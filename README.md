Tesla Powerwall 2 - Local Gateway API documentation
======
_(Based on firmware version 1.15.0)_

This is a list of api URLs and some random thoughts I've been able to pull together from the interwebz and other functions we've been able to reverse engineer from the local gateway.  (This is not the [ Tesla Owner API](https://timdorr.docs.apiary.io/#)).

Powerwall 2 Web UI
---
The web UI provides ~~an instantaneous~~ 250-500ms average(?) power flow diagram an access to the wizard.
Hit your local gateway IP with a browser, i.e. _http://192.168.xxx.xxx/

You should see something like this:

![GatewayUI](https://github.com/vloschiavo/powerwall2/raw/master/img/TeslaPowerwallGatewayUI.png "Gateway Web UI")

---
**Wizard**
You can hit the _"Run Wizard"_ button here and go through the setup (be careful what you change in the wizard).

`username: <leave this blank as it's ignored (and/or logged)>`

`password: S + <gateway serial number>`

You can find the serial number of the gateway ( the linux server that switches power) on the inside of the metal access door to the gateway. Don't unscrew anything as the box is switching high voltage & current behind the screwed pannels. See image:

![Gateway Location](https://github.com/vloschiavo/powerwall2/raw/master/img/equipment.jpg "Gateway location")

[ Original image taken from www.tesla.com here](https://www.tesla.com/support/energy/install/powerwall/powerwall-installations)

___
### Information

**Meters / Power output stats**
Calling the below URLs does not require authentication.  Each will return JSON output with key-value pairs.

_GET /api/meters/aggregates_

request: `curl http://192.168.xxx.xxx/api/meters/aggregates`

response: [see sample response here](https://raw.githubusercontent.com/vloschiavo/powerwall2/master/samples/api_meters_aggregates.json
)

This returns the current readings from the meters that measure solar, grid, battery, and home production and usage.  Watts, Hz, etc.  Watt values can be positive or negative.  
1. "site" corresponds to "Grid" in the Tesla mobile app
	-Positive numbers indicate power draw from the grid to the system
	-Negative numbers indicate sending power from the system to the grid
2. "battery" corresponds to "Powerwall" in the Tesla mobile app - this is an aggregate number if you have more than one Powerwall
	-Positive numbers indicate power draw from the batteries to the system
	-Negative numbers indicate sending power from the system to the batteries
3. "load" corresponds to "Home" in the Tesla mobile app
	-Positive numbers indicate power draw from the system to the home
	-Negative numbers should never happen
4. "solar" corresponds to "Solar" in the Tesla mobile app
	-Positive numbers indicate power production from solar to the system
	-Negative numbers indicate sending power from the system to solar - this should never be higher than 100 Watts.  On occasion I see +/- -10 at night.
5. "busway" - Unknown - my numbers show 0 for this.
6. "frequency" - Unknown - my numbers show 0 for this.
7. "generator" - Unknown I don't have a generator - my numbers show 0 for this.

---
**State of Charge / State of Energy**
_GET /api/system_status/soe_

This returns the aggregate charge state in percent of the powerwall(s).

request: `curl http://192.168.xxx.xxx/api/system_status/soe`

response:	`{"percentage":69.1675560298826}`

---

_GET /api/sitemaster_
Use this URL to determine: 
1. Powerwall state {running|stopped}
2. How long the powerwall has been set to the running state {in seconds}
3. Is the powerwall gateway connected to Tesla's servers {true|false}}

request: `curl http://192.168.xxx.xxx/api/sitemaster`

response:	`{"running":true,"uptime":"166594s,","connected_to_tesla":true}`

---

_GET /api/powerwalls_
Use this URL to determine how many power walls you have, their serial numbers, and if they are in sync (assuming more than one powerwall).

request: `curl http://192.168.xxx.xxx/api/powerwalls`

response:	`{"powerwalls":[{"PackagePartNumber":"1234567-01-E","PackageSerialNumber":"T1234567890"},{"PackagePartNumber":"1012345-03-E","PackageSerialNumber":"T1234567891"}],"has_sync":true}`

---

_GET /api/customer/registration_
Use this URL to determine registration status.  The below shows the results from a system that is fully configured and running.

request: `curl http://192.168.xxx.xxx/api/customer/registration`

response: `{"privacy_notice":true,"limited_warranty":true,"grid_services":null,"marketing":null,"registered":true,"emailed_registration":true,"skipped_registration":false,"timed_out_registration":false}`

---

_GET /api/system_status/grid_status_
Determine if the Grid is up or down.

request: `curl http://192.168.xxx.xxx/api/customer/registration`

response: `{"grid_status":"SystemGridConnected"}`

{SystemGridConnected} = Grid is up.
{?} = Grid is down.  (I haven't seen a grid down situation yet - have any of you seen the value for a grid down?)  

---
_GET /api/system/update/status_

request: `curl http://192.168.xxx.xxx/api/system/update/status`

response: `{"state":"/update_failed","info":{"status":["nonactionable"]},"current_time":1422697552910}`

1. update_failed / status nonactionable = I tried to do an upgrade but I have the latest firmware version already installed.
2. current_time in EPOC.
	-1422697552910 = **GMT**: Monday, April 2, 2018 8:09:17.447 PM
	
---	
_GET /api/site_info_

request: `curl http://192.168.xxx.xxx/api/site_info`

response: `Response: {"site_name":"Home Energy Gateway","timezone":"America/Los_Angeles","min_site_meter_power_kW":-1000000000,"max_site_meter_power_kW":1000000000,"nominal_system_energy_kWh":13.5,"grid_code":"60Hz_240V_s_UL1741SA:2016_California","grid_voltage_setting":240,"grid_freq_setting":60,"grid_phase_setting":"Split","country":"United States","state":"California","region":"UL1741SA"}`

---

_GET /api/site_info/site_name_

request: `curl http://192.168.xxx.xxx/api/site_info/site_name`

response: `{"site_name":"Home Energy Gateway","timezone":"America/Los_Angeles"}`

---
_GET /api/status_

request: `curl http://192.168.xxx.xxx/api/status`

response: `{"start_time":"2018-03-16 19:08:46 +0800","up_time_seconds":"402h8m19.937911668s","is_new":false,"version":"1.15.0\n","git_hash":"dc337851c6cad15a7e9c7223d60fff719eb8da4d\n"}`

Useful here: Gateway Version:  "version":"1.15.0\n"

---

_GET /api/logout_

The Gateway Web UI uses this url to logout of the wizard.  I assume you can also use this to expire an auth token...(some testing is required).

Request: `curl -i 192.168.xxx.xxx/api/logout`

Response: `HTTP/1.1 204 No Content
Access-Control-Allow-Credentials: false
Access-Control-Allow-Headers: X-Requested-With, X-HTTP-Method-Override, Content-Type, Accept, Accept-Encoding, Authorization
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
Access-Control-Allow-Origin: *
Access-Control-Max-Age: 86400`

---
_GET /api/system_status/grid_faults_

Not sure what this does...does it list the recent grid failure dates/times?

Request: `curl 192.168.xxx.xxx/api/system_status/grid_faults`

Response: `[]`

---
_GET /api/sitemaster/stop_

This stops the powerwalls & gateway.  In the stopped state, the powerwall will not charge, discharge, or monitor solar, grid, battery, home statistics.

Request: `curl http://192.168.xxx.xxx/api/sitemaster/stop`

Response:  

---
_GET /api/sitemaster/run_

This starts the powerwalls & gateway.  Use this after getting an authentication token to restart the powerwalls.

Request: `http://192.168.xxx.xxx/api/sitemaster/run`

Response:  

---
_GET /api/config/completed_

This applies configuration changes.

This is a GET request and doesn't require an authentication token.

Request: `curl /api/config/completed`

Response:

___
Note: __*** The below API calls require authentication ***__


**Login**
_POST /api/login/Basic_

**Authentication example:**
Note: Getting an authentication token will stop the powerwall.  It won't charge, discharge, or collect stats on v1.15.0.  Therefore you should re-enable the powerwall after getting a token.  
See: the _/api/sitemaster/run_ section above.

Here is an example login using a blank username (none needed) and a serial number of T123456789.  The password is S+Serial number: ST123456789.

Request: 

`curl -s -i -X POST -H "Content-Type: application/json" -d '{"username":"","password":"ST123456789","force_sm_off":false}' http://192.168.xxx.xxx/api/login/Basic`

Response: 

`{"email":null,"firstname":"Tesla","lastname":"Energy","roles":["Provider_Engineer"],"token":"OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==","provider":"Basic"}`

Save the token for use with the below calls.

**Note for Windows users:**
Windows shell handles quotes differently than linux Bash.
In windows, the above example works by:
1. changing the single quotes to double quotes
2. escape the double quotes inside the -d section

Windows Example Request: 

`curl -s -i -X POST -H "Content-Type: application/json" -d "{\"username\":\"\",\"password\":\"ST123456789\",\"force_sm_off\":false}" http://192.168.xxx.xxx/api/login/Basic`


---
_POST /api/operation_
Change the Powerwall mode and Reserve Percentage

_Note 1: Making changes to the Powerwalls via the Mobile application can take some time to go into effect.  There's a rumor that states that the changes happen around 30 minutes past the hour. (Probably based on a cron job in Tesla's servers)._

_Note 2: Setting a value is not sufficient to make the change.  You must "save" or "commit" the configuration to have it go into effect.  See  the _Config Completed_ section below._

_Note 3: Once a value is changed and committed it is immediately in effect._

The below request would set the battery mode to "Self-powered" and a "Reserve for Power Outages" to 20% (app value) using the token retrieved from the authentication example. 

request: `curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" -X POST -d '{"mode":"self_consumption","backup_reserve_percent":20}' 'http://192.168.xxx.xxx/api/operation'`

response: `{"mode":"self_consumption","backup_reserve_percent":24}`

Valid Modes:
1. `self_consumption`
2. `backup`

There also is an option to set the max PV Export power in kW.  I'm not 100% sure what that does but I could guess (Time of use?). Mine is currently set to null (probably because time of use isn't enabled on my system yet (as of April 2018).  You can omit this key/value pair from the POST.

`{max_pv_export_power_kW: null, mode: "self_consumption", backup_reserve_percent: 24}`

Note the difference in the app value (20%) versus the value we set via the local API (24%).  The difference is likely proportional until you reach 100%:

Tested values:
20% = 24%
30% = 33%
100% = 100%.

---

Others to be documented:
/api/powerwalls/status
/api/site_info/grid_codes
/api/solars
/api/solars/brands
/api/generators
/api/generators/disconnect_types
/api/solars/brands/SolarEdge%20Technologies
/api/meters
/api/meters/readings
/api/installer - `{company: "Tesla Timbuktu", customer_id: "01234567", phone: "8885551212"}`
/api/customer
/api/config - `{vin: "0123456-00-E--T1234567890"}`


___
Other
---

/api/siteinfo/timezone - `404 - not working at the moment. Requires auth?`

