# Create Simple RTSP Server on Raspberry Pi or Similar Computer

The RTSP streamer is an H264 video server with gstreamer.
This will work for raspberry pi or jetson nano and likely any unix system.
The client is usally a windows computer, but you can also watch on your phone using tinyCam.

The latency of this setup using raspberry pi v1 camera and 640x480 resolution and 30fps over wifi is 200ms.

- [Create Simple RTSP Server on Raspberry Pi or Similar Computer](#create-simple-rtsp-server-on-raspberry-pi-or-similar-computer)
- [Receiver / Client](#receiver---client)
  * [Prerequisits on Client](#prerequisits-on-client)
    + [Add gstreamer to Windows Path](#add-gstreamer-to-windows-path)
  * [Network](#network)
  * [Script to run the Viewer](#script-to-run-the-viewer)
  * [Overlay](#overlay)
    + [Test the SVG Graphic Object](#test-the-svg-graphic-object)
    + [Test with RTSP](#test-with-rtsp)
  * [Modify the Server Settings](#modify-the-server-settings)
- [Build the RTSP Server](#build-the-rtsp-server)
  * [Server Dependencies](#server-dependencies)
  * [Create RTSP Server](#create-rtsp-server)
  * [Build and Install Gstreamer RTSP Server](#build-and-install-gstreamer-rtsp-server)
  * [Test the Streams](#test-the-streams)
  * [Create Shell Script to Simplify Start of Server](#create-shell-script-to-simplify-start-of-server)
  * [Run the Script at Boot](#run-the-script-at-boot)
  * [Make the Device Wired and Compliant](#make-the-device-wired-and-compliant)
- [Build from source 1.18.4](#build-from-source-1184)
  * [Remove the old version of gstreamer](#remove-the-old-version-of-gstreamer)
  * [Download and unpack gstreamer](#download-and-unpack-gstreamer)
  * [Download and unpack base plugins](#download-and-unpack-base-plugins)
  * [Download and unpack good plugins](#download-and-unpack-good-plugins)
  * [Download and unpack bad plugins](#download-and-unpack-bad-plugins)
  * [Download and unpack ugly plugins](#download-and-unpack-ugly-plugins)
  * [download and unpack omxh264enc plugins](#download-and-unpack-omxh264enc-plugins)
  * [Download and unpack rtsp server](#download-and-unpack-rtsp-server)
  * [gst python](#gst-python)
  * [Test the streams](#test-the-streams)
  * [Receiver](#receiver)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


# Receiver / Client

## Prerequisits on Client
- gstreamer from https://gstreamer.freedesktop.org/download/ using 64bit runtime installer for MSVC   
- bonjour https://support.apple.com/downloads/DL999/en_US/BonjourPSSetup.exe to get mDNS working.  
- VC redistributable https://aka.ms/vs/17/release/vc_redist.x64.exe   

### Add gstreamer to Windows Path
Open Power Shell.  
Backup current path:
```
$Env:PATH > path_backup.txt    
```
Do not repeat the above if gstreamer does not work otherwise you will loose your backup.

Start powershell as Administrator:
```
Start-Process powershell -Verb runAs  
```
In the new Window add gstreamer path to current system path:
```
setx /M PATH "$ENV:PATH;C:\gstreamer\1.0\msvc_x86_64\bin"
```
If anything went wrong, you can revert to your backed up plan by entering the text in the backup file into the setx command line between then quotation marks.

## Network
Plug the server into your network. 

If you connect the server directly to your client with a wired cable, the address is ```hostname.local```. 

If both obtain IP through DHCP then the address is just hostname. 

If you use static IP on the server and client then your hostname will be something like 10.TE.AM.11.

```
10.TE.AM.6 your computer
255.255.255.0 netmask
10.TE.AM.1 as gateway
```

The host name was set on your server computer (see below) and is announced using mDNS.

## Script to run the Viewer
Create a file such as ```LaunchViewer.bat``` on your client computer, with content such as:

```
cd %HOMEDRIVE%%HOMEPATH%
cd Desktop
gst-launch-1.0 rtspsrc location=rtsp://10.41.83.11:8554/test latency=10 buffer-mode=auto drop-on-latency=1 ! decodebin ! videoconvert ! videoflip method=rotate-180 ! rsvgoverlay location=Bucket0.svg width-relative=1 height-relative=1 x-relative=0 y-relative=0  ! autovideosink
```
The above assumes your have the script on your desktop and the overlay file is located there also. You will need to adjust the path if you place it elsewhere. You can remove the overlay if you dont need it. You cna also remove the videoflip or change the rotation. Google gstreamer videoflip for the options.

Alternativel you can use VLC https://www.videolan.org/
```
vlc rtsp://hostname.local:8554/test
```
On VLC make sure you set buffering to very small number (advanced options) otherwise your latency is going to be in the seconds.

## Overlay
Create SVG graphics for example in Inkscape. You can use colored lines and text. gstreamer has module to overlay static SVG graphics onto your video feed. Inkscape saves its graphics by default as svg file.

### Test the SVG Graphic Object
Test your script without RTSP, just with test video feed:
```
# Cross Hair in the center
gst-launch-1.0 videotestsrc ! rsvgoverlay location=CrossHair.svg width-relative=0.1 height-relative=0.133 x-relative=0.45 y-relative=0.433 ! videoflip method=clockwise ! autovideosink

# Grid Overlay
gst-launch-1.0 videotestsrc ! rsvgoverlay location=Bucket.svg width-relative=1 height-relative=1 x-relative=0 y-relative=0 ! videoflip method=clockwise ! autovideosink
```

### Test with RTSP
```
gst-launch-1.0 rtspsrc location=rtsp://hostname.local:8554/test latency=10 ! decodebin ! videoconvert ! rsvgoverlay location=CrossHair.svg width-relative=0.1 height-relative=0.133 x-relative=0.45 y-relative=0.433 ! autovideosink
```

## Modify the Server Settings
On the server there is a script executed at boot time to start RTSP server.

You can SSH to the server: ```ssh pi@10.TE.AM.11``` and edit the file using ```nano run_server.sh```. Password is the usual.

The script contains the following:
```
#! /bin/bash
cd /home/pi
./test-launch "( v4l2src device=/dev/video0 ! video/x-h264, width=1280, height=720, framerate=15/1 ! h264parse config-interval=1 ! rtph264pay name=pay0 pt=96 )" &
v4l2-ctl -c white_balance_auto_preset=10
v4l2-ctl -c auto_exposure=0
# v4l2-ctl -c exposure_time_absolute=10000
v4l2-ctl -c video_bitrate=500000
v4l2-ctl -c video_bitrate_mode=0
```

You can access any video camera in the ```/dev/``` folder. 
You can set the resolution of the camera (check online what resolutions are supported, usually 1080p, 720p, 640x480, 320x240).   
You can set the frame rate. It will need to be experessed as ratio e.g. 15/1   
You can use ```v4l2-ctl``` to change the camera properties.   
```v4l2-ctl -l``` lists all properties you can change. It will take default /dev/video0 camera. But you can choose the device.  
Recommended is autoexposure, to enable auto exposure you need set it 0 (not 1)  
Recommended is auto white balancing. This is not recommended for vision processing but is ideal for stream viewing.  
You will want to limit the amount of data sent over the network. The bitrate is bits per second.  
The bitrate mode is either constant bitrate or variable bitrate.  

# Build the RTSP Server
The RTSP server for gstreamer is not available on windows. Therefore the server will need to run on UNIX based OS. The RTSP server is not distributed as binary. So you will need to first install gstreamer, and the gstreamer development components and then build the RTSP server.

These programs might be helpful to explore camera properties and gstreamer options:  
https://github.com/jetsonhacks/camera-caps   
https://github.com/jetsonhacks/gst-explorer   

## Server Dependencies

Not all dependencies below are needed for gstreamer but they are needed if you plan to use opencv. This is my basic vision processing setup.
```
sudo apt-get -y install libjpeg-dev libtiff-dev libtiff5-dev libjasper-dev libpng-dev
sudo apt-get -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libavresample-dev
sudo apt-get -y install libxvidcore-dev libx264-dev
sudo apt-get -y install libtbb2 libtbb-dev libdc1394-22-dev libv4l-dev
sudo apt-get -y install libjasper-dev libhdf5-dev
sudo apt-get -y install libopenblas-dev liblapack-dev libatlas-base-dev libblas-dev libeigen{2,3}-dev
sudo apt-get -y install python3-numpy python3-dev python3-pip python3-mock
sudo apt-get -y install cmake gfortran
sudo apt-get -y install protobuf-compiler
sudo apt-get -y install libgtk2.0-dev libcanberra-gtk* libgtk-3-dev 
sudo apt-get -y install python3-pyqt5
sudo pip3 install opencv-contrib-python==4.1.0.25
```

## Create RTSP Server

Either install pre built or build your own RTSP server (not recommended) 

Check current verison of gstreamer with:
```
dpkg -l | grep gstream*
```
2/14/2022 this version is 1.14.4

```
# install base and plugins
sudo apt-get install -y libgstreamer1.0-dev \
     libgstreamer-plugins-base1.0-dev \
     libgstreamer-plugins-bad1.0-dev \
     gstreamer1.0-plugins-ugly \
     gstreamer1.0-tools
# install some optional plugins
sudo apt-get install -y gstreamer1.0-gl gstreamer1.0-gtk3
# if you have Qt5, install this plugin
sudo apt-get install -y gstreamer1.0-qt5
# install if you want to work with audio
sudo apt-get install -y gstreamer1.0-pulseaudio
# perhaps useful also
sudo apt-get install -y gstreamer1.0-python3-plugin-loader
sudo apt-get install -y gstreamer1.0-rtsp
```

## Build and Install Gstreamer RTSP Server

You will need to build RTSP server regradless whether you built gstreamer or installed it with package manager.

```
sudo apt-get -y install gobject-introspection
sudo apt-get -y install libgirepository1.0-dev
sudo apt-get -y install gir1.2-gst-rtsp-server-1.0

# Download rtsp server version 1.14.4 or the one that matches your current isntallation.
wget https://gstreamer.freedesktop.org/src/gst-rtsp-server/gst-rtsp-server-1.14.4.tar.xz
tar -xf gst-rtsp-server-1.14.4.tar.xz
cd gst-rtsp-server-1.14.4
./configure --enable-introspection=yes
make
sudo make install
sudo ldconfig
```

The RTSP server is in the example folder and is called ```test-launch```. It accessess local libraries in ```.libs```. If you copy test-launch you will also need to copy the hidden .libs folder.

## Test the Streams

Before working with camera you will want to create a test stream such as:

```
# smaller number less output
export GST_DEBUG="*:5"
cd ~/gst-rtsp-server-1.14.4/build/examples
# run the test pipeline
./test-launch "( videotestsrc ! x264enc ! rtph264pay name=pay0 pt=96 )"
```

Watch with receiver as shown above on Windows or on same computer.

## Create Shell Script to Simplify Start of Server

You will want to start the server with a simple script:

```
#! /bin/bash
cd /home/pi
./test-launch "( v4l2src device=/dev/video0 ! video/x-h264, width=1280, height=720, framerate=15/1 ! h264parse config-interval=1 ! rtph264pay name=pay0 pt=96 )" &
v4l2-ctl -c white_balance_auto_preset=10
v4l2-ctl -c auto_exposure=0
# v4l2-ctl -c exposure_time_absolute=10000
v4l2-ctl -c video_bitrate=500000
v4l2-ctl -c video_bitrate_mode=0
```

```v4l2-ctl -l``` lists camera options. You will need to program the following
- video bitrate
- autoexposure or set exposure time, often auto_exposure ON means setting it to 0
- white balancing
- bitrate mode, you will want either constant bit rate or varibale bit rate
- if you have more than one camera you can change the camera device=/dev/video1 etc.

This will not work on latest bullseye raspian. There the camera will need to be opened using libcam. ```libcamerasrc ! video/x-h254, width=1280, height=720, framerate=15/1``` might work.

On jetson nano your script might need to look like:
```
./test-launch "v4l2src device=/dev/video0 ! nvvidconv ! nvv4l2h264enc insert-sps-pps=1 insert-vui=1 ! h264parse ! rtph264pay name=pay0"
```

## Run the Script at Boot
To run the above script each time the server boots you edit
```
sudo nano /etc/rc.local
```
and add the following line before exit 0
```
/home/pi/run_streamer.sh >> /home/pi/run_streamer.log 2>&1
```

## Make the Device Wired and Compliant
For some usage scenarios you will need to turn off wireless and bluetooth. 
```
sudo nano /boot/config.txt
```
Find other locations where dtoverlays are set add these two lines under it:
```
dtoverlay=disable-wifi
dtoverlay=disable-bt
```

You will want to set the hostname
```
sudo raspi-config
```
Then set hostname under system

Set static IP (this will require that your client is set also to static IP, advantage is that neither DNS nor mDNS needs to work):
```
sudo nano /etc/dhcpcd.conf
# use
# 10.TE.AM.11/24 
# /24 is netmask 255.255.255.0
# static routers = 10.41.83.1
# static domain_name_server = 10.41.83.1
```

# Build from source 1.18.4
Not recommended   
Source: https://qengineering.eu/install-gstreamer-1.18-on-raspberry-pi-4.html   
Continue with steps outlined at the end or the QEngineering Website.  

## Remove the old version of gstreamer
```
sudo apt-get remove gstreamer1.0
sudo apt-get remove gstreamer-1.0

sudo rm -rf /usr/bin/gst-*
sudo rm -rf /usr/include/gstreamer-1.0

# install a few dependencies
sudo apt-get install -y cmake meson flex bison pkg-config
sudo apt-get install -y python3-dev
sudo apt-get install -y libglib2.0-dev libjpeg-dev libx264-dev
sudo apt-get install -y libgtk2.0-dev libcanberra-gtk* libgtk-3-dev
sudo apt-get install -y libasound2-dev
sudo apt-get install -y glib-2.0 
sudo apt-get install -y libcairo2-dev
sudo apt-get install -y gir1.2-gst-plugins-base-1.0
sudo apt-get install -y python-gi-dev
#sudo apt-get install -y libgirepository1.0-dev
```

## Download and unpack gstreamer
```
wget https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-1.18.4.tar.xz
sudo tar -xf gstreamer-1.18.4.tar.xz
cd gstreamer-1.18.4
# make an installation folder
mkdir build && cd build
# run meson (a kind of cmake)
meson --prefix=/usr \
        --wrap-mode=nofallback \
        -D buildtype=release \
        -D gst_debug=true \
        -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
        -D package-name="GStreamer 1.18.4 BLFS" ..
# build the software
ninja -j4
# test the software (optional)
ninja test
# install the libraries
sudo ninja install
sudo ldconfig
```

## Download and unpack base plugins
```
cd ~
wget https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-1.18.4.tar.xz
sudo tar -xf gst-plugins-base-1.18.4.tar.xz
# make an installation folder
cd gst-plugins-base-1.18.4
mkdir build
cd build
# run meson
meson --prefix=/usr \
-D buildtype=release \
-D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ ..
ninja -j4
# optional
# ninja test
# install the libraries
sudo ninja install
sudo ldconfig
```

## Download and unpack good plugins
```
cd ~
sudo apt-get install -y libjpeg-dev
# download and unpack the plug-ins good
wget https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-1.18.4.tar.xz
sudo tar -xf gst-plugins-good-1.18.4.tar.xz
cd gst-plugins-good-1.18.4
# make an installation folder
mkdir build && cd build
# run meson
meson --prefix=/usr       \
       -D buildtype=release \
       -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
       -D package-name="GStreamer 1.18.4 BLFS" ..
ninja -j4
# optional
ninja test
# install the libraries
sudo ninja install
sudo ldconfig
```

## Download and unpack bad plugins

```
cd ~
# dependencies for RTMP streaming (YouTube)
sudo apt install -y librtmp-dev
sudo apt-get install -y libvo-aacenc-dev
# download and unpack the plug-ins bad
wget https://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-1.18.4.tar.xz
sudo tar -xf gst-plugins-bad-1.18.4.tar.xz
cd gst-plugins-bad-1.18.4
# make an installation folder
mkdir build && cd build
# run meson
meson --prefix=/usr       \
       -D buildtype=release \
       -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
       -D package-name="GStreamer 1.18.4 BLFS" ..
ninja -j4
# optional
# ninja test
# install the libraries
sudo ninja install
sudo ldconfig
```

## Download and unpack ugly plugins
```
cd ~
# download and unpack the plug-ins ugly
wget https://gstreamer.freedesktop.org/src/gst-plugins-ugly/gst-plugins-ugly-1.18.4.tar.xz
sudo tar -xf gst-plugins-ugly-1.18.4.tar.xz
cd gst-plugins-ugly-1.18.4
# make an installation folder
mkdir build && cd build
# run meson
meson --prefix=/usr       \
      -D buildtype=release \
      -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
      -D package-name="GStreamer 1.18.4 BLFS" ..
ninja -j4
# optional
ninja test
# install the libraries
sudo ninja install
sudo ldconfig

# test if the module exists (for instance x264enc)
gst-inspect-1.0 x264enc
# if not, make sure you have the libraries installed
# stackoverflow is your friend here
sudo apt-get install libx264-dev
# check which the GStreamer site which plugin holds the module
```

## download and unpack omxh264enc plugins
```
cd ~
# Download and unpack the plug-in gst-omx
wget https://gstreamer.freedesktop.org/src/gst-omx/gst-omx-1.18.4.tar.xz
sudo tar -xf gst-omx-1.18.4.tar.xz
cd gst-omx-1.18.4
# make an installation folder
mkdir build && cd build
# run meson
meson --prefix=/usr       \
       -D header_path=/opt/vc/include/IL \
       -D target=rpi \
       -D buildtype=release ..
ninja -j4
# optional
ninja test
# install the libraries
sudo ninja install
sudo ldconfig
```

## Download and unpack rtsp server
```
cd ~
wget https://gstreamer.freedesktop.org/src/gst-rtsp-server/gst-rtsp-server-1.18.4.tar.xz
tar -xf gst-rtsp-server-1.18.4.tar.xz
cd gst-rtsp-server-1.18.4
# make an installation folder
mkdir build && cd build
# run meson
meson --prefix=/usr       \
       --wrap-mode=nofallback \
       -D buildtype=release \
       -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
       -D package-name="GStreamer 1.18.4 BLFS" ..
ninja -j4
# install the libraries
sudo ninja install
sudo ldconfig
```

sudo apt install gir1.2-gst-rtsp-server-1.0

## gst python
```

cd ~
wget https://gstreamer.freedesktop.org/src/gst-python/gst-python-1.18.4.tar.xz
tar -xf gst-python-1.18.4.tar.xz
cd gst-python-1.18.4
# make an installation folder
mkdir build && cd build
# run meson
meson --prefix=/usr       \
      -D buildtype=release \
      -D package-origin=https://gstreamer.freedesktop.org/src/gstreamer/ \
      -D package-name="GStreamer 1.18.4 BLFS" ..
ninja -j4
# install the libraries
sudo ninja install
sudo ldconfig
```

## Test the streams
```
cd ~/gst-rtsp-server-1.18.4/build/examples
# run the test pipeline
./test-launch "( videotestsrc ! x264enc ! rtph264pay name=pay0 pt=96 )"

# run camera pipeline
./test-launch "v4l2src device=/dev/video0 ! video/x-h264, width=640, height=480, framerate=30/1 ! h264parse config-interval=1 ! rtph264pay name=pay0 pt=96"
```

./test-launch "v4l2src device=/dev/video0 ! video/x-h264, width=640, height=480, framerate=30/1 ! h264parse config-interval=1 ! rtph264pay name=pay0 pt=96"

## Receiver
```
gst-launch-1.0 rtspsrc location=rtsp://192.168.178.32:8554/test/ latency=10 ! decodebin ! autovideosink
```

or

```
vlc rtsp://serverip:8554/test
```
