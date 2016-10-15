`timescale 1 ns / 1 ps

module DetermineSuccessiveClapsAmount #
	(
		parameter integer SUC_CLAPS_WIDTH=16,
		parameter integer N_D=16,
		parameter integer N_CLAP=16
	)
	(
		input wire clock,
		input wire nreset,
		input wire clap_valid,
		output reg clap_ready=0,
		input wire energy_valid,
		input wire energy_ready,
		output reg [SUC_CLAPS_WIDTH-1:0] suc_claps_data=0,
		output reg suc_claps_valid=0,
		input wire suc_claps_ready
	);
	
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	function integer clogb2 ( input integer bit_depth );                                   
	  begin                                                                              
			for( clogb2=0; bit_depth>0; clogb2=clogb2+1 )                                      
				 bit_depth = bit_depth >> 1;                                                    
	  end                                                                                
	endfunction  
	
	localparam integer ENERGY_CLAP_THRES=N_D+N_CLAP;
	reg energy_nreset=0,clap_nreset=0;
	reg [clogb2(ENERGY_CLAP_THRES)-1:0] energy_amt=0;
	reg [SUC_CLAPS_WIDTH-1:0] suc_claps_amt=0;
	wire energy_amt_reached;
	assign energy_amt_reached = ( energy_amt==(ENERGY_CLAP_THRES-1) );
			
	always @( posedge clock )
		if ( (suc_claps_valid==1 && suc_claps_ready==1) || nreset==0 )
			begin
				suc_claps_valid <= 0;
			end
		else if ( energy_amt_reached==1 )
			begin
				suc_claps_data <= suc_claps_amt;
				suc_claps_valid <= 1;
			end 
			
	always @( posedge clock or negedge energy_nreset )
		if ( energy_nreset==0 )
			begin
				energy_amt <= 0;
			end
		else if ( energy_valid==1 && energy_ready==1 )
			begin
				energy_amt <= energy_amt+1;
			end
			
	always @( posedge clock or negedge clap_nreset )
		if ( clap_nreset==0 )
			begin
				clap_ready <= 0;
				suc_claps_amt <= 0;
			end
		else
			begin
				if ( clap_valid==1 && clap_ready==1 )
					begin
						suc_claps_amt <= suc_claps_amt+1;
					end
				clap_ready <= 1;	
			end
			
	always @( posedge clock )
		begin
			clap_nreset = !energy_amt_reached;
			energy_nreset = !( energy_amt_reached || ( clap_valid==1 && clap_ready==1 ) );
		end
	
endmodule
