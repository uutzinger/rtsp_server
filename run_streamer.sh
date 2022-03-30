#! /bin/bash
cd /home/pi
./test-launch "( v4l2src device=/dev/video0 ! video/x-h264, width=640, height=480, framerate=30/1 ! h264parse config-interval=1 ! rtph264pay name=pay0 pt=96 )" &
v4l2-ctl -c white_balance_auto_preset=10
v4l2-ctl -c auto_exposure=0
# v4l2-ctl -c exposure_time_absolute=10000
v4l2-ctl -c video_bitrate=1000000
v4l2-ctl -c video_bitrate_mode=0