#!/bin/bash
#
# This script will connect to a Powerwall device and dump the contents of all
# known informational API endpoints (all endpoints that are simple GET
# requests).  Since some endpoints only contain useful information or change
# their invormation when the system is in a particular state, It will first
# dump the endpoints once while the system (sitemaster) is running, then it
# will stop the system and dump all of the endpoints again, and then re-start
# the system.
#
# This script will dump the results into a subdirectory of the user's choosing.
# To avoid accidental overwrites, it requires that the specified directory must
# not already exist (it will be created).  Arguments can be provided on the
# command line or, if arguments are not provided, they will be prompted for.

gateway_addr="$1"
email="$2"
password="$3"
dump_dir="$4"

DEFAULT_ADDR="powerwall"

# List of all API endpoints to dump.
# The following are technically GET requests, but actually perform actions or
# have side-effects, so are not included in this list:
#
# - config/completed
# - sitemaster/run

API_LIST="
  auth/toggle/supported
  autoconfig/status
  config
  customer
  customer/registration
  generators
  generators/disconnect_types
  installer
  installer/companies
  meters
  meters/aggregates
  meters/readings
  meters/status
  networks
  networks/client_protocols
  operation
  powerwalls
  powerwalls/phase_usages
  powerwalls/status
  site_info
  site_info/grid_regions
  site_info/site_name
  sitemaster
  solars
  solars/brands
  status
  synchrometer/ct_voltage_references
  synchrometer/ct_voltage_references/options
  system/networks/conn_tests
  system/networks/ping_test
  system/testing
  system/update/status
  system_status
  system_status/grid_faults
  system_status/grid_status
  system_status/soe
  troubleshooting/problems
"

# Sub-paths under /meters/<meter-serialno>/ to query as well
METER_API_LIST="
  ct_config
  cts
"

###############################################################################

get_api() {
  curl -s -S -k -b "$cookie_file" "https://${gateway_addr}/api/$1"
}

post_api() {
  curl -s -S -k -b "$cookie_file" -X POST -d "$2" "https://${gateway_addr}/api/$1"
}

preflight_check() {
  # Check for required utilities

  for cmd in curl jq; do
    if ! which "$cmd" > /dev/null; then
      cat <<EOF >&2
This script requires the '$cmd' utility be installed.

For Debian/Ubuntu/etc: 'sudo apt-get install $cmd'
For Fedora: 'sudo dnf install $cmd'
For openSUSE: 'sudo zypper install $cmd'
For Arch: 'sudo pacman -S $cmd'
For MacOS: 'brew install $cmd' or 'port install $cmd'

EOF
      exit 2
    fi
  done
}

prompt_for_inputs() {
  while [[ -z "$gateway_addr" ]]; do
    read -p "Powerwall address/IP [$DEFAULT_ADDR]: " gateway_addr
    gateway_addr="${gateway_addr:-$DEFAULT_ADDR}"
  done

  while [[ -z "$email" ]]; do
    default_email=$(git config --get user.email 2>/dev/null)
    read -p "Email address to login as [$default_email]: " email
    email="${email:-$default_email}"
  done

  while [[ -z "$password" ]]; do
    read -s -p "Password: " password
    echo ""
  done

  while [[ -z "$dump_dir" ]]; do
    # Get the version number of the firmware
    version=$(get_api status | jq -r .version | sed -e 's/ .*//') || exit 4
    default_dump_dir="./${version}-${email%%@*}"

    read -p "Directory to place output in [$default_dump_dir]: " dump_dir
    dump_dir="${dump_dir:-$default_dump_dir}"

    if [[ -d "$dump_dir" ]]; then
      echo "Error: Directory '$dump_dir' already exists.  Please choose another location." >&2
      dump_dir=""
    fi
  done
}

