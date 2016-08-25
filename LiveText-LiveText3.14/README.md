# LiveText Agent
Welcome to LiveText Agent!  This document will eventually include and/or link
to everything you wanted to know about being a LiveText Agent developer.  For
now, though, we'll focus on the recent (as of 2016-05-23) changes made to
migrate away from the existing LTA dev platform to our mainline HeyWire
Business (which covers LTA, and Business Messenger) backend.

*Why change things?*  
Great question!  There are a number of reasons, but the most important are that
the existing DEV environment was out of date AND that LiveText Agent will soon
need to interact with newer versions of the HeyWire platform.  Maintaining a
second, one-off developer platform didn't make sense, since that doesn't
automatically get newer versions of the platform as part of our nightly
build and maintenance process.

## LiveText Agent Development Back-End
The LiveText Agent developer back-end is now integrated with HeyWire Business
developer back end.

**Environment Topology**  
The HeyWire development environment is comprised of the following servers:
- **build.dev.heywire.com** &mdash; TeamCity build server
- **dev.mediafriendsinc.com** &mdash; Dev Web Server that hosts HeyWire web
applications (RestWeb, API, Notification Service, etc)
- **db.dev.heywire.com** &mdash; Dev database server that hosts provisioning,
messaging, and notifier databases for Dev web applications
- **mms.dev.heywire.com** &mdash; MMS server that hosts the native picture/
audio messaging functionality AND the Twilio gateway, used for long/short code
MMS.


**Migration Details**  
The following table highlights the differences between the previous LTA
developer platform and the new one.  *Note that there are new URLs for
the API and oAuth*

|                     |  Previous                 | New                        |
| ---                 | -------------------       | -------------              |
| Database Server     | perf3vm2                  | db.dev.heywire.com         |
| Provisioning DB     | dev_livetext_provisioning | dev_hwbiz_provisioning     |
| Notifier DB         | dev_livetext_provisioning | dev_hwbiz_provisioning     |
| Messaging DB        | dev_livetext_messaging_50Demo | dev_livetext_messaging |
| API URL             | livetext.dev.heywire.com/API  | dev.mediafriendsinc.com/hwbiz/api |
| Base oAuth URL      | livetext.dev.heywire.com  | oAuth.dev.heywire.com/LiveTextAgent    |

For example, if you were using the following URL for oAuth:<br />
https://livetext.dev.heywire.com/oauth_fr <br />you should now use<br />
https://oauth.dev.heywire.com/LiveTextAgent/oauth_fr <br />

  Similarly, the new URL to use to communicate with the HeyWire API is now: <br />
  https://dev.mediafriendsinc.com/hwbiz/api

Existing "fake" phone numbers and API tokens have been migrated to the new stack.  
Additionally, each stack has been configured with a pair of working, MMS-enabled
phone numbers as well.

| Name          | Org Id                | API Credentials (AccountId / AuthToken)                                     | Phone Numbers |
| -----         | ------                | ---------------                                                             | ------------- |
| LiveTextFRDev | 00Dj0000001rzYhEAI    | 03B3FA9A-F972-4316-BCCB-840E0D79D87F / D5B6AFA0-B9C0-4C16-90D8-A1440C5EBBB0 | 51515<br />525252<br />+18005555555<br />+18006666666<br />+16175555555<br />+16176666666<br />**+16788108909**<br />**+17206863664**|
| LiveTextPKDev | 00Dj0000001rNJqEAM    | CA759D83-84D0-40F3-ACF2-66F943003C62 / EA7D629F-8423-41C7-B76E-07EAC8975121 | 31313<br />323232<br />+18003333333<br />+18004444444<br />+16173333333<br />+16174444444<br />**+17206863673**<br />**+17206863711**|
| LiveTextRADev | 00Dj0000001ty1fEAA    | BE3E2F3F-C793-4686-83E0-F5A4071B8579 / 60BE0991-F4B7-4C07-8FAE-CB758754BD6B | 71717<br />727272<br />+18007777777<br />+16177777777<br />**+16788108926**<br />**+16788108846**|
| LiveTextPADev | 00D1a000000Y7vfEAC    | 9142A5A6-25B9-4EA4-935D-7F2CCADA33AF / 5B718459-70A2-4E91-8D3D-2218829D585A | 81818<br />828282<br />+18008888888<br />+18008888888<br />+16178888888<br />**+16128437111**<br />**+16128437208**|
