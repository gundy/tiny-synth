# generate a table of F values for the state variable filter
# MIDI controllers produce values from 00..7f, and this gets mapped
# to a logarithmic range from Fmin to Fmax

import math

# sample rate
Fs = 250000

# min F
Fmin = 30

# max F
Fmax = 16000

# number of entries in table
Ts = 128.0



def svf_f(fs, fc):
    return 2*3.14159265359*(fc/fs)


Frange = Fmax/Fmin;

table = range(int(Ts))
table = [ int(svf_f(Fs, (math.pow(Frange, (i/128.0))*Fmin) )*131072.0) for i in table ]

for i in table:
    print( format(i,'05x') )
