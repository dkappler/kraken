**kraken** is an open source garmin app for the forerunner 235. It was
created to show and store more detailed 24x7 heart rate data. The main
idea is to query the sensor only ones every so and so many seconds
(user choice)and visualize the last ~90 minutes of heart rate data
always on screen.

To be battery efficient the screen is only updated every minute.
The sensor is queried always for 15 seconds every minute e.g.
1.22 - 1.43 or 10.22-10.43. The heart rate which is visualized
is the mean heart rate obtained from this measurement period.

IMPORTANT: The sensor is queried every second right now, due to 
a bug in the Garmin SDK. Therefore, the battery lifetime is 
a little bit more than a DAY. As soon as this is fixed,
the battery lifetime should increase significantly.

## Todos
Right now all parameters are hard coded and not accessible by 
the watch keys. This has to be changed.

The current SDK supports turning of the sensor, but according to
forum.garmin.com there is a bug in the implementation which is why the
sensor is taking measurements every second and cannot be turned off
ones activated.
As soon as Garmin will fix this issue the battery lifetime should 
significantly increase when using this app.

## Donation
If you like this app donations are always welcome.

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=PF85KTH8UJEH2)

