`timescale 1 ns / 1 ps

module ToggleLight # 
	(
		parameter integer CLAPS_WIDTH=16,
		parameter integer TOGLITE_ON_VAL= 2,
		parameter integer TOGLITE_OFF_VAL=3
	)
	(
		input wire clock,
		input wire [CLAPS_WIDTH-1:0] claps_data,
		input wire claps_valid,
		output reg claps_ready=0,
		output reg toglite_state=0
	);
	
	reg [CLAPS_WIDTH-1:0] claps_buff=0;

	always @(posedge clock)
		if (claps_valid==1&&claps_ready==1)
			begin
				claps_buff <= claps_data;
				claps_ready <= 0;
			end
		else
			begin
				claps_ready <= 1;
			end
			
	always @(posedge clock)
		if (claps_buff==TOGLITE_ON_VAL)
			begin
				toglite_state <= 1;
			end 
		else if (claps_buff==TOGLITE_OFF_VAL)
			begin
				toglite_state <= 0;
			end
	
endmodule