confirm_proceed() {
  echo ""
  echo "NOTE: This script will temporarily stop the powerwall in order to collect some information (and then start it up again afterwards).  This should be fairly safe, but it is recommended to double-check (via the web interface or app) after completion to ensure the Powerwall has come back up properly and is functioning as expected afterward."
  echo ""
  read -p "Proceed? [y/N]: " yesno
  if [[ "$yesno" != "y" ]] && [[ "$yesno" != "Y" ]]; then
    echo "Aborting."
    exit 5
  fi
}

create_tempfiles() {
  script_name=$(basename "$0")
  cookie_file=$(mktemp -t "$script_name.cookies") || exit 3
  mask_file=$(mktemp -t "$script_name.mask") || exit 3

  # Our temp files will contain secrets, so make sure they're not world-readable.
  chmod go= "$cookie_file" "$mask_file"
}

delete_tempfiles() {
  rm -f "$cookie_file" "$mask_file"
}

do_login() {
  # Attempt to login and get an auth cookie to use

  request_json=$(jq -c -n --arg email "$email" --arg password "$password" '
    {
      "username": "customer",
      "email": $email,
      "password": $password,
      "force_sm_off": false
    }
  ')

  result=$(curl -s -k -c "$cookie_file" -X POST -H "Content-Type: application/json" -d "$request_json" "https://${gateway_addr}/api/login/Basic")

  auth_token=$(cat "$cookie_file" | awk '/AuthCookie/ {print $7}')
  if [[ -z "$auth_token" ]]; then
    echo "Login failed: $result"
    exit 1
  fi
}

check_sitemaster() {
  smstatus=$(get_api sitemaster | jq -r .status) || exit 4
  if [[ "$smstatus" != "StatusUp" ]]; then
    echo "Error: Powerwall is not currently in running state.  Please run this script when the device is already up and fully running." >&2
    exit 4
  fi
}

add_mask_entry() {
  # Escape characters in the input pattern to make it suitable for passing as
  # an expression to the 'sed' command.
  _escaped=$(echo "$1" | sed -e 's/\([$.*[\^/]\)/\\\1/g')
  echo "s/$_escaped/$2/g" >> "$mask_file"
}

# Lookup any values we need to mask out and add them to a sed file we can use for that purpose.
populate_maskfile() {
  # Mask out the TSN (gateway serial number), as well as any other device serial numbers
  vin=$(get_api config | jq -r .vin) || exit 4
  tsn="${vin##*--}"
  meter_serials=$(get_api meters | jq -r '.[].serial' | sed -e 's/synchrometer.*//' | uniq)
  battery_serials=$(get_api powerwalls | jq  -r '.powerwalls[].PackageSerialNumber')

  add_mask_entry "$tsn" "<<GATEWAY_TSN>>"
  for v in $meter_serials; do
    add_mask_entry "$v" "<<METER_SERIAL>>"
  done
  for v in $battery_serials; do
    add_mask_entry "$v" "<<BATTERY_SERIAL>>"
  done

  # The "installer phone" is usually the phone number of the company (which
  # isn't particularly sensitive), but somebody could conceivably put in the
  # end-user's phone number here, etc, so we'll mask it out just in case.  The
  # "email" field theoretically should be the installer's email, I think, but
  # on my system (foogod) it actually shows my own email address there...
  installer_info=$(get_api installer) || exit 4
  inst_phone=$(echo "$installer_info" | jq -r '.phone')
  inst_email=$(echo "$installer_info" | jq -r '.email')

  add_mask_entry "$inst_phone" "<<INSTALLER_PHONE>>"
  add_mask_entry "$inst_email" "<<INSTALLER_EMAIL>>"

  # Mask out WiFi network names, IP addresses, and hardware MAC addresses
  networks_info=$(get_api networks) || exit 4
  wifi_names=$(echo "$networks_info" | jq -r '.[].iface_network_info | select(.interface=="WifiType").network_name // empty')
  wifi_usernames=$(echo "$networks_info" | jq -r '.[].username // empty')
  ip_addresses=$(echo "$networks_info" | jq  -r '.[].iface_network_info.ip_networks[]?.ip // empty')
  gateways=$(echo "$networks_info" | jq  -r '.[].iface_network_info.gateway // empty')
  hw_addresses=$(echo "$networks_info" | jq  -r '.[].iface_network_info.hw_address // empty')

  for v in $wifi_names; do
    add_mask_entry "$v" "<<WIFI_SSID>>"
  done
  for v in $wifi_usernames; do
    add_mask_entry "$v" "<<WIFI_USERNAME>>"
  done
  for v in $ip_addresses $gateways; do
    add_mask_entry "$v" "<<IP_ADDR>>"
  done
  for v in $hw_addresses; do
    add_mask_entry "$v" "<<MAC_ADDR>>"
  done

  # Include the login password and auth token too.
  # We hopefully shouldn't ever encounter these in output, but add masks for them
  # just in case:
  add_mask_entry "$password" "<<CUSTOMER_PASSWORD>>"
  add_mask_entry "$auth_token" "<<AUTH_TOKEN>>"
}

sanitize_hostname() {
  # Take an arbitrary string (such as an API path) and turn it into a
  # relatively clean filename.  This also runs it through our mask filter in
  # case it has any sensitive info in it.

  echo "$1" | sed -f "$mask_file" | tr '/' '.' | tr -c -d '[:alnum:]._'
}

dump_api() {
  outfile=$(sanitize_hostname "$1")
  result=$(curl -i -s -S -k -b "$cookie_file" "https://${gateway_addr}/api/$1")
  status=$(echo "$result" | head -1 | sed -e 's/^HTTP[^ ]* //' -e 's/ .*//')
  if [[ "$status" == "200" ]]; then
    body=$(echo "$result" | awk 'p {print} /^\r*$/ {p=1}')
    echo "$body" | jq . | sed -f "$mask_file" > "${outfile}.json"
  else
    # (A 502 status is expected for a lot of calls when sitemanager is not
    # running, so don't complain about it, just record it.  Likewise, some
    # calls return 500 if the particular hardware config just doesn't support
    # an operation.)
    if [[ "$status" != "500" ]] && [[ "$status" != "502" ]]; then
      echo "(Note: Call to '$1' returned status $status)" >&2
    fi
    echo "$result" > "${outfile}.err"
  fi
}

dump_all() {
  for api in $API_LIST; do
    dump_api "$api"
  done
  meters=$(get_api meters | jq -r '.[].serial')
  for meter in $meters; do
    for api in $METER_API_LIST; do
      dump_api "meters/$meter/$api"
    done
  done
}

###############################################################################
#                              Begin main script                              #
###############################################################################

preflight_check
create_tempfiles
prompt_for_inputs
do_login
check_sitemaster
confirm_proceed
populate_maskfile

mkdir "$dump_dir" && cd "$dump_dir" || exit 4

echo ""
echo "Collecting running samples..."

mkdir "running" && cd "running" || exit 4
dump_all
cd ..

echo ""
echo "Stopping sitemaster..."

post_api "sitemaster/stop" '{"force":true}'
sleep 2
smstatus=$(get_api sitemaster | jq -r .status) || exit 4
if [[ "$smstatus" != "StatusDown" ]]; then
  echo "ERROR: Unable to stop sitemaster (current status: $smstatus).  Check powerwall for errors." >&2
  exit 4
fi

echo ""
echo "Collecting stopped samples..."

mkdir "stopped" && cd "stopped" || exit 4
dump_all
cd ..

echo ""
echo "Starting sitemaster..."

get_api "sitemaster/run"
sleep 2
smstatus=$(get_api sitemaster | jq -r .status) || exit 4
if [[ "$smstatus" != "StatusUp" ]]; then
  echo "ERROR: Unable to start sitemaster (current status: $smstatus).  Check powerwall for errors." >&2
  exit 4
fi

echo ""
echo "Collection completed."

# Clean up after ourselves
delete_tempfiles
