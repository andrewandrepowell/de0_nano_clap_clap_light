`timescale 1 ns / 1 ps

module DetermineClap #
	(
		parameter integer ENERGY_WIDTH=16,
		parameter integer ENERGY_HIGH_THRESHOLD=100,
		parameter integer ENERGY_LOW_THRESHOLD=50,
		parameter integer SAMPLE_HIGH_THRESHOLD=4,
		parameter integer SAMPLE_MIDDLE_THRESHOLD=10,
		parameter integer SAMPLE_LOW_THRESHOLD=200,
		parameter integer CLAPS_SAMPLE_THRESHOLD=200,
		parameter integer CLAPS_OUT_WIDTH=16 
	) (
		input wire clock,
		input wire nreset,
		input wire [ENERGY_WIDTH-1:0] energy_data,
		input wire energy_valid,
		output reg energy_ready=0,
		output reg [CLAPS_OUT_WIDTH-1:0] claps_out_data=0,
		output reg claps_out_valid=0,
		input wire claps_out_ready
	);
	
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	function integer clogb2 ( input integer bit_depth );                                   
	  begin                                                                              
			for( clogb2=0; bit_depth>0; clogb2=clogb2+1 )                                      
				 bit_depth = bit_depth >> 1;                                                    
	  end                                                                                
	endfunction  
	
	// Net declarations.
	localparam integer CS_INITIAL=0,CS_ENERGY_HIGH=1,CS_ENERGY_MIDDLE=2,CS_ENERGY_LOW=3;
	integer counters_state=CS_INITIAL;
	reg [ENERGY_WIDTH-1:0] counters_data=0;
	reg counters_valid=0;
	reg counters_nreset=0;
	integer counters_sample_high=0;
	integer counters_sample_mid=0;
	integer counters_sample_low=0;
	reg [CLAPS_OUT_WIDTH-1:0] claps_total=0;
	integer claps_counter=0;
	reg claps_counter_nreset=0;
	reg claps_total_nreset=0;
	reg claps_valid=0;

	// Acquire energy sample.
	always @ (posedge clock)
		if (energy_valid==1&&energy_ready==1)
			begin
				counters_data <= energy_data;
				counters_valid <= 1;
			end
		else
			begin
				counters_valid <= 0;
			end
			
	// Increment counters related to determining a clap.
	always @ (posedge clock or negedge counters_nreset)
		if (counters_nreset==0)
			begin
				counters_sample_high <= 0;
				counters_sample_mid <= 0;
				counters_sample_low <= 0;
			end
		else if (counters_valid==1)
			begin
				if (counters_data>=ENERGY_HIGH_THRESHOLD)
					begin
						counters_sample_high <= counters_sample_high+1;
					end
				else if (counters_data>=ENERGY_LOW_THRESHOLD) 
					begin
						counters_sample_mid <= counters_sample_mid+1;
					end
				else
					begin
						counters_sample_low <= counters_sample_low+1;
					end
			end
					
	// Determine whether or not a clap occurred.
	always @ (posedge clock)
		if (counters_valid==1)
			begin
				case (counters_state)
				CS_INITIAL:
					begin
						if (counters_data>=ENERGY_HIGH_THRESHOLD)
							begin
								claps_counter_nreset <= 0;
								counters_state <= CS_ENERGY_HIGH;
							end
						counters_nreset <= 0;
					end
				CS_ENERGY_HIGH:
					begin
						if (counters_data<ENERGY_HIGH_THRESHOLD)
							begin
								if (counters_sample_high>=SAMPLE_HIGH_THRESHOLD)
									begin
										if (counters_data<=ENERGY_LOW_THRESHOLD)
											begin
												counters_state <= CS_ENERGY_LOW;
											end
										else
											begin
												counters_state <= CS_ENERGY_MIDDLE;
											end
									end
								else
									begin
										counters_nreset <= 1;
										counters_state <= CS_INITIAL;
									end
							end
					end
				CS_ENERGY_MIDDLE:
					begin
						if (counters_sample_mid<SAMPLE_MIDDLE_THRESHOLD)
							begin
								if (counters_data>=ENERGY_HIGH_THRESHOLD)
									begin
										counters_nreset <= 0;
										counters_state <= CS_INITIAL;
									end
								else if (counters_data<=ENERGY_LOW_THRESHOLD)
									begin
										counters_state <= CS_ENERGY_LOW;
									end
							end
						else
							begin
								counters_nreset <= 1;
								counters_state <= CS_INITIAL;
							end
					end
				CS_ENERGY_LOW:
					begin
						if (counters_sample_low<SAMPLE_LOW_THRESHOLD)
							begin
								if (counters_data>ENERGY_LOW_THRESHOLD)
									begin
										counters_nreset <= 1;
										counters_state <= CS_INITIAL;
									end
							end
						else
							begin
								counters_nreset <= 1;
								counters_state <= CS_INITIAL;
								claps_valid <= 1;
								claps_counter_nreset <= 1;
							end
					end
				endcase
			end
			
	// Determine the amount of samples in between claps.
	always @(posedge clock or negedge claps_counter_nreset)
		if (claps_counter_nreset==0)
			begin
				claps_counter <= 0;
			end
		else if (counters_valid==1)
			begin
				claps_counter <= claps_counter+1;
			end
			
	// Count total number of consecutive claps.
	always @(posedge clock or negedge claps_total_nreset)
		if (claps_total_nreset==0)
			begin
				claps_total <= 0;
			end
		else if (claps_valid==1)
			begin
				claps_total <= claps_total+1;
			end
			
	// Output total number of consecutive claps.
	always @(posedge clock)
		if (claps_total_nreset==1)
			begin
				claps_total_nreset <= 0;
			end
		else if (claps_counter>=CLAPS_SAMPLE_THRESHOLD)
			begin
				claps_out_data <= claps_total;
				claps_out_valid <= 1;
			end
		else if (claps_out_ready==1)
			begin
				claps_out_valid <= 0;
				claps_total_nreset <= 1;
			end
	
endmodule
