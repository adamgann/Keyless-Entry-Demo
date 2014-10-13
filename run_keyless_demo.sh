
clear 

sudo rm data/keyless_mag_fifo
mkfifo data/keyless_mag_fifo

sudo python keyless_live.py
