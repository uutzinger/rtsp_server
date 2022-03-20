cd %HOMEDRIVE%%HOMEPATH%
cd Desktop
gst-launch-1.0 rtspsrc location=rtsp://10.41.83.11:8554/test latency=10 ! decodebin ! videoconvert ! videoflip method=rotate-180 ! rsvgoverlay location=Bucket0.svg width-relative=1 height-relative=1 x-relative=0 y-relative=0  ! autovideosink
