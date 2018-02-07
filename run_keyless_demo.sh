
clear 

sudo rm /tmp/keyless_mag_fifo
mkfifo /tmp/keyless_mag_fifo

sudo python keyless_live.py
