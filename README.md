Tesla Powerwall 2 - Local Gateway API documentation
======



_(Based on firmware version 1.15.0)_

This is a list of api URLs and some random thoughts I've been able to pull together from the interwebz and other urls I've been able to reverse engineer from my local gatway.

**Powerwall Web UI**

The web UI provides ~~an instantaneous~~ 250-500ms average(?) power flow diagram an access to the wizard.
Hit your local gateway IP with a browser, i.e. _http://192.168.100.10/_
<br>
**Wizard**
You can hit the _"Run Wizard"_ button here and go through the setup.

`username: <leave this blank as it's ignored (and/or logged)>`

`password: S + <gateway serial number>`

_You can find the serial number of the gateway ( the linux server that switches power) on the inside of the metal access door to the gateway.  Don't unscrew anything as the box is switching high voltage & current behind the screwed pannels._
___
### Information

**Meters / Power output stats**
Calling the below URLs does not require authentication.  Each will return JSON output with key-value pairs.

_/api/meters/aggregates_

This returns the current readings from the meters that measure solar, grid, battery, and home production and usage.  Values can be positive or negative.  
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
_/api/system_status/soe_

This returns the aggregate charge state in percent of the powerwall(s).
request: `curl http://192.168.xxx.xxx/api/system_status/soe`
response:	`{"percentage":69.1675560298826}`

---

/api/sitemaster 
{"running":true,"uptime":"166594s,","connected_to_tesla":true}

---

/api/powerwalls
{"powerwalls":[{"PackagePartNumber":"1234567-01-E","PackageSerialNumber":"T1234567890"},{"PackagePartNumber":"1012345-03-E","PackageSerialNumber":"T1234567891"}],"has_sync":true}

---

/api/customer/registration
{"privacy_notice":true,"limited_warranty":true,"grid_services":null,"marketing":null,"registered":true,"emailed_registration":true,"skipped_registration":false,"timed_out_registration":false}

---

/api/system_status/grid_status   
{"grid_status":"SystemGridConnected"}

---
/api/system/update/status
{"state":"/update_failed","info":{"status":["nonactionable"]},"current_time":1422697552910}
1. update_failed / status nonactionable = I tried to do an upgrade but I have the latest firmware version already installed.
2. current_time in EPOC.
	-1422697552910 = **GMT**: Monday, April 2, 2018 8:09:17.447 PM
---	
/api/site_info

Response: `{"site_name":"Home Energy Gateway","timezone":"America/Los_Angeles","min_site_meter_power_kW":-1000000000,"max_site_meter_power_kW":1000000000,"nominal_system_energy_kWh":13.5,"grid_code":"60Hz_240V_s_UL1741SA:2016_California","grid_voltage_setting":240,"grid_freq_setting":60,"grid_phase_setting":"Split","country":"United States","state":"California","region":"UL1741SA"}`

---

/api/site_info/site_name
`{"site_name":"Home Energy Gateway","timezone":"America/Los_Angeles"}`

---
/api/status
`{"start_time":"2018-03-16 19:08:46 +0800","up_time_seconds":"402h8m19.937911668s","is_new":false,"version":"1.15.0\n","git_hash":"dc337851c6cad15a7e9c7223d60fff719eb8da4d\n"}`

---

Request: `curl -i 192.168.xxx.xxx/api/logout`
Response: `HTTP/1.1 204 No Content
Access-Control-Allow-Credentials: false
Access-Control-Allow-Headers: X-Requested-With, X-HTTP-Method-Override, Content-Type, Accept, Accept-Encoding, Authorization
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
Access-Control-Allow-Origin: *
Access-Control-Max-Age: 86400`

---
Request: `curl 192.168.xxx.xxx/api/system_status/grid_faults`
Response: `[]`

---
**Stopping Powerwall**

Request: `curl http://192.168.xxx.xxx/api/sitemaster/stop`

---
**Starting Powerwall**
Request: `http://192.168.xxx.xxx/api/sitemaster/run`

___
### The below API calls require authentication


**Login**
/api/login/Basic

**Authentication example:**
Note: Getting an authentication token will stop the powerwall.  It won't charge, discharge, or collect stats on v1.15.0.  Therefore you should re-enable the powerwall after getting a token.  See: the _Starting Powerwall_ section.

Request: `curl -s -i -X POST -H "Content-Type: application/json" -d '{"username":"","password":"ST123456789","force_sm_off":false}' "http://192.168.xxx.xxx/api/login/Basic"`
Response: `{"email":null,"firstname":"Tesla","lastname":"Energy","roles":["Provider_Engineer"],"token":"OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==","provider":"Basic"}`

Save the token for use with the below calls:

---

**Changing the Powerwall mode and Reserve percentage**

_Note 1: Making changes to the Powerwalls via the Mobile application can take some time to go into effect.  There's a rumor that states that the changes happen around 30 minutes past the hour. (Probably based on a cron job in Tesla's servers)._

_Note 2: Setting a value is not sufficient to make the change.  You must "save" or "commit" the configuration to have it go into effect.  See  the _Config Completed_ section below._

_Note 3: Once a value is changed and committed it is immediately in effect._

The below request would set the battery mode to "Self-powered" and a "Reserve for Power Outages" to 20% (app value) using the token retrieved from the authentication example. 

request: `curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" -X POST -d '{"mode":"self_consumption","backup_reserve_percent":20}' 'http://192.168.xxx.xxx/api/operation'`
response: {"mode":"self_consumption","backup_reserve_percent":24}

Valid Modes:
1. `self_consumption`
2. `backup`

There also is an option to set the max PV Export power KW.  I'm not sure what that does. Mine is currently set to null.  You can omit this key/value pair from the POST.

`{max_pv_export_power_kW: null, mode: "self_consumption", backup_reserve_percent: 24}`

Note the difference in the app value (20%) versus the value we set via the local API (24%).  The difference is likely proportional until you reach 100%:

Tested values:
20% = 24%
30% = 33%
100% = 100%.

---
**Config Completed**

This applies any configuration changes.

This is a GET request and doesn't require an authentication token.
Request: `curl /api/config/completed`

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


Cut and pasted from the Forums:  
---
Thank you to all of you who have figured these things out!

You can set the operation mode and reserve percentage using the local API used by the wizard if you want. To do it, you need to authenticate using /api/login/Basic and then use the token that's returned as a bearer token in the request.

The endpoint is /api/operation and take JSON post data such as the following: {"backup_reserve_percent": 100, "mode":"self_consumption"}

This just queues the change up. To commit it, do a GET of /api/config/completed.

I just received my Powerwalls and my app hasn't been provisioned yet, so I've just been playing with the local API so far.

One other thing I forgot to mention: it looks like the stop and start buttons from the local web UI just generate a GET to /api/sitemaster/stop and /api/sitemaster/run, respectively. No credentials seem to be needed, so if all you're trying to automate is stopping the powerwall, it seems relatively straightforward. The drawback of course is that a stopped gateway won't do any monitoring.

Login:
Same as for the wizard. Username appears to be ignored (probably just logged), password is S + serial number of the gateway.

curl -i -X POST \
-d \
'{"username":"", "password":"SXXXXXXXXXXX", "force_sm_off":false}' \
'http://gateway-ip-address/api/login/Basic'

One other note: unlike how I understand the server interface works, using the local API the changes seem to happen right away (after the config/done call).
