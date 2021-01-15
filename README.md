Tesla Powerwall 2 - Local Gateway API documentation
======

_(This documentation is currently in flux: portions are updated and portions aren't updated.  Use at your own risk)_

_(If you find issues, please submit pull requests - currently testing on firmware version 1.45.2)_

___*** Please be patient as I have an unrelated day job! ***___

**Please help me update this: Pull requests are welcome!**

This is a list of api URLs and some random thoughts I've been able to pull together from the interwebs and other functions we've been able to reverse engineer from the local gateway.  This is not the [ Tesla Owner API] which you can find here: (https://tesla-api.timdorr.com) with a Python library that works nicely to control a Powerwall 2 here: (https://github.com/mlowijs/tesla_api).

A python implementation of the local API can be found here (https://github.com/jrester/tesla_powerwall).
-Thanks for submitting this: 


A note about HTTPS and SSL Certificates
---
In a recent update to the Powerwall firmware (v1.20+) non-SSL requests (http) are no longer supported and queries will return HTTP/1.1 301 Moved Permanently.  Unfortunately the certificate presented by the Powerwall is not signed by a root certificate authority as they are self-signed.  This results in web browsers and tools like curl not accept it without it either being included as a trusted certificate or a specific action by the user to override the error. 

You have three ways around a certificate error:

1) In web browser this will manifest itself as an error that the certificate is not trusted.  To bypass simply click "details" (IE/Edge) or "Advanced..." (Firefox) and select continue.

2) With curl the `--insecure` or `-k` option will ignore the SSL certificate.  This is ok, but it doesn't authenticate the device you are connecting to.

3) A better way is to export the Powerwall public certificate and add it to the local machine's trusted certificate list or just use the certificate in your curl request.

__I recommend option 3 above.__

_Here's what worked for me:_

Step 1: DNS

Enable DNS lookups, on your local network, for one of the following DNS names in the certificate under the "Certificate Subject Alt Name".  On my gateway these names are:
1) teg
2) powerwall
3) powerpack

You can add this to your local DNS server as an A Record or /etc/hosts file or other DNS name resolution service.  

For /etc/hosts add an entry that looks like this if your Powerwall gateway's IP was 192.168.99.99:

`192.168.99.99	powerwall`

Step 2: Get the certificate
`echo quit | openssl s_client -showcerts -servername powerwall -connect powerwall:443 > cacert.pem`

This grabs the certificate from the powerwall using the DNS entry you setup in step 1.

Step 3: use the certificate in your curl statements
e.g. `curl --cacert cacert.pem https://powerwall/api/meters/aggregates`

If you get this error: `curl: (51) SSL: no alternative certificate subject name matches target host name` then the name you chose (teg or powerwall or powerpack) doesn't match what's in the certificate file and you'll need to check the certificate and perhaps do some googling to figure out the solution.

For the rest of the documentation, I will assume you copied the certificate and are using method C with the Powerwall's public certificate.  If you didn't, just leave out the certificate `--cacert cacert.pem` portion and add `-k`.


Powerwall 2 Web UI
---
The web UI provides ~~an instantaneous~~ a 250-500ms average(?) power flow diagram an access to the wizard.
Hit your local gateway IP with a browser, i.e. _https://powerwall/

You should see something like this:

