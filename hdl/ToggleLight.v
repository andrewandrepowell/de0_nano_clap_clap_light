`timescale 1 ns / 1 ps

module ToggleLight # 
	(
		parameter integer SUC_CLAPS_WIDTH=16,
		parameter integer TOGLITE_ON_VAL= 1,
		parameter integer TOGLITE_OFF_VAL=2
	)
	(
		input wire clock,
		input wire nreset,
		input wire [SUC_CLAPS_WIDTH-1:0] suc_claps_data,
		input wire suc_claps_valid,
		output wire suc_claps_ready,
		output reg toglite_state=0
	);

	reg [SUC_CLAPS_WIDTH-1:0] toglite_suc_claps=0;
	reg toglite_valid=0;
	
	assign suc_claps_ready=1;

	always @( posedge clock )
		if ( nreset==0 )
			begin
				toglite_valid <= 0;
			end
		else if ( suc_claps_valid==1 && suc_claps_ready==1 )
			begin
				toglite_suc_claps <= suc_claps_data;
				toglite_valid <= 1;
			end
		else
			begin
				toglite_valid <= 0;
			end
			
	always @( posedge clock )
		if ( nreset==0 )
			begin
				toglite_state <= 0;
			end
		else if ( toglite_valid==1 )
			if ( toglite_suc_claps==TOGLITE_ON_VAL )
				begin
					toglite_state <= 1;
				end
			else if ( toglite_suc_claps==TOGLITE_OFF_VAL )
				begin
					toglite_state <= 0;
				end
	
endmodule
