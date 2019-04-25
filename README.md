# snips-resources-safe
SAFE system extra resources and configuration snippets

# Linphone

The softphone used in the SAFE system base and satellite (pendant) is the open source [Linphone](https://www.linphone.org/technical-corner/linphone). We only require the console daemon `linphonec` and the management application `linphonecsh`. 

## Compilation

The linphone compilation are follows the [developer guidelines](https://wiki.linphone.org/xwiki/wiki/public/view/Linphone/Linphone%20and%20Raspberry%20Pi/) with some small changes in the preparation step.

Raspberry Pi 3B+ preparation:

```bash
./prepare.py no-ui -DENABLE_OPENH264=ON -DENABLE_WEBRTC_AEC=OFF -DENABLE_UNIT_TESTS=OFF -DENABLE_MKV=OFF -DENABLE_FFMPEG=ON -DENABLE_CXX_WRAPPER=OFF -DENABLE_NON_FREE_CODECS=ON -DENABLE_VCARD=OFF -DENABLE_BV16=OFF -DENABLE_V4L=OFF -DENABLE_RELATIVE_PREFIX=YES
```

Raspberry Pi Zero preparation:

```bash
./prepare.py no-ui -DENABLE_OPENH264=ON -DENABLE_WEBRTC_AEC=OFF -DENABLE_UNIT_TESTS=OFF -DENABLE_MKV=OFF -DENABLE_FFMPEG=ON -DENABLE_CXX_WRAPPER=OFF -DENABLE_NON_FREE_CODECS=ON -DENABLE_VCARD=OFF -DENABLE_BV16=OFF -DENABLE_V4L=OFF -DENABLE_RELATIVE_PREFIX=YES -DENABLE_VPX=OFF
```

> ***It is strongly recommended to setup a USB swap memory and plug a power adaptor capable of sourcing 2A***
> ***In this repository you can find a compiled version for both platforms and Raspbian version 4.14.98.***

## Softphone system wide setup

If the software is not compiled but reused from the packages in this repository, there are some requirements:
```bash
sudo apt-get install -y libasound2-dev libpulse-dev libv4l-dev libglew-dev 

Additionally, the SOX tool is required for Snips SAFE Base and Satellite call scripts.

```bash
sudo apt-get install -y sox
```

With the compiled binaries and libraries, they will be system wide available this way:

```bash
cd linphone-desktop/OUTPUT/no-ui 
sudo cp -R bin/* /usr/local/bin
sudo cp -R lib/* /usr/local/lib
sudo cp -R share/* /usr/local/share
sudo ldconfig
```

## Plugins setup

The media streamer plugins library is searched at the `SAFE_software_execution_path/lib/mediastreamer`.
So we have to copy the library to the proper path depending on the SAFE software execution path and the execution user.

SAFE base (`_snips-skills` user):
```
mkdir -p /var/lib/snips/skills/snips-app-safe/lib/mediastreamer && cp -R lib/mediastreamer/plugins /var/lib/snips/skills/snips-app-safe/lib/mediastreamer
mkdir -p /var/lib/snips/skills/snips-app-safe/.local/share/linphone/ && chmod 777 /var/lib/snips/skills/snips-app-safe/.local/share/linphone/
```

SAFE satellite (root user, as a service):

```bash
mkdir -p /var/lib/snips/snips-satellite-safe/lib/mediastreamer && cp -R lib/mediastreamer/plugins /var/lib/snips/snips-satellite-safe/lib/mediastreamer
```

## SAFE base user setup

The softphone will start and stop with every call, because there  is no need of having a permanent service as no calls are receive. To ease the clean up, the `_snip_skills` user will be granted some `sudo` permissions:

```bash
sudo vi /etc/sudoers.d/010_snips-systemctl
		_snips-skills ALL=(ALL) NOPASSWD: /usr/bin/pkill linphonec
```

## Softphone configuration

There are example `linphonerc.ini` template files in the SAFE base and SAFE pendant that should be fulfilled with the user account details.

SAFE base:
`/var/lib/snips/skills/snips-app-safe/linphonerc.ini`

SAFE pendant:
`/var/lib/snips/snips-satellite-safe/linphonerc.ini`

```bash
[sound]
echocancellation=1

[video]
enabled=0
size=vga

[sip]
sip_port=5060
guess_hostname=0
use_ipv6=0

[auth_info_0]
username=USERNAME
passwd=SECRET
realm=SERVER.xxx

# If there is no proxy, delete this section
# Send or not registration to proxy, depends on the server
[proxy_0]
reg_proxy=sip:PROXYHOST:PROXYPORT
reg_identity=sip:USERNAME@SERVER.xxx
reg_sendregister=1
guess_hostname=0

# If there is no stun server, delete this section
# Firewall policy depends on the server
[net]
stun_server=STUNSERVER.xxx
firewall_policy=3
```

It is a tricky procedure and there is not real detailed documentation on the rc configuration files, but some commented sample configuration files can be found in the web and specifically at [Belledonne github repository](https://github.com/BelledonneCommunications/linphone/tree/master/tester/rcfiles).

# Making test calls 

It is strongly recommended to test the softphone calls separately before using the SAFE system, to ensure that the configuration is rigth.

The `linphone_call.sh` script is the tool to use, and can be found in both base and satellite devices.

```
linphone_call.sh 
usage: ./linphone_call.sh [-v(erbose)] [-m <sos_message_wav>] [-t <end_timeout_s> def: 900] [-p <playback_soundcard_name>] [-c <capture_soundcard_name>] <conf_file> <contact_number>
```

SAFE base:
`cd /var/lib/snips/skills/snips-app-safe`

SAFE pendant:
`cd /var/lib/snips/snips-satellite-safe`

To test a regular call execute `linphone_call.sh -v linphonerc.ini +34655555555` and wait for the call to connect and give a typical output:

```bash
linphone_call.sh -v linphonerc.ini +34655555555
 ... reading configuration
 ... starting daemon
 ... setup sound
Using capture device #1 (PulseAudio: seeed-2mic-voicecard Analog Stereo)
Using playback sound device ALSA: seeed-2mic-voicecard
Using ring sound device ALSA: seeed-2mic-voicecard
 ... proxy registration
     registered_proxy: yes
     registered_proxy: yes
     registered_proxy: yes
 ... calling to +34655555555
Establishing call id to sip:+34655555555@telefonica.net, assigned id 1
Call 1 to sip:+34655555555@telefonica.net in progress.
     1 | sip:+34655555555@telefonica.net | OutgoingProgress |
     1 | sip:+34655555555@telefonica.net | OutgoingProgress |
     1 | sip:+34655555555@telefonica.net | OutgoingProgress |
     1 | sip:+34655555555@telefonica.net | OutgoingEarlyMedia |
     1 | sip:+34655555555@telefonica.net | OutgoingEarlyMedia |
     1 | sip:+34655555555@telefonica.net | StreamsRunning |
     1 | sip:+34655555555@telefonica.net | StreamsRunning |
     1 | sip:+34655555555@telefonica.net | StreamsRunning |
     1 | sip:+34655555555@telefonica.net | StreamsRunning |
     1 | sip:+34655555555@telefonica.net | StreamsRunning |
     1 | sip:+34655555555@telefonica.net | StreamsRunning |
     1 | sip:+34655555555@telefonica.net | StreamsRunning |
 ... unregister
 ... stop daemon
```

### root user at the pendant

The SAFE pendant software is executed as `root` user in a service, so it is recommendable to test with it:
```
sudo ./linphone_call.sh -v linphonerc.ini +34670619949
```

## Troubleshooting

If the softphone is not working properly, take a look at the log file `linphone_call.log` and also do some cleaning actions as those in the `linphone_reset.sh` script, besides to `linphone_call.sh` one.
