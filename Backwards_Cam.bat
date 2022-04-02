cd %HOMEDRIVE%%HOMEPATH%
cd Desktop
gst-launch-1.0^
 rtspsrc location=rtsp://raspberry:8554/test buffer-mode=synced protocols=tcp+udp+udp-mcast !^
 queue max-size-buffers=0 max-size-time=0 max-size-bytes=0 min-threshold-time=0 !^
 decodebin ! videoconvert ! videoflip method=rotate-180 !^
 autovideosink sync=false^
