`timescale 1 ns / 1 ps

module DetermineClap #
	(
		parameter integer ENERGY_WIDTH=16,
		parameter integer K_H=64,
		parameter integer K_L=32,
		parameter integer N_L=32,
		parameter integer N_H=32
	)
	(
		input wire clock,
		input wire nreset,
		input wire [ENERGY_WIDTH-1:0] energy_data,
		input wire energy_valid,
		output reg energy_ready=0,
		output reg clap_valid=0,
		input wire clap_ready
	);
	
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	function integer clogb2 ( input integer bit_depth );                                   
	  begin                                                                              
			for( clogb2=0; bit_depth>0; clogb2=clogb2+1 )                                      
				 bit_depth = bit_depth >> 1;                                                    
	  end                                                                                
	endfunction  

	// Nets and local parameters.
	localparam integer LOHI_S_LOW=0,LOHI_S_MID=1,LOHI_S_HIGH=2;
	localparam integer LOHI_HIGH_AMT_WIDTH=clogb2(N_H);
	localparam integer LOHI_LOW_AMT_WIDTH=clogb2(N_L);
	reg lohi_valid=0,lohi_ready=0;
	reg [ENERGY_WIDTH-1:0] lohi_energy=0;
	reg [1:0] lohi_state = LOHI_S_MID;
	reg [LOHI_HIGH_AMT_WIDTH-1:0] lohi_high_amt=0;
	reg [LOHI_HIGH_AMT_WIDTH-1:0] lohi_high_amt_buff=0;
	reg [LOHI_LOW_AMT_WIDTH-1:0] lohi_low_amt=0;
	
	// Acquire the energy.
	always @( posedge clock )
		if ( nreset==0 )
			begin
				lohi_valid <= 0;
				energy_ready <= 0;
			end
		else if ( lohi_valid==1 && lohi_ready==1 )
			begin
				lohi_valid <= 0;
			end
		else if ( energy_valid==1 && energy_ready==1 )
			begin
				lohi_energy <= energy_data;
				lohi_valid <= 1;
				energy_ready <= 0;
			end
		else
			begin
				energy_ready <= 1;
			end
		
	// Determine whether or not a clap occurred.
	always @( posedge clock )
		if ( nreset==0 )
			begin
				lohi_ready <= 0;
				lohi_state <= LOHI_S_MID;
				lohi_high_amt <= 0;
				lohi_high_amt_buff <= 0;
				lohi_low_amt <= 0;
				clap_valid <= 0;
			end
		else if ( clap_valid==1 && clap_ready==1 )
			begin
				clap_valid <= 0;
			end
		else if ( lohi_valid==1 && lohi_ready==1 )
			begin
				if ( lohi_energy<K_L )
					if ( lohi_state!=LOHI_S_LOW )
						begin
							lohi_high_amt <= 0;
							lohi_high_amt_buff <= lohi_high_amt;
							lohi_low_amt <= 1;
							lohi_state <= LOHI_S_LOW;
						end
					else if ( ((lohi_low_amt-1)==N_L) && (lohi_high_amt_buff==N_H) )
						begin
							clap_valid <= 1;
							lohi_high_amt_buff <= 0;
							lohi_low_amt <= 0;
						end
					else
						begin
							lohi_low_amt <= lohi_low_amt+1;
						end
				else if ( lohi_energy>K_H )
					if ( lohi_state!=LOHI_S_HIGH )
						begin
							lohi_low_amt <= 0;
							lohi_high_amt <= 1;
							lohi_state <= LOHI_S_HIGH;
						end
					else 
						begin
							lohi_high_amt <= lohi_high_amt+1;
						end
				else if ( lohi_state!=LOHI_S_MID )
					begin
						lohi_high_amt <= 0;
						lohi_low_amt <= 0;
						lohi_state <= LOHI_S_MID;
					end
				lohi_ready <= 0;
			end 
		else 
			begin	
				lohi_ready <= 1;	
			end
	
endmodule
