# Tesla Powerwall 2 - Local Gateway API documentation #

## Contributing ##

_(This documentation is currently in flux: portions are updated and portions aren't updated.  Use at your own risk)_

_(If you find issues, please submit pull requests - currently testing on firmware version 20.49.0)_

___*** Please be patient as I have an unrelated day job! ***___

**Please help me update this: Pull requests are welcome!**

## Overview ##

This is a list of api URLs and some random thoughts I've been able to pull together from the interwebs and other functions we've been able to reverse engineer from the local gateway.  This is not the [ Tesla Owner API] which you can find here: (https://tesla-api.timdorr.com) with a Python library that works nicely to control a Powerwall 2 here: (https://github.com/mlowijs/tesla_api).

### Libraries / apps using this API

The following projects are known to be using portions of this API, and may be useful for those looking to interact with Powerwall devices:

- [tesla_powerwall](https://github.com/jrester/tesla_powerwall) client library for Python
- [go-powerwall](https://github.com/foogod/go-powerwall) client library for Go
- [Powerwall exporter for Prometheus](https://github.com/foogod/powerwall_exporter) (uses the `go-powerwall` library)

## Getting Started ##

### A note about HTTPS and SSL Certificates ###

In a recent update to the Powerwall firmware (v1.20+) non-SSL requests (http) are no longer supported and queries will return HTTP/1.1 301 Moved Permanently.  Unfortunately the certificate presented by the Powerwall is not signed by a root certificate authority as they are self-signed.  This results in web browsers and tools like curl not accept it without it either being included as a trusted certificate or a specific action by the user to override the error. 

You have three ways around a certificate error:

1) In web browser this will manifest itself as an error that the certificate is not trusted.  To bypass simply click "details" (IE/Edge) or "Advanced..." (Firefox) and select continue.

2) With curl the `--insecure` or `-k` option will ignore the SSL certificate.  This is ok, but it doesn't authenticate the device you are connecting to.

3) A better way is to export the Powerwall public certificate and add it to the local machine's trusted certificate list or just use the certificate in your curl request.

__I recommend option 3 above.__

In addition to the issues of validating the certificate itself, the Powerwall gateway also apparently uses [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) when serving the TLS certificate, and will simply abort the connection if the wrong hostname is presented via SNI when establishing the TLS connection.  It can therefore only be accessed using a few set hostnames (and if you put its IP address in your local DNS or hosts file with a different name, it will likely not work).

Hostnames which are known to work to access a Powerwall:

- (IP address)
- teg
- powerwall
- powerpack

Note that none of these names have any domain component.  That means you *must* access the Powerwall as, for example, `https://powerwall/`.  Something like `https://powerwall.mycooldomain.net/` will not work (even if `mycooldomain.net` is configured to have the necessary DNS entry).

If you want to access your Powerwall using a name other than one of the above, you will likely need to do some custom hacking with your client's HTTPS/TLS settings to provide one of these names via SNI instead of the actual hostname (note that not all clients support this).

_Here's what worked for me:_

Step 1: DNS

Enable DNS lookups, on your local network, for one of the hostnames listed above (for example, `powerwall`) pointing to the device's IP address.

You can add this to your local DNS server as an A Record or /etc/hosts file or other DNS name resolution service.  

For /etc/hosts add an entry that looks like this if your Powerwall gateway's IP was 192.168.99.99:

`192.168.99.99	powerwall`

Step 2: Get the certificate
`openssl s_client -showcerts -connect powerwall:443 < /dev/null | sed --quiet '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' > cacert.pem`

This grabs the certificate from the powerwall using the DNS entry you setup in step 1.

Step 3: use the certificate in your curl statements
e.g. `curl --cacert cacert.pem https://powerwall/api/status`

If you get this error: `curl: (51) SSL: no alternative certificate subject name matches target host name` then the name you chose (teg or powerwall or powerpack) doesn't match what's in the certificate file and you'll need to check the certificate and perhaps do some googling to figure out the solution.

For the rest of the documentation, I will assume you copied the certificate and are using method C with the Powerwall's public certificate.  If you didn't, just leave out the certificate `--cacert cacert.pem` portion and add `-k`.


Powerwall 2 Web UI
---
The web UI provides ~~an instantaneous~~ a 250-500ms average(?) power flow diagram an access to the wizard.
Hit your local gateway IP with a browser, i.e. _https://powerwall/

You should see something like this:

![GatewayUI](img/TeslaPowerwallGatewayUI.jpg "Gateway Web UI")

---
**Wizard**
You can hit the _"Login"_ link on this page and go through the setup (be careful what you change in the wizard).

`username: <Enter whatever you like here>`

`password: `
Follow the instructions on the web page to set/change/recover the password. Whatever you set here will be used later.

As of version 20.49.0, the password you set here will be required to pull any of the URIs (statistics & settings) listed below.

Check out the bash script [powerwallstats.sh](samples/powerwallstats.sh) in the samples directory for an example: 
___

## API Reference

### Alternative API documentation in the form of OpenAPI Spec

An alternative to the below README form of documenting the APIs can be seen in [openapi](openapi) folder.  OpenAPI spec is a machine-readable format that can be used to generate documentation, client libraries, and more.

You can also view the OpenAPI spec using the Swagger viewer by going to https://vloschiavo.github.io/powerwall2/openapi/

Advantages of OpenAPI spec:

- Industry standard format for documenting APIs
- Machine-readable format
- Can be used to generate client libraries
- Swagger UI presents the spec in an easy to read format
- With the right setup, you can use the Swagger UI to test the API endpoints against your own Powerwall

Disadvantages of OpenAPI spec:

- Not as human-readable as the README format
- Not as easy to contribute to as the README format

---

### Base Endpoint

`https://<tesla-powerwall-ip>/api/`

### Key ###

| Symbol | Meaning |
| - | - |
| :heavy_check_mark: | Yes |
| :x: or _\<blank>_ | No |
| 🚧 | Requires updating or has partial info |

### Overview

Endpoint | Method | Requires Authentication? | Documented? | Summary
| - | - | - | - | - |
| `/${e}`                                       | GET    |  |  |  |
| `/auth/toggle/login`                          | POST   |  |  |  |
|                                               | DELETE |  |  |  |
| `/auth/toggle/start`                          | POST   |  |  |  |
| `/auth/toggle/supported`                      | GET    |  |  |  |
| `/autoconfig/cancel`                          | POST   |  |  |  |
| `/autoconfig/retry`                           | POST   |  |  |  |
| `/autoconfig/run`                             | POST   |  |  |  |
| `/autoconfig/status`                          | GET    |  |  |  |
| `/config`                                     | [GET](#get-apiconfig)    | :heavy_check_mark: | 🚧 |  |
| `/config/completed`                           | [GET](#get-apiconfigcompleted)    | :heavy_check_mark: | :heavy_check_mark: | Applies config changes |
| `/customer`                                   | [GET](#get-apicustomer)    | :heavy_check_mark: | :heavy_check_mark: |  |
|                                               | POST   |  |  |  |
| `/customer/registration`                      | [GET](#get-apicustomerregistration)    | :x: | :heavy_check_mark: |  |
| `/customer/registration/legal`                | [POST](#post-apicustomerregistrationlegal)   | 🚧 | 🚧 |  |
| `/customer/registration/skip`                 | [POST](#post-apicustomerregistrationskip)   | 🚧 | 🚧 |  |
| `/devices/vitals`                                   | [GET](#get-apidevicesvitals)    | :heavy_check_mark: | 🚧 |  |
| `/generators`                                 | [GET](#get-apigenerators) | :heavy_check_mark: | 🚧 |  |
| `/generators/disconnect_types`                | [GET](#get-apigeneratorsdisconnect_types) | :heavy_check_mark: | 🚧 |  |
| `/installer`                                  | [GET](#get-apiinstaller)     | :heavy_check_mark: | :heavy_check_mark: |  |
| `/installer/companies`                        | [GET](#get-apiinstallercompanies)     | 🚧 | 🚧 |  |
| `/logging`                                    | POST   |  |  |  |
| `/login/Basic`                                | [POST](#post-apiloginbasic)   | :x: | 🚧 |  |
| `/logout`                                     | [GET](#get-apilogout)    | 🚧 | 🚧 |  |
| `/meters`                                     | [GET](#get-apimeters)    | :heavy_check_mark: | 🚧 |  |
|                                               | POST   |  |  |  |
| `/meters/${e}/ct_config`                      | GET    |  |  |  |
|                                               | POST   |  |  |  |
| `/meters/${e}/cts`                            | DELETE |  |  |  |
| `/meters/${e}/invert_cts`                     | POST   |  |  |  |
| `/meters/${i}/commission`                     | POST   |  |  |  |
| `/meters/${o.serial}/cts`                     | POST   |  |  |  |
| `/meters/${t}`                                | DELETE |  |  |  |
| `/meters/${t}/verify`                         | [POST](#post-apimetersabc1234567890verify)   | 🚧 | 🚧 |  |
| `/meters/aggregates`                          | [GET](#get-apimetersaggregates)    | :heavy_check_mark: | :heavy_check_mark: | Instantaneous readings from the CT clamps |
| `/meters/detect_wired_meters`                 | POST   |  |  |  |
| `/meters/readings`                            | [GET](#get-apimetersreadings)    | :heavy_check_mark: | 🚧 |  |
| `/meters/status`                              | GET    | :heavy_check_mark: |  |  |
| `/meters/verify`                              | POST   |  |  |  |
| `/networks`                                   | [GET](#get-apinetworks)    | :heavy_check_mark: | 🚧 |  |
|                                               | [POST](#post-apinetworks)   | :heavy_check_mark: | 🚧 |  |
|                                               | DELETE | :heavy_check_mark: | :x: |  |
| `/networks/${e}/disconnect`                   | DELETE |  |  |  |
| `/networks/client_protocols`                  | GET    |  |  |  |
|                                               | POST   |  |  |  |
| `/networks/connect`                           | POST   |  |  |  |
| `/networks/enable_${e}`                       | POST   |  |  |  |
| `/networks/request_scan_wifi`                 | POST   |  |  |  |
| `/operation`                                  | [GET](#apioperation)    | :heavy_check_mark: | :heavy_check_mark: |  |
|                                               | [POST](#apioperation)   | :heavy_check_mark: | :heavy_check_mark: |  |
| `/password/change`                            | POST   |  |  |  |
| `/password/generate`                          | POST   |  |  |  |
| `/password/reset`                             | POST   |  |  |  |
| `/powerwalls`                                 | [GET](#get-apipowerwalls)    | :heavy_check_mark: | :heavy_check_mark: |  |  |
| `/powerwalls/phase_detection`                 | GET    |  |  |  |
| `/powerwalls/phase_usages`                    | GET    |  |  |  |
| `/powerwalls/status`                          | [GET](#get-apipowerwallsstatus)    | :heavy_check_mark: | :heavy_check_mark: |  |
| `/powerwalls/update`                          | GET    |  |  |  |
| `/site_info`                                  | [GET](#get-apisite_info)    | :heavy_check_mark: | :heavy_check_mark: | High Level info about site and grid the powerwall connected to |
| `/site_info/grid_code`                        | POST   |  | :x: |  |
| `/site_info/grid_codes`                       | [GET](#get-apisite_infogrid_codes)   | :heavy_check_mark: | :heavy_check_mark: |  |
| `/site_info/grid_regions`                     | GET    |  |  |  |
| `/site_info/offgrid`                          | POST   |  |  |  |
| `/site_info/site_name`                        | [GET](#get-apisite_infosite_name)    | :heavy_check_mark: | :heavy_check_mark: | Name of the site + timezone |
|                                               | POST   |  |  |  |
| `/site_info/timezone`                         | POST   |  |  |  |
| `/sitemaster`                                 | [GET](#get-apisitemaster)    | :heavy_check_mark: | :heavy_check_mark: |  |
| `/sitemaster/run`                             | [GET](#get-apisitemasterrun)    | :heavy_check_mark: | :heavy_check_mark: | Starts the Powerwall electricity flow |
| `/sitemaster/run_for_commissioning`           | [POST](#post-apisitemasterrun_for_commissioning)   |  |  |  |
| `/sitemaster/stop`                            | [GET](#get-apisitemasterstop)    | :heavy_check_mark: | :heavy_check_mark: | Stops the Powerwall electricity flow |
| `/solar_powerwall/${n}/power_status`          | GET    |  |  |  |
| `/solar_powerwall/${t}/reset`                 | GET    |  |  |  |
| `/solar_powerwall/power_status`               | GET    |  |  |  |
| `/solar_powerwall/reset`                      | GET    |  |  |  |
| `/solars`                                     | [GET](#get-apisolars)    | :heavy_check_mark: | :heavy_check_mark: |  |
| `/solars/brands`                              | [GET](#get-apisolarsbrands)    | :heavy_check_mark: | :heavy_check_mark: |  |
| `/solars/brands/${brand}`                     | [GET](#get-apisolarsbrandssolaredge20technologies)    | :heavy_check_mark: | :heavy_check_mark: |  |
| `/status`                                     | [GET](#get-apistatus)    | :x: | :heavy_check_mark: | Information about the gateway software version |
| `/synchrometer/ct_voltage_references`         | GET    |  |  |  |
|                                               | POST   |  |  |  |
| `/synchrometer/ct_voltage_references/options` | GET    |  |  |  |
| `/system/networks/conn_tests`                 | GET    |  |  |  |
|                                               | POST   |  |  |  |
| `/system/networks/ping_test`                  | [POST](#apisystemnetworksping_test)   | 🚧 | 🚧 |  |
| `/system/testing`                             | [GET](#get-apisystemtesting)    | 🚧 | 🚧  |  |  |
|                                               | DELETE |  |  |  |
| `/system/testing/PINV_TEST`                   | POST   |  |  |  |
| `/system/update/status`                       | [GET](#get-apisystemupdatestatus)  | :heavy_check_mark: | :heavy_check_mark: |  |
| `/system_status`                  | [GET](#get-apisystem_status)    | :heavy_check_mark: | 🚧 |  |
| `/system_status/grid_faults`                  | [GET](#get-apisystem_statusgrid_faults)    | :heavy_check_mark: | 🚧 |  |
| `/system_status/grid_status`                  | [GET](#get-apisystem_statusgrid_status)    | :heavy_check_mark: | :heavy_check_mark: | Whether the Powerwall is on or off grid |
| `/system_status/soe`                          | [GET](#get-apisystem_statussoe)    | :heavy_check_mark: | :heavy_check_mark: | Powerwall charged percentage |
| `/v2/islanding/mode`                          | [POST](#post-apiv2islandingmode)   | :heavy_check_mark: | :heavy_check_mark: | Go on or off-grid |

<sub>_Table partially generated using https://github.com/vls29/tesla-powerwall2-api-to-table_</sub>

---
#### _GET /api/meters/aggregates_ ####

request: `curl --cacert cacert.pem https://powerwall/api/meters/aggregates`

response: [see sample response here](samples/api_meters_aggregates.json
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

#### _GET /api/meters/site_ ####

Detailed information about the site specific meter.

request: `curl --cacert cacert.pem https://powerwall/api/meters/site`

response: [see sample response here](samples/api-meters-site.json)

#### _GET /api/meters/solar_ ####

Detailed information about the solar specific meter.

request: `curl --cacert cacert.pem https://powerwall/api/meters/solar`

response: [see sample response here](samples/api-meters-solar.json)


---
**State of Charge / State of Energy**
#### _GET /api/system_status/soe_ ####

This returns the aggregate charge state in percent of the powerwall(s).

request: `curl --cacert cacert.pem https://powerwall/api/system_status/soe`

response:	`{"percentage":69.1675560298826}`

When site master or the Powerwalls are off, the response is: HTTP Status 502

---

#### _GET /api/sitemaster_ ####
Use this URL to determine: 
1. Powerwall state {running|stopped}
2. How long the powerwall has been set to the running state {in seconds}
3. Is the powerwall gateway connected to Tesla's servers {true|false}}

request: `curl --cacert cacert.pem https://powerwall/api/sitemaster`

response:	`{"running":true,"uptime":"802459s,","connected_to_tesla":true}`

When site master or the Powerwalls are off, the response is:  `{"running":false,"uptime":"log:","connected_to_tesla":false}`

---

#### _GET /api/powerwalls_ ####
Use this URL to determine how many power walls you have, their serial numbers, and if they are in sync (assuming more than one powerwall).

request: `curl --cacert cacert.pem https://powerwall/api/powerwalls`

response:	[see sample response here](samples/api-powerwalls.json)

I have two of the AC Powerwall 2s in the United States.  The PackagePartNumber is: 1092170-03-E.  Let me know if you have a different package part number and what Powerwall model you have.  (i.e. DC, AC, Powerwall v1 or v2)


---

#### _GET /api/customer/registration_ ####
Use this URL to determine registration status.  The below shows the results from a system that is fully configured and running.

request: `curl --cacert cacert.pem https://powerwall/api/customer/registration`

response: `{"privacy_notice":true,"limited_warranty":true,"grid_services":null,"marketing":null,"registered":true,"timed_out_registration":false}`

---
#### _GET /api/system_status_ ####

Provides information on batteries and inverters. (**nominal_full_pack_energy** is useful for monitoring degradation over time, as discussed here: (https://teslamotorsclub.com/tmc/threads/powerwall-2-available-energy-after-2-years.228580/#post-5537358).

Request: `curl --cacert cacert.pem https://powerwall/api/system_status`

---

#### _GET /api/system_status/grid_status_ ####
Determine if the Grid is up or down.

request: `curl --cacert cacert.pem https://powerwall/api/system_status/grid_status`

response: {"grid_status":"SystemGridConnected","grid_services_active":false}

`{"grid_status":"SystemGridConnected"}` = grid is up

`{"grid_status":"SystemIslandedActive"}` = grid is down

`{"grid_status":"SystemTransitionToGrid"}` = grid is restored but not yet in sync.

---
#### _GET /api/system/update/status_ ####
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

-   "ignoring", // possibly some uninterruptible action is in progress?  
    
-   "error",  
    
-   "nonactionable" // everything is OK  
    

  

Use case:  One user is making this request to check new firmware available, and run the upgrade, approximately 30 minutes before switching to discharging (self_consumption mode with 5% reserve). Assumption is - we better upgrade firmware while battery is in standby mode, rather then letting gateway upgrade itself later, because it will stop battery possibly during peak hours for an upgrade. He noticed his gateway has self-upgraded during peak hours, resulting around 15 minutes stop of battery, which was an unpleasant surprise and extra cost. So, his idea was to force a new firmware check (and upgrade) when battery is not used:

  
-   7:15am  check for new firmware and run an upgrade if firmware is available  
    
-   7:55am  - start discharging (self_consumption, 5% reserve)  
    
-   10:05pm  - start charging (backup, 100% reserve)  
    

Southern California Edison has TOU plan with the following details:

-   8am-2pm,  8pm-10pm  - offpeak  
    
-   2pm-8pm  - peak  
    
-   10pm-8am  - super offpeak

---	
#### _GET /api/site_info_ ####

request: `curl --cacert cacert.pem https://powerwall/api/site_info`

response: `{"max_site_meter_power_kW":1000000000,"min_site_meter_power_kW":-1000000000,"nominal_system_energy_kWh":13.5,"nominal_system_power_kW":10,"site_name":"Loschiavo","timezone":"America/Los_Angeles","grid_code":"60Hz_240V_s_UL1741SA:2016_California","grid_voltage_setting":240,"grid_freq_setting":60,"grid_phase_setting":"Split","country":"United States","state":"California","distributor":"*","utility":"Pacific Gas and Electric Company","retailer":"*","region":"UL1741SA"}`

---

#### _GET /api/site_info/site_name_ ####

request: `curl --cacert cacert.pem https://powerwall/api/site_info/site_name`

response: `{"site_name":"Home Energy Gateway","timezone":"America/Los_Angeles"}`

The site_name value can be changed from the Tesla Mobile app settings.

---
#### _GET /api/status_ ####

request: `curl --cacert cacert.pem https://powerwall/api/status`

response: `{"start_time":"2019-09-23 23:38:46 +0800","up_time_seconds":"223h5m51.577762169s","is_new":false,"version":"1.40.2","git_hash":"14f7c1769ec307bba2ea62355a09d01c8e58988c+"}`

Useful here: Gateway Version:  "version":"1.40.2\n"

---

#### _GET /api/logout_ ####

The Gateway Web UI uses this url to logout of the wizard.  I assume you can also use this to expire an auth token...(some testing is required).
_This is untested. Question for the community: Does this still work? Soliciting for pull requests! :)_

Request: `curl --cacert cacert.pem -i https://powerwall/api/logout`

Response: `HTTP/2 204 
date: Thu, 03 Oct 2019 13:48:10 GMT`

returns HTTP/2 Status 204, with a date

---

#### _GET /api/system_status/grid_faults_ ####

Not sure what this does...does it list the recent grid failure dates/times?

Request: `curl --cacert cacert.pem https://powerwall/api/system_status/grid_faults`

Response: `[{"timestamp":1569976192352,"alert_name":"PINV_a006_vfCheckUnderFrequency","alert_is_fault":false,"decoded_alert":"[{\"name\":\"PINV_alertID\",\"value\":\"PINV_a006_vfCheckUnderFrequency\"},{\"name\":\"PINV_alertType\",\"value\":\"Warning\"},{\"name\":\"PINV_a006_frequency\",\"value\":57.207,\"units\":\"Hz\"}]","alert_raw":432406325129904128,"git_hash":"14f7c1769ec307","site_uid":"xxxx","ecu_type":"TEPINV","ecu_package_part_number":"xxxxx","ecu_package_serial_number":"xxxxxx"}]`

---
#### _GET /api/sitemaster/stop_ ####
_UPDATE: You need to be authenticated for this command_
This stops the powerwalls & gateway.  In the stopped state, the powerwall will not charge, discharge, or monitor solar, grid, battery, home statistics.

Request: `curl --cacert cacert.pem https://powerwall/api/sitemaster/stop`

Response:  

returns HTTP Status 500 if powerwall cannot be stopped at this moment with the following JSON: 

`{"code":500,"error":"Cannot Start Wizard","message":"Unable to stop sitemaster"}`

---
#### _GET /api/sitemaster/run_ ####
_UPDATE: You need to be authenticated for this command_
This starts the powerwalls & gateway.  Use this after getting an authentication token to restart the powerwalls.

Request: `curl --cacert cacert.pem https://powerwall/api/sitemaster/run`

Response:  
Returns HTTPS Status 202 if request is accepted


---
#### _GET /api/config/completed_ ####
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
#### _POST /api/login/Basic_ ####

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
#### _/api/operation_ ####
Change the Powerwall mode and Reserve Percentage

_Note 1: Making changes to the Powerwalls via the Mobile application can take some time to go into effect.  There's a rumor that states that the changes happen around 30 minutes past the hour. (Probably based on a cron job in Tesla's servers)._

_Note 2: Setting a value is not sufficient to make the change.  You must "save" or "commit" the configuration to have it go into effect.  See  the _Config Completed_ section below._

_Note 3: Once a value is changed and committed it is immediately in effect._


#### _GET /api/operation_ ####

request: `curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/operation`

response: `{"mode":"self_consumption","backup_reserve_percent":15}`


#### _POST /api/operation_ ####

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

#### _GET /api/powerwalls/status_ ####

Informational:

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/powerwalls/status`

Response:

`{"code":409,"error":"Sitemaster is current running","message":"Sitemaster is current running"}`

---
#### _GET /api/site_info/grid_codes_ ####

_vls29 - I couldn't find this endpoint in the javascript file and it returns 404_

Informational: setting options used in the wizard

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/site_info/grid_codes`

Response: 

[ Grid Codes Long JSON response here](samples/api_site_info_grid_codes.json)

---

#### _GET /api/solars_ ####

Informational: responds with the solar inverter brand, model, and max power rating as stored on the gateway.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/solars`

Reply:

`[{"brand":"SolarEdge Technologies","model":"SE5000 (240V) w/ -ER-US or A-US","power_rating_watts":6000}]`

---

#### _GET /api/solars/brands_ ####

Informational: responds with the Solar inverter Brand options for the wizard.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/solars/brands > api_solars_brands.json`

[ Solar Brands - Long JSON response here](samples/api_solars_brands.json)

---


#### _GET /api/solars/brands/SolarEdge%20Technologies_ ####

Informational: Get a list of SolarEdge models - used in the wizard.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/solars/brands/SolarEdge%20Technologies`

Response

[ SolarEdge Models - Long JSON response here](samples/solar_edge_models.json)

---

#### _GET /api/generators_ ####

Note: I don't have a generator tied to my system.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" httsp://192.168.xxx.xxx/api/generators`

Response:

`{"disconnect_type":"None","generators":[]}`

---


#### _GET /api/customer_ ####

Informational:

Request: 

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/customer`

Response:

`{"city":"New York","state":"New York ","zip":"10010","country":"US","registered":true,"privacy_notice":true,"limited_warranty":true,"emailed_registration":true}`

---


#### _GET /api/config_ ####

Informational - I'm not sure what this is...

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/config`

Response:

`{vin: "0123456-00-E--T1234567890"}`


---

#### _POST /api/v2/islanding/mode_

Sets whether the powerwall is on or off grid.  Change the value in the POSTed data to change to off-grid (`intentional_reconnect_failsafe`) or on-grid (`backup`).

##### Switch to Off-grid mode

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" -X POST -d '{"island_mode":"intentional_reconnect_failsafe"}' https://192.168.xxx.xxx/api/v2/islanding/mode`

Response:
```json
{
    "island_mode": "intentional_reconnect_failsafe"
}
```

Note that subsequent calls to [/api/system_status/grid_status/](#get-apisystem_statusgrid_status) will return `grid_status: "SystemIslandedActive"` once the system is in off-grid mode.

##### Switch to On-grid mode

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" -X POST -d '{"island_mode":"backup"}' https://192.168.xxx.xxx/api/v2/islanding/mode`

Response:
```json
{
    "island_mode": "backup"
}
```

Note that subsequent calls to [/api/system_status/grid_status/](#get-apisystem_statusgrid_status) will return `grid_status: "SystemGridConnected"` once the system is back in on-grid mode.

---

__Others to be documented:__

#### _GET /api/devices/vitals_ ####

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" -o https://192.168.xxx.xxx/api/devices/vitals`


Response:

darryllee - Found when I logged into my Gateway as an Installer, this returns a binary file with what looks like interesting information including:
```
THC_State THC_STATE_AUTONOMOUSCONTROL
THC_AmbientTemp!
...
POD_nom_energy_to_be_charged!
POD_nom_energy_remaining!
POD_nom_full_pack_energy!
POD_available_charge_power!
POD_available_dischg_power!
POD_curtailed_charge_power!
POD_curtailed_dischg_power!
POD_est_DC_Bus_Power!
        POD_Ibatt!
        POD_Vbatt!
POD_DC_Bus_Voltage!
        POD_state*
POD_ACTIVE
POD_enable_line0
POD_ChargeComplete0
POD_DischargeComplete0
POD_PersistentlyFaulted0
POD_PermanentlyFaulted0
POD_ChargeRequest0
POD_ActiveHeating0
POD_Resting0
POD_CCVhold0
POD_HeatZeroCurrentReg0
POD_ExtendedCapacityMode0
POD_IpcRequestedBusUp0
POD_SelfTestRequested0
```

jasonacox - The binary file is a *protobuf* payload.  It includes all devices including metrics for string data. Without the proto schema, the `protoc` tool can decode the raw file (some information will be missing without the schema):

```bash
protoc --decode_raw < vitals
```

The output represents the data in `{ ... }` groupings with number prefixing and key values in hex, strings or 1/0 boolean. Thanks to @brianhealey we have a working [tesla.proto](tesla.proto) file.  This can be used to decode the *protobuf* payload (e.g. `protoc --python_out=. tesla.proto`).  

A decoded output example /api/devices/vitals from [pypowerwall](https://github.com/jasonacox/pypowerwall) (`pw.vitals()`) looks like this:

Full example: [samples/api-devices-vitals.json](samples/api-devices-vitals.json)

Some interesting data points:
```json
    "STSTSM--1232100-00-E--TTTTTTTTTTTTTT": {
        "Parent": "",
        "STSTSM-Location": "Gateway",
        "firmwareVersion": "2021-11-02-g3d303deef",
        "lastCommunicationTime": "1639168200",
        "manufacturer": "TESLA",
        "partNumber": "1232100-00-E",
        "serialNumber": "TTTTTTTTTTTTTT"
    },
	"NEURIO--VVVVVVVVVVVVV": {
        "NEURIO_CT0_InstRealPower": 1576.0756967629245,
        "NEURIO_CT0_Location": "solar",
...
    },
    "PVAC--1538100-00-F--CCCCCCCCCCCCCC": {
...
        "PVAC_LifetimeEnergyPV_Total": 1543380.0,
        "PVAC_PVCurrent_A": 2.24,
        "PVAC_PVCurrent_B": 0.0,
        "PVAC_PVCurrent_C": 1.62,
        "PVAC_PVCurrent_D": 1.6,
        "PVAC_PVMeasuredPower_A": 552.0,
        "PVAC_PVMeasuredPower_B": 0.0,
        "PVAC_PVMeasuredPower_C": 508.0,
        "PVAC_PVMeasuredPower_D": 503.0,
        "PVAC_PVMeasuredVoltage_A": 244.8,
        "PVAC_PVMeasuredVoltage_B": -2.5,
        "PVAC_PVMeasuredVoltage_C": 314.5,
        "PVAC_PVMeasuredVoltage_D": 315.20000000000005,
        "PVAC_Pout": 1610.0,
        "PVAC_PvState_A": "PV_Active",
        "PVAC_PvState_B": "PV_Active",
        "PVAC_PvState_C": "PV_Active",
        "PVAC_PvState_D": "PV_Active_Parallel",
        "PVAC_Qout": 20.0,
...
    },
    "PVS--1538100-00-F--CCCCCCCCCCCCCC": {
...
        "PVS_StringA_Connected": true,
        "PVS_StringB_Connected": false,
        "PVS_StringC_Connected": true,
        "PVS_StringD_Connected": true,
        "PVS_vLL": 241.5,
...
    },
	"TEPINV--1081100-10-U--SSSSSSSSSSS": {
        "PINV_EnergyCharged": 439040.0,
        "PINV_EnergyDischarged": 383090.0,
...
        "PINV_PllFrequency": 59.969,
        "PINV_PllLocked": true,
        "PINV_Pout": -0.19,
        "PINV_PowerLimiter": "PWRLIM_POD_Power_Limit",
        "PINV_Qout": 0.0,
        "PINV_ReadyForGridForming": true,
        "PINV_State": "PINV_GridFollowing",
        "PINV_VSplit1": 120.9,
        "PINV_VSplit2": 120.30000000000001,
        "PINV_Vout": 241.10000000000002,
...
    },
	"TEPOD--1081100-10-U--SSSSSSSSSSS": {
        "POD_ActiveHeating": false,
        "POD_CCVhold": false,
        "POD_ChargeComplete": false,
        "POD_ChargeRequest": false,
        "POD_DischargeComplete": false,
        "POD_PermanentlyFaulted": false,
        "POD_PersistentlyFaulted": false,
        "POD_available_charge_power": 7000.0,
        "POD_available_dischg_power": 12000.0,
        "POD_enable_line": true,
        "POD_nom_energy_remaining": 8636.0,
        "POD_nom_energy_to_be_charged": 5685.0,
        "POD_nom_full_pack_energy": 13990.0,
        "POD_state": "POD_ACTIVE",
...
    },
	"TESYNC--1493315-01-F--77777777777777": {
        "ISLAND_FreqL1_Load": 59.980000000000004,
        "ISLAND_FreqL1_Main": 59.980000000000004,
        "ISLAND_FreqL2_Load": 60.010000000000005,
        "ISLAND_FreqL2_Main": 60.0,
...
        "ISLAND_GridConnected": true,
        "ISLAND_GridState": "ISLAND_GridState_Grid_Compliant",
        "ISLAND_L1L2PhaseDelta": -256.0,
        "ISLAND_L1L3PhaseDelta": -256.0,
        "ISLAND_L1MicrogridOk": true,
        "ISLAND_L2L3PhaseDelta": -256.0,
        "ISLAND_L2MicrogridOk": true,
        "ISLAND_L3MicrogridOk": false,
        "ISLAND_PhaseL1_Main_Load": 0.0,
        "ISLAND_PhaseL2_Main_Load": 0.0,
        "ISLAND_PhaseL3_Main_Load": -256.0,
        "ISLAND_ReadyForSynchronization": true,
        "ISLAND_VL1N_Load": 121.0,
        "ISLAND_VL1N_Main": 121.0,
        "ISLAND_VL2N_Load": 121.0,
        "ISLAND_VL2N_Main": 121.0,
        "ISLAND_VL3N_Load": 0.0,
        "ISLAND_VL3N_Main": 0.0,
        "METER_X_CTA_I": 4.2525,
        "METER_X_CTA_InstReactivePower": -13.0,
        "METER_X_CTA_InstRealPower": 434.0,
        "METER_X_CTB_I": 3.9210000000000003,
        "METER_X_CTB_InstReactivePower": -44.0,
        "METER_X_CTB_InstRealPower": -433.0,
        "METER_X_CTC_I": 0.0,
        "METER_X_CTC_InstReactivePower": 0.0,
        "METER_X_CTC_InstRealPower": 0.0,
        "METER_X_LifetimeEnergyExport": 372371.0,
        "METER_X_LifetimeEnergyImport": 1904776.0,
        "METER_X_VL1N": 120.3,
        "METER_X_VL2N": 120.68,
        "METER_X_VL3N": 0.0,
        "METER_Y_CTA_I": 0.0,
        "METER_Y_CTA_InstReactivePower": 0.0,
        "METER_Y_CTA_InstRealPower": 0.0,
        "METER_Y_CTB_I": 0.0,
        "METER_Y_CTB_InstReactivePower": 0.0,
        "METER_Y_CTB_InstRealPower": 0.0,
        "METER_Y_CTC_I": 0.0,
        "METER_Y_CTC_InstReactivePower": 0.0,
        "METER_Y_CTC_InstRealPower": 0.0,
        "METER_Y_LifetimeEnergyExport": 0.0,
        "METER_Y_LifetimeEnergyImport": 2.0,
        "METER_Y_VL1N": 120.31,
        "METER_Y_VL2N": 120.68,
        "METER_Y_VL3N": 0.0,
...
    },
    "TETHC--2012170-25-E--44444444444444": {
        "Parent": "STSTSM--1232100-00-E--TTTTTTTTTTTTTT",
        "THC_AmbientTemp": 16.0,
        "THC_State": "THC_STATE_AUTONOMOUSCONTROL",
...
    },
```

---

#### _GET /api/generators/disconnect_types_ ####

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/generators/disconnect_types`


Response:

`["DownstreamATS"]`

---

#### _GET /api/meters_ ####

Request: 

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/meters`

Response:

`[{"serial":"OBB3172012345","short_id":"49123","connected":true,"cts":[{"type":"solar","valid":[false,false,true,true],"inverted":[false,false,false,false]},{"type":"site","valid":[true,true,false,false],"inverted":[false,false,false,false]}]}]`

---


#### _GET /api/installer_ ####

Details of the company that did the installation of the powerwall as well as your customer ID in their system.  This can be configured in the Wizard.

Request:

`curl --header "Authorization: Bearer OgiGHjoNvwx17SRIaYFIOWPJSaKBYwmMGc5K4tTz57EziltPYsdtjU_DJ08tJqaWbWjTuI3fa_8QW32ED5zg1A==" https://192.168.xxx.xxx/api/installer`

Response:

 `{company: "Tesla Timbuktu", customer_id: "01234567", phone: "8885551212"}`

Alternative Response:
`{"company":"Tesla Orange County","customer_id":"1234567","phone":"1231234567","email":"...","run_sitemaster":true}`




---

__Others to document__

#### _POST /api/sitemaster/run_for_commissioning_ ####

#### _POST /api/customer/registration/skip_ ####

_vls29 - I couldn't find this endpoint in the javascript file and it returns 404_

#### _GET /api/installer/companies_ ####
[{
		"company" : "1 Willpower Ltd",
		"customer_id" : "AN-0000059"
	}, {
		"company" : "1000 Energie",
		"customer_id" : "AN-0000062"
        }, {
                ... <LONG_LIST>
}]

#### _POST /api/networks/wifi_scan_ ####

_vls29 - I couldn't find this endpoint in the javascript file and it returns 404_

#### _POST /api/networks_ ####
"Content-Type": "application/json"
{
        interface: K.InterfaceTypes.WIFI,
        network_name: ???,
	security_type: ???
}

#### _POST /api/networks/<...>/disable_ ####

#### _POST /api/networks/<...>/enable_ ####

#### _POST /api/system/networks/conn_tests_ ####

while test is running the request returns:
{"results":null,"timestamp":"0001-01-01T00:00:00Z"}

when test is complete it returns:
```
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
```

Also need to research:
#### _/api/system/networks/ping_test_ ####

POST /api/logging
{
	level: ???,
	log: ???
}

#### _POST /api/customer/registration/emailed_ ####

_vls29 - I couldn't find this endpoint in the javascript file and it returns 404_

#### _POST /api/customer/registration/legal_ ####
"Content-Type": "application/json"
response:
```
{
	marketing: ???,
	privacy_notice: ???,
	limited_warranty: ???,
	grid_services: ???
}
```

#### _GET /api/networks_ ####
returns all configured network adapters in gateway which seems running Linux:

can0 - very interesting unknown adapter (CAN-bus for the car??)
eth0 - ethernet
rpine0 - seems cellular network adapter (3G)
wifi0 - wireless adapter to connect to home network
wifi1 - configured as access point (TEG-XXXX)

```
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
```

#### _GET /api/system/networks_ ####

_vls29 - I couldn't find this endpoint in the javascript file and it returns 404_

```
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
```

#### _GET /api/networks/wifi_security_types_ ####

_vls29 - I couldn't find this endpoint in the javascript file and it returns 404_

["NONE","WEP","WPAorWPA2_Personal"]

#### _POST /api/meters/ABC1234567890/verify_ ####

"Content-Type": "application/json"
request's body: {"short_id":"12345","serial":" ABC1234567890 "}

#### _GET /api/meters/readings_ ####

```
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
```

---
#### _GET /api/system/testing_

```
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
```
