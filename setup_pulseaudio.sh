echo ""
echo 'WARNING: do not forget to do this before running this script:
$ sudo vi /etc/rc.local
	# Add before exit 0 to fix bus problems
	DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
	DBUS_SESSION_BUS_PID=`cat /run/dbus/pid`
'
read -p 'continue...' seguir
echo ""

sudo apt-get install pulseaudio
#sudo apt-get --purge --reinstall install pulseaudio

sudo sed -i "s/^.ifexists module-udev-detect.so\b/&.ignore/" /etc/pulse/default.pa
sudo sed -i "s/^load-module module-native-protocol-unix\b/& auth-anonymous=1 socket=\/tmp\/pulseaudio.socket/" /etc/pulse/default.pa
sudo sed -i "/^#load-module module-native-protocol-tcp$/ s|#||" /etc/pulse/default.pa
sudo sed -i "s/^load-module module-native-protocol-tcp\b/& auth-ip-acl=127.0.0.1/" /etc/pulse/default.pa
sudo sed -i "s/^load-module module-suspend-on-idle\b/& timeout=604800/" /etc/pulse/default.pa

echo "autospawn = no" | sudo tee -a /etc/pulse/client.conf
echo "default-server = unix:/tmp/pulseaudio.socket" | sudo tee -a /etc/pulse/client.conf

echo "exit-idle-time = -1" | sudo tee -a /etc/pulse/daemon.conf
echo "resample-method = ffmpeg" | sudo tee -a /etc/pulse/daemon.conf
echo "enable-remixing = yes" | sudo tee -a /etc/pulse/daemon.conf
echo "flat-volumes = no" | sudo tee -a /etc/pulse/daemon.conf
echo "default-sample-rate = 48000" | sudo tee -a /etc/pulse/daemon.conf

sudo adduser pulse audio
sudo adduser pi pulse-access
sudo adduser _snips pulse-access
sudo adduser root pulse-access

echo '
[Unit]
Description=PulseAudio Daemon
After=sound.target network.target
Requires=sound.target

[Install]
WantedBy=default.target

[Service]
Restart=always
Type=simple
PrivateTmp=false
ExecStart=/usr/bin/pulseaudio --system --realtime --disallow-exit --no-cpu-limit --log-target=syslog
ExecStop=/usr/bin/pulseaudio --kill
' > pulseaudio.service
sudo cp pulseaudio.service /etc/systemd/system/pulseaudio.service
sudo systemctl daemon-reload
sudo systemctl enable pulseaudio
sudo reboot