![GatewayUI](https://github.com/vloschiavo/powerwall2/raw/master/img/TeslaPowerwallGatewayUI.jpg "Gateway Web UI")

---
**Wizard**
You can hit the _"Login"_ link on this page and go through the setup (be careful what you change in the wizard).

`username: <Enter whatever you like here>`

`password: `
Follow the instructions on the web page to set/change/recover the password. Whatever you set here will be used later.


___
### Information

**Meters / Power output stats**
Calling the below URLs does not require authentication.  Each will return JSON output with key-value pairs. Specify the cacert.pem you grabbed earlier using the Certificate Subject Alt Name.

_GET /api/meters/aggregates_

request: `curl --cacert cacert.pem https://powerwall/api/meters/aggregates`

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

When site master or the Powerwalls are off, the response is: HTTP Status 502

_GET /api/meters/site_

Detailed information about the site specific meter.

request: `curl --cacert cacert.pem https://powerwall/api/meters/site`

response: [see sample response here](https://raw.githubusercontent.com/vloschiavo/powerwall2/master/samples/api-meters-site.json)

_GET /api/meters/solar_

Detailed information about the solar specific meter.

request: `curl --cacert cacert.pem https://powerwall/api/meters/solar`

response: [see sample response here](https://raw.githubusercontent.com/vloschiavo/powerwall2/master/samples/api-meters-solar.json)


---
**State of Charge / State of Energy**
_GET /api/system_status/soe_

This returns the aggregate charge state in percent of the powerwall(s).

request: `curl --cacert cacert.pem https://powerwall/api/system_status/soe`

response:	`{"percentage":69.1675560298826}`

When site master or the Powerwalls are off, the response is: HTTP Status 502

---

_GET /api/sitemaster_
Use this URL to determine: 
1. Powerwall state {running|stopped}
2. How long the powerwall has been set to the running state {in seconds}
3. Is the powerwall gateway connected to Tesla's servers {true|false}}

request: `curl --cacert cacert.pem https://powerwall/api/sitemaster`

response:	`{"running":true,"uptime":"802459s,","connected_to_tesla":true}`

When site master or the Powerwalls are off, the response is:  `{"running":false,"uptime":"log:","connected_to_tesla":false}`

---

_GET /api/powerwalls_
Use this URL to determine how many power walls you have, their serial numbers, and if they are in sync (assuming more than one powerwall).

request: `curl --cacert cacert.pem https://powerwall/api/powerwalls`

response:	[see sample response here](https://raw.githubusercontent.com/vloschiavo/powerwall2/master/samples/api-powerwalls.json)

I have two of the AC Powerwall 2s in the United States.  The PackagePartNumber is: 1092170-03-E.  Let me know if you have a different package part number and what Powerwall model you have.  (i.e. DC, AC, Powerwall v1 or v2)


---

_GET /api/customer/registration_
Use this URL to determine registration status.  The below shows the results from a system that is fully configured and running.

request: `curl --cacert cacert.pem https://powerwall/api/customer/registration`

response: `{"privacy_notice":true,"limited_warranty":true,"grid_services":null,"marketing":null,"registered":true,"timed_out_registration":false}`

---

_GET /api/system_status/grid_status_
Determine if the Grid is up or down.

request: `curl --cacert cacert.pem https://powerwall/api/system_status/grid_status`

response: {"grid_status":"SystemGridConnected","grid_services_active":false}

`{"grid_status":"SystemGridConnected"}` = grid is up

`{"grid_status":"SystemIslandedActive"}` = grid is down

`{"grid_status":"SystemTransitionToGrid"}` = grid is restored but not yet in sync.

---
_GET /api/system/update/status_
_UPDATE: You need to be authenticated for this command_

From: @kylerove:
"After digging, the answer was right on Tesla's website:
https://www.tesla.com/support/energy/powerwall/own/monitoring-from-home-network

username=customer
email=your Tesla account email address
password=last 5 digits of your gateway serial number

You can then reset/choose your own customer password, if you want to make it stronger."

request: `curl --cacert cacert.pem https://powerwall/api/system/update/status`

response: `{"state":"/update_failed","info":{"status":["nonactionable"]},"current_time":1422697552910}`

1. update_failed / status nonactionable = I tried to do an upgrade but I have the latest firmware version already installed.
2. current_time in EPOC.
	-1422697552910 = **GMT**: Monday, April 2, 2018 8:09:17.447 PM
	
	  
possible values of "state" property, according to the code:

-   "/clear_update_status", // Checking for firmware update is in progress (need to keep sending request until state is changed)  
    
-   "/update_succeeded", // Success  
    
-   "/update_failed", // Update failed, or not required  
    
-   "/update_staged", // Staging update?  
    
-   "/download",  // Downloading update  
    
-   "/update_downloaded", // Ready to update  
    
-   "/update_unknown"  

possible values of "status" property according to the code:

-   "ignoring", // possibly some uninterruptable action is in progress?  
    
-   "error",  
    
-   "nonactionable" // everything is OK  
    

  

Use case:  One user is making this request to check new firmware available, and run the upgrade, approximately 30 minutes before switching to discharging (self_consumption mode with 5% reserve). Assumption is - we better upgrade firmware while battery is in standby mode, rather then letting gateway upgrade itself later, because it will stop battery possibly during peak hours for an upgrade. He noticed his gateway has self-upgraded during peak hours, resulting around 15 minutes stop of battery, which was an unpleasant surprise and extra cost. So, his idea was to force a new firmware check (and upgrade) when battery is not used:

  
-   7:15am  check for new fimware and run an upgrade if firmware is available  
    
-   7:55am  - start discharging (self_consumption, 5% reserve)  
    
-   10:05pm  - start charging (backup, 100% reserve)  
    

Southern California Edison has TOU plan with the following details:

-   8am-2pm,  8pm-10pm  - offpeak  
    
-   2pm-8pm  - peak  
    
-   10pm-8am  - super offpeak

---	
_GET /api/site_info_

request: `curl --cacert cacert.pem https://powerwall/api/site_info`

response: `{"max_site_meter_power_kW":1000000000,"min_site_meter_power_kW":-1000000000,"nominal_system_energy_kWh":13.5,"nominal_system_power_kW":10,"site_name":"Loschiavo","timezone":"America/Los_Angeles","grid_code":"60Hz_240V_s_UL1741SA:2016_California","grid_voltage_setting":240,"grid_freq_setting":60,"grid_phase_setting":"Split","country":"United States","state":"California","distributor":"*","utility":"Pacific Gas and Electric Company","retailer":"*","region":"UL1741SA"}`

---

_GET /api/site_info/site_name_

request: `curl --cacert cacert.pem https://powerwall/api/site_info/site_name`

response: `{"site_name":"Home Energy Gateway","timezone":"America/Los_Angeles"}`

The site_name value can be changed from the Tesla Mobile app settings.

---
_GET /api/status_

request: `curl --cacert cacert.pem https://powerwall/api/status`

response: `{"start_time":"2019-09-23 23:38:46 +0800","up_time_seconds":"223h5m51.577762169s","is_new":false,"version":"1.40.2","git_hash":"14f7c1769ec307bba2ea62355a09d01c8e58988c+"}`

Useful here: Gateway Version:  "version":"1.40.2\n"

---

_GET /api/logout_

The Gateway Web UI uses this url to logout of the wizard.  I assume you can also use this to expire an auth token...(some testing is required).
_This is untested. Question for the community: Does this still work? Soliciting for pull requests! :)_

Request: `curl --cacert cacert.pem -i https://powerwall/api/logout`

Response: `HTTP/2 204 
date: Thu, 03 Oct 2019 13:48:10 GMT`

returns HTTP/2 Status 204, with a date

---
_GET /api/system_status/grid_faults_

Not sure what this does...does it list the recent grid failure dates/times?

Request: `curl --cacert cacert.pem https://powerwall/api/system_status/grid_faults`

Response: `[{"timestamp":1569976192352,"alert_name":"PINV_a006_vfCheckUnderFrequency","alert_is_fault":false,"decoded_alert":"[{\"name\":\"PINV_alertID\",\"value\":\"PINV_a006_vfCheckUnderFrequency\"},{\"name\":\"PINV_alertType\",\"value\":\"Warning\"},{\"name\":\"PINV_a006_frequency\",\"value\":57.207,\"units\":\"Hz\"}]","alert_raw":432406325129904128,"git_hash":"14f7c1769ec307","site_uid":"xxxx","ecu_type":"TEPINV","ecu_package_part_number":"xxxxx","ecu_package_serial_number":"xxxxxx"}]`

---
_GET /api/sitemaster/stop_
_UPDATE: You need to be authenticated for this command_
This stops the powerwalls & gateway.  In the stopped state, the powerwall will not charge, discharge, or monitor solar, grid, battery, home statistics.

Request: `curl --cacert cacert.pem https://powerwall/api/sitemaster/stop`

Response:  

returns HTTP Status 500 if powerwall cannot be stopped at this moment with the following JSON: 

`{"code":500,"error":"Cannot Start Wizard","message":"Unable to stop sitemaster"}`

---
_GET /api/sitemaster/run_
_UPDATE: You need to be authenticated for this command_
This starts the powerwalls & gateway.  Use this after getting an authentication token to restart the powerwalls.

Request: `curl --cacert cacert.pem https://powerwall/api/sitemaster/run`

Response:  
Returns HTTPS Status 202 if request is accepted


---
_GET /api/config/completed_
_UPDATE: You need to be authenticated for this command_
This applies configuration changes.

Request: `curl --cacert cacert.pem https://powerwall/api/config/completed`

Response:
Returns HTTP Status 202 if input accepted


___
Note: __*** The below API calls require authentication ***__

Note2: __*** This documentation is old (created on version 1.15) and needs updating ***__
__*** I wouldn't be surprised if less than 1% of the below still works in versions 1.40+ ***__


**Login**
_POST /api/login/Basic_

Note: _This section needs updating: Does this work?_

**Authentication example:**
Note: Getting an authentication token will stop the powerwall.  It won't charge, discharge, or collect stats on v1.15+.  Therefore you should re-enable the powerwall after getting a token.  
See: the _/api/sitemaster/run_ section above.

Here is an example login using a blank username (none needed) and a serial number of T123456789.  The password is S+Serial number: ST123456789.

Request: 

`curl --cacert cacert.pem -s -i -X POST -H "Content-Type: application/json" -d '{"username":"","password":"ST123456789","force_sm_off":false}' https://powerwall/api/login/Basic`

Response: 

`{"email":null,"firstname":"Tesla","lastname":"Energy","roles":["Provider_Engineer"],"token":"OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==","provider":"Basic"}`

Save the token for use with the below calls.

**Note for Windows users:**
Windows shell handles quotes differently than linux Bash.
In windows, the above example works by:
1. changing the single quotes to double quotes
2. escape the double quotes inside the -d section

Windows Example Request: 

`curl -s -i -X POST -H "Content-Type: application/json" -d "{\"username\":\"\",\"password\":\"ST123456789\",\"force_sm_off\":false}" https://192.168.xxx.xxx/api/login/Basic`


---
_GET & POST /api/operation_
Change the Powerwall mode and Reserve Percentage

_Note 1: Making changes to the Powerwalls via the Mobile application can take some time to go into effect.  There's a rumor that states that the changes happen around 30 minutes past the hour. (Probably based on a cron job in Tesla's servers)._

_Note 2: Setting a value is not sufficient to make the change.  You must "save" or "commit" the configuration to have it go into effect.  See  the _Config Completed_ section below._

_Note 3: Once a value is changed and committed it is immediately in effect._


_GET_

request: `curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/operation`

response: `{"mode":"self_consumption","backup_reserve_percent":15}`


_POST_

The below request would set the battery mode to "Self-powered" and a "Reserve for Power Outages" to 20% (app value) using the token retrieved from the authentication example. 

request: `curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" -X POST -d '{"mode":"self_consumption","backup_reserve_percent":24.6}' https://192.168.xxx.xxx/api/operation`

response: `{"mode":"self_consumption","backup_reserve_percent":24.6}`

Valid Modes:
1. `self_consumption`
2. `backup`
3. `autonomous` (aka Time of Use (TOU) as reported by dlieu on the teslamotorsclub.com forums)
4. `scheduler`  aka Aggregation - This seems like it is not supported now. 

The JavaScript constant in the code of mobile client for Android has the following options:

```
OperationModes = 
{SELF_CONSUMPTION: "self_consumption",
TIME_OF_USE: "autonomous",
BACKUP: "backup",
AGGREGATION: "scheduler"}
```

There also is an option to set the max PV Export power in kW.  I'm not 100% sure what that does but I could guess (Time of use?). Mine is currently set to null (probably because time of use isn't enabled on my system yet (as of April 2018).  You can omit this key/value pair from the POST.

`{max_pv_export_power_kW: null, mode: "self_consumption", backup_reserve_percent: 24}`

Note the difference in the app value (20%) versus the value we set via the local API (24%).  The difference is likely proportional until you reach 100%:

___**Tested values:**___

| APP Setting | API Setting |
| :-------------: |:-------------:|
| 5%	| 10%		| 
| 16%	| 20%		|
| 16%	| 20.6%		|
| 20%	| 24%		|
| 21%	| 24.6% 	|
| 30%	| 33%		|
| 100%	| 100%		|


---

_GET /api/powerwalls/status_

Informational:

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/powerwalls/status`

Response:

`{"code":409,"error":"Sitemaster is current running","message":"Sitemaster is current running"}`

---
_GET /api/site_info/grid_codes_
Informational: setting options used in the wizard

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/site_info/grid_codes`

Response: 

[ Grid Codes Long JSON response here](https://raw.githubusercontent.com/vloschiavo/powerwall2/master/samples/api_site_info_grid_codes.json)

---

_GET /api/solars_

Informational: responds with the solar inverter brand, model, and max power rating as stored on the gateway.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/solars`

Reply:

`[{"brand":"SolarEdge Technologies","model":"SE5000 (240V) w/ -ER-US or A-US","power_rating_watts":6000}]`

---

_GET /api/solars/brands_

Informational: responds with the Solar inverter Brand options for the wizard.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/solars/brands > api_solars_brands.json`

[ Solar Brands - Long JSON response here](https://raw.githubusercontent.com/vloschiavo/powerwall2/master/samples/api_solars_brands.json)

---


_GET /api/solars/brands/SolarEdge%20Technologies_

Informational: Get a list of SolarEdge models - used in the wizard.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/solars/brands/SolarEdge%20Technologies`

Response

[ SolarEdge Models - Long JSON response here](https://raw.githubusercontent.com/vloschiavo/powerwall2/master/samples/solar_edge_models.json)

---

_GET /api/generators_

Note: I don't have a generator tied to my system.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" httsp://192.168.xxx.xxx/api/generators`

Response:

`{"disconnect_type":"None","generators":[]}`

---


_GET /api/customer_

Informational:

Request: 

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/customer`

Response:

`{"city":"New York","state":"New York ","zip":"10010","country":"US","registered":true,"privacy_notice":true,"limited_warranty":true,"emailed_registration":true}`

---


_GET /api/config_

Informational - I'm not sure what this is...

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/config`

Response:

`{vin: "0123456-00-E--T1234567890"}`


---
__Others to be documented:__

_GET /api/generators/disconnect_types_

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/generators/disconnect_types`


Response:

`["DownstreamATS"]`

---

_GET /api/meters_

Request: 

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/meters`

Response:

`[{"serial":"OBB3172012345","short_id":"49123","connected":true,"cts":[{"type":"solar","valid":[false,false,true,true],"inverted":[false,false,false,false]},{"type":"site","valid":[true,true,false,false],"inverted":[false,false,false,false]}]}]`

---


_GET /api/installer_

Details of the company that did the installation of the powerwall as well as your customer ID in their system.  This can be configured in the Wizard.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/installer`

Response:

 `{company: "Tesla Timbuktu", customer_id: "01234567", phone: "8885551212"}`

Alternative Response:
`{"company":"Tesla Orange County","customer_id":"1234567","phone":"1231234567","email":"...","run_sitemaster":true}`




---

__Others to document__

POST /api/sitemaster/run_for_commissioning

GET /api/customer/registration
{"privacy_notice":true,"limited_warranty":true,"grid_services":false,"marketing":true,"registered":true,"emailed_registration":true,"skipped_registration":false,"timed_out_registration":false}

POST /api/customer/registration/skip

GET /api/installer/companies
[{
		"company" : "1 Willpower Ltd",
		"customer_id" : "AN-0000059"
	}, {
		"company" : "1000 Energie",
		"customer_id" : "AN-0000062"
        }, {
                ... <LONG_LIST>
}]

POST /api/networks/wifi_scan

POST /api/networks
"Content-Type": "application/json"
{
        interface: K.InterfaceTypes.WIFI,
        network_name: ???,
	security_type: ???
}

POST /api/networks/<...>/disable
POST /api/networks/<...>/enable

POST /api/system/networks/conn_tests

while test is running the request returns:
{"results":null,"timestamp":"0001-01-01T00:00:00Z"}

when test is complete it returns:
{
	"results" : {
		"Config Syncer Test" : {
			"pass" : true,
			"error" : ""
		},
		"Gle GET Test" : {
			"pass" : true,
			"error" : ""
		},
		"Hermes Status Test" : {
			"pass" : true,
			"error" : ""
		},
		"Synergy Data Test" : {
			"pass" : true,
			"error" : ""
		}
	},
	"timestamp" : "2018-02-22T17:12:56.296673681-08:00"
}

Also need to research:
??? /api/system/networks/ping_test

POST /api/logging
{
	level: ???,
	log: ???
}

POST /api/customer/registration/emailed

POST /api/customer/registration/legal
"Content-Type": "application/json"
response:
{
	marketing: ???,
	privacy_notice: ???,
	limited_warranty: ???,
	grid_services: ???
}

GET /api/networks
returns all configured network adapters in gateway which seems running Linux:

can0 - very interesting unknown adapter (CAN-bus for the car??)
eth0 - ethernet
rpine0 - seems cellular network adapter (3G)
wifi0 - wireless adapter to connect to home network
wifi1 - configured as access point (TEG-XXXX)

[{
		"id" : 2,
		"name" : "can0",
		"connected" : true,
		"is_dhcp" : true,
		"ip_address" : "",
		"subnet" : "",
		"config" : null
	}, {
		"id" : 3,
		"name" : "eth0",
		"connected" : true,
		"is_dhcp" : true,
		"ip_address" : "",
		"subnet" : "",
		"config" : null
	}, {
		"id" : 170,
		"name" : "rpine0",
		"connected" : true,
		"is_dhcp" : true,
		"ip_address" : "",
		"subnet" : "",
		"config" : null
	}, {
		"id" : 171,
		"name" : "wifi0",
		"connected" : true,
		"is_dhcp" : true,
		"ip_address" : "<IP_ADDRESS>",
		"subnet" : "255.255.255.0",
		"config" : {
			"network_name" : "<AP_NAME>",
			"interface" : "WifiType",
			"security_type" : "WPA2_Personal",
			"dhcp" : true,
			"enabled" : true
		}
	}, {
		"id" : 172,
		"name" : "wifi1",
		"connected" : true,
		"is_dhcp" : true,
		"ip_address" : "192.168.91.1",
		"subnet" : "255.255.255.0",
		"config" : null
	}
]

GET /api/system/networks
[{
		"network_name" : "default_gsm",
		"interface" : "GsmType",
		"security_type" : "NONE",
		"dhcp" : null
	}, {
		"network_name" : "default_eth",
		"interface" : "EthType",
		"security_type" : "NONE",
		"dhcp" : true
	}, {
		"network_name" : "<AP_NAME>",
		"interface" : "WifiType",
		"security_type" : "WPA2_Personal",
		"dhcp" : true,
		"enabled" : true
	}
]

GET /api/networks/wifi_security_types
["NONE","WEP","WPAorWPA2_Personal"]

POST /api/meters/ABC1234567890/verify
"Content-Type": "application/json"
request's body: {"short_id":"12345","serial":" ABC1234567890 "}

GET /api/meters/readings
{
	"ABC1234567890" : {
		"error" : "",
		"data" : {
			"IP" : "Neurio-12345",
			"sensorId" : "0x<EIGHT_BYTES_HERE_IN_HEX_FORMAT>",
			"firmwareVersion" : "Tesla-0.0.7",
			"f_Hz" : 60,
			"cts" : [{
					"ct" : 1,
					"v_V" : 120.1,
					"p_W" : 345.07,
					"q_VAR" : -179.66,
					"eExp_Ws" : 12601671,
					"eImp_Ws" : 579265920
				}, {
					"ct" : 2,
					"v_V" : 120.81,
					"p_W" : 68.48,
					"q_VAR" : -109.03,
					"eExp_Ws" : 76422454,
					"eImp_Ws" : 447595772
				}, {
					"ct" : 3,
					"v_V" : 120.88,
					"p_W" : -0.2,
					"q_VAR" : 0,
					"eExp_Ws" : 258718,
					"eImp_Ws" : 32548
				}, {
					"ct" : 4,
					"v_V" : 120.1,
					"p_W" : -0.06,
					"q_VAR" : -0.17,
					"eExp_Ws" : 112940,
					"eImp_Ws" : 88921
				}
			]
		}
	}
}

GET /api/system/testing
{
	"running" : false,
	"status" : "TestPassed",
	"charge_tests" : [0, -1000, -2000, -1000, 0],
	"meter_results" : [[{
				"Power" : 575.6900024414062,
				"CT" : 1,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}, {
				"Power" : 71.94999694824219,
				"CT" : 2,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}
		], [{
				"Power" : 595.2100219726562,
				"CT" : 1,
				"Serial" : " ABC1234890",
				"Type" : "site"
			}, {
				"Power" : 71.5199966430664,
				"CT" : 2,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}
		], [{
				"Power" : 1064.7099609375,
				"CT" : 1,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}, {
				"Power" : 540.1099853515625,
				"CT" : 2,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}
		], [{
				"Power" : 1283.739990234375,
				"CT" : 1,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}, {
				"Power" : 779.1300048828125,
				"CT" : 2,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}
		], [{
				"Power" : 562.5499877929688,
				"CT" : 1,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}, {
				"Power" : 69.66999816894531,
				"CT" : 2,
				"Serial" : " ABC1234567890",
				"Type" : "site"
			}
		]],
	"inverter_results" : null,
	"hysteresis" : 0.05,
	"error" : "",
	"errors" : null,
	"tests" : null
}

---

