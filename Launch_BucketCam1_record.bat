cd %HOMEDRIVE%%HOMEPATH%
cd Desktop
gst-launch-1.0^
 rtspsrc location=rtsp://10.41.83.12:8554/test latency=0 drop-on-latency=1!^
 tee name=RECORD !^
 decodebin ! videoconvert !^
 rsvgoverlay location=Bucket1.svg width-relative=1 height-relative=1 x-relative=0 y-relative=0 !^
 autovideosink^
 RECORD. ! queue ! rtph264depay ! h264parse ! mp4mux ! filesink location=camera1.mp4
