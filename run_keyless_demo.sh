# run_keyless_demo.sh
#
# Script to create the FIFO for piping data to Matlab
# and then run the GNU Radio script


clear 

if [ "$EUID" -ne 0 ]
	then echo "Please run as root. I need permissions to create a FIFO"
	exit
fi


rm /tmp/keyless_mag_fifo
mkfifo /tmp/keyless_mag_fifo

python keyless_live.py
