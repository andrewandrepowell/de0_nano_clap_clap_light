`timescale 1 ns / 1 ps

module ComputeEnergy #
	(
		parameter integer SAMPLE_WIDTH=16,
		parameter integer ENERGY_WIDTH=32,
		parameter integer DURATION=16
	)
	(
		input wire clock,
		input wire nreset,
		input wire [SAMPLE_WIDTH-1:0] sample_data,
		input wire sample_valid,
		output wire sample_ready,
		output reg [ENERGY_WIDTH-1:0] energy_data=0,
		output reg energy_valid=0,
		input wire energy_ready
	);
	
	assign sample_ready = 1;
	
	reg [SAMPLE_WIDTH-1:0] sample_hold = 0;
	reg [ENERGY_WIDTH-1:0] sum_data = 0;
	reg sum_valid = 0;
	reg sum_nreset = 0;
	integer sum_counter = 0;
	
	always @( posedge clock )
		if ( nreset==0 )
			begin
				sample_hold <= 0;
				sum_valid <= 0;
			end
		else if ( sample_valid==1 && sample_ready==1 )
			begin
				sample_hold <= sample_data;
				sum_valid <= 1;
			end
		else
			begin
				sum_valid <= 0;
			end
		
	always @( posedge clock )
		if ( sum_nreset==0 )
			begin
				sum_data <= 0;
				sum_counter <= 0;
			end
		else if ( sum_valid==1 )
			begin
				sum_data <= sum_data+(sample_hold*sample_hold);
				sum_counter <= sum_counter+1;
			end
			
	always @(posedge clock )
		if ( (energy_valid==1 && energy_ready==1) || nreset==0 )
			begin
				energy_valid <= 0;
			end
		else if ( sum_counter==(DURATION-1) )
			begin
				energy_data <= sum_data;
				energy_valid <= 1;
			end
			
	always @( posedge clock )
		if ( nreset==0 )
			sum_nreset <= !(sum_counter==(DURATION-1)); 
		else
			sum_nreset <= 0;

	
endmodule 