# Run the RTL-SDR test file with required parameters to quickly test if 
# the device is communicating properly. 
#
# This will spit out a whole bunch of characters to the terminal if working.
# If not, it will throw an error.
# Script automatically terminates after 2 seconds.

timeout 2 rtl_fm -f 96.9e6
clear
