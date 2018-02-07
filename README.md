A simple receiver for keyless entry remotes demonstrating the use of MATLAB + GNU Radio for decoding signals. 
Tested with a key that transmits OOK at 315MHz, yours may use a different frequency or packet format.

### Dependencies
* GNU Radio 3.7.10 or later
* Modern-ish version of Matlab. No toolboxes should be required. 
* gr-osmosdr, if you use the build-gnuradio script, this will be installed by default

### Running
From the terminal "sudo sh run_keyless_demo.sh"
From MATLAB run keyless_demo_live.m
When done, kill the MATLAB script first, then the terminal process.



