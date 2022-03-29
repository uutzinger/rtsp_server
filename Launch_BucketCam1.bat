cd %HOMEDRIVE%%HOMEPATH%
cd Desktop
gst-launch-1.0^
 rtspsrc location=rtsp://10.41.83.12:8554/test buffer-mode=synced protocols=tcp+udp+udp-mcast !^
 queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 min-threshold-time=0 !^
 decodebin ! videoconvert ! videoflip method=rotate-180 !^
 rsvgoverlay location=Bucket1.svg width-relative=1 height-relative=1 x-relative=0 y-relative=0 !^
 autovideosink sync=false
