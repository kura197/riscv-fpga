
veri_file = testbench.v\
			cpu.v\
			datapath.v\
			controller.v\
			alu.v\
			flopr.v\
			flopenr.v\
			mux.v\
			regfile.v\
			csrfile.v\
			extend.v\
			type_decoder.v\
			cont_decoder.v\
			mmu.v\
			edge_to_pulse.v\
			port.v\
			div_bb.v\
			mul_bb.v\
			PS2.v

result:$(veri_file) 
	iverilog $(veri_file) -o result

clean:
	rm result
