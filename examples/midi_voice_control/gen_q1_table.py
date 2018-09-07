# generate a table of Q1 values for the state variable filter
# MIDI controllers produce values from 00..7f, and this gets mapped
# linearly to a Q range from Qmin .. Qmax

Qmin = 0.5
Qmax = 8.0
Ts = 128.0

table = range(int(Ts))

table = [ int((1.0/(Qmin + ((Qmax - Qmin) * (i/Ts)))) * 65536) for i in table ]

for i in table:
    print( format(i,'05x') )
