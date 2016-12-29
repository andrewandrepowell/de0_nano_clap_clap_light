`timescale 1ns / 1ps

module testbench;
	 
	function integer clogb2 ( input integer bit_depth );                                   
		begin                                                                              
			for( clogb2=0; bit_depth>0; clogb2=clogb2+1 )                                      
				bit_depth = bit_depth >> 1;                                                    
		end                                                                                
	endfunction 
	
	localparam integer CLOCK_PERIOD=10;
	localparam integer SAMPLE_WIDTH=16;
	reg clock_sig=0;
	reg nreset_sig=0;
	wire spi_clock_sig;
	wire spi_chipselect_sig;
	reg spi_data_sig=0;
	
	localparam integer IN_SAMPLE_TOTAL=120;
	integer in;
	integer out;
	reg [SAMPLE_WIDTH-1:0] in_samples [0:IN_SAMPLE_TOTAL-1];
	reg [SAMPLE_WIDTH-1:0] in_noise [0:IN_SAMPLE_TOTAL-1];
    
	task wait_clock_cycles( input integer amount );
		automatic integer each_edge;
		begin
			for ( each_edge=0; each_edge<amount; each_edge=each_edge+1 )
				@ ( posedge clock_sig );
		end
	endtask
    
	task drive_spi( input [ SAMPLE_WIDTH-1:0 ] sample );
		automatic integer each_bit;
		begin
			@( negedge spi_chipselect_sig );
			for ( each_bit=0; each_bit<SAMPLE_WIDTH; each_bit=each_bit+1 )
				begin
					@( negedge spi_clock_sig );
					spi_data_sig = sample[ SAMPLE_WIDTH-1-each_bit ];
				end
		end
	endtask
 
	// DUT 
	top2 top2_inst (
	.clock(clock_sig) ,	
	.nreset(nreset_sig),	
	.spi_clock(spi_clock_sig),	
	.spi_chipselect(spi_chipselect_sig),
	.spi_data(spi_data_sig),	
	.toglite_state(toglite_state_sig));
	assign top2_inst.claps_ready_sig = 1;
        
    // Drive clock
    always 
        begin
            clock_sig = !clock_sig;
            #(CLOCK_PERIOD/2);
        end
    
	// Testbench execution.
	initial
		begin: process_load_samples
			// Declarations.
			integer each_word;
			// Load data into input sample buffer.
			$display("Loading input data...");
			in  = $fopen("../../../eclipse/generate_sims/nclap_3_ntrial_1.txt","r");
			wait_clock_cycles(1);
			each_word = 0;
			while (!$feof(in)) 
				begin
					$fscanf(in,"%h\n",in_samples[each_word]);
					each_word = each_word+1;
				end
			$fclose(in);
			// Reset SPI interface.
			nreset_sig = 0;
			// Drive SPI interface.
			wait_clock_cycles(1);
			nreset_sig = 1;
			for ( each_word=0; each_word<IN_SAMPLE_TOTAL; each_word=each_word+1 )
				begin
					drive_spi(in_samples[each_word]);
				end
			// Loading noise.
			$display("Loading input noise...");
			in  = $fopen("../../../eclipse/generate_sims/nclap_0_ntrial_1.txt","r");
			wait_clock_cycles(1);
			each_word = 0;
			while (!$feof(in)) 
				begin
					$fscanf(in,"%h\n",in_noise[each_word]);
					each_word = each_word+1;
				end
			$fclose(in);
			// Drive SPI interface.
			wait_clock_cycles(1);
			for ( each_word=0; each_word<IN_SAMPLE_TOTAL; each_word=each_word+1 )
				begin
					drive_spi(in_noise[each_word]);
				end
			$finish;
		end
    
    
endmodule
