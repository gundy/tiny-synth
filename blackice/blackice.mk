chip.bin: $(VERILOG_FILES) ${PCF_FILE} 
	yosys -q -f "verilog -Dblackice" -p "synth_ice40 -blif chip.blif" $(VERILOG_FILES) 
	arachne-pnr -d 8k -P tq144:4k -p ${PCF_FILE} chip.blif -o chip.txt 
	icepack chip.txt chip.bin 

.PHONY: upload 
upload: chip.bin 
	stty -F /dev/ttyACM1 raw 
	cat chip.bin >/dev/ttyACM1 
 
.PHONY: clean 
clean: 
	$(RM) -f chip.blif chip.txt chip.bin 
