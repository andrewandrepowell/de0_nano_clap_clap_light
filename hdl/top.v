`timescale 1 ns / 1 ps

module top
	(
		input wire clock,
		input wire nreset, // This will later get removed.
		output wire spi_clock,
		output wire spi_chipselect,
		input wire spi_data,
		output wire toglite_state
	);
	
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	function integer clogb2 ( input integer bit_depth );                                   
	  begin                                                                              
			for( clogb2=0; bit_depth>0; clogb2=clogb2+1 )                                      
				 bit_depth = bit_depth >> 1;                                                    
	  end                                                                                
	endfunction 
	
	localparam integer SPI_CLK_DIVIDER=2;
	localparam integer SAMPLE_RATE_CLK_DIVIDER=128;
	localparam integer INPUT_BUFFER_ADDR_WIDTH=3;
	localparam integer SAMPLE_WIDTH=16;
	localparam integer SUC_CLAPS_WIDTH=16;
	localparam integer DURATION=4;
	localparam integer K_H = 128;
	localparam integer K_L = 32;
	localparam integer N_H = 64;
	localparam integer N_L = 12;
	localparam integer N_D = 12;
	localparam integer CLAPS_FOR_ON=1;
	localparam integer CLAPS_FOR_OFF=2;
	localparam integer ENERGY_WIDTH= SAMPLE_WIDTH*2+clogb2(DURATION);
	localparam integer N_CLAP = N_H+N_L;
	
	wire [SAMPLE_WIDTH-1:0] sample_data;
	wire sample_valid,sample_ready;
	wire [ENERGY_WIDTH-1:0] energy_data;
	wire energy_valid,energy_ready;
	wire clap_valid,clap_ready;
	wire [SUC_CLAPS_WIDTH-1:0] suc_claps_data;
	wire suc_claps_valid,suc_claps_ready;
	
	GetSignal #
	(
		.CLK_TRIG( SPI_CLK_DIVIDER ),
		.GRAB_TRIG( SAMPLE_RATE_CLK_DIVIDER ),
		.RAM_ADDR_WIDTH( INPUT_BUFFER_ADDR_WIDTH ),
		.C_M00_AXIS_TDATA_WIDTH( SAMPLE_WIDTH )
	)
	GetSignal_inst
	(
		.m00_axis_aclk( clock ) ,	
		.m00_axis_aresetn( nreset ) ,
		.m00_axis_tvalid( sample_valid ) ,
		.m00_axis_tdata( sample_data ) ,	
		.m00_axis_tstrb() ,	
		.m00_axis_tready( sample_ready ) ,	
		.spi_clock( spi_clock ) ,
		.spi_chipselect( spi_chipselect ) ,	
		.spi_data( spi_data ) 	
	);
	
	ComputeEnergy # 
	(
		.SAMPLE_WIDTH( SAMPLE_WIDTH ),
		.ENERGY_WIDTH( ENERGY_WIDTH ),
		.DURATION( DURATION )
	)
	ComputeEnergy_inst
	(
		.clock( clock ) ,
		.nreset( nreset ) ,	
		.sample_data( sample_data ) ,	
		.sample_valid( sample_valid ) ,	
		.sample_ready( sample_ready ) ,	
		.energy_data( energy_data ) ,	
		.energy_valid( energy_valid ) ,	
		.energy_ready( energy_ready ) 	
	);
	
	DetermineClap # 
	(
		.ENERGY_WIDTH( ENERGY_WIDTH ),
		.K_H( K_H ),
		.K_L( K_L ),
		.N_H( N_H ),
		.N_L( N_L )
	)
	DetermineClap_inst
	(
		.clock( clock ) ,	
		.nreset( nreset ) ,	
		.energy_data( energy_data ) ,	
		.energy_valid( energy_valid ) ,
		.energy_ready( energy_ready ) ,	
		.clap_valid( clap_valid ) ,	
		.clap_ready( clap_ready ) 
	);

	DetermineSuccessiveClapsAmount #
	(
		.SUC_CLAPS_WIDTH( SUC_CLAPS_WIDTH ),
		.N_D( N_D ),
		.N_CLAP( N_CLAP )
	)
	DetermineSuccessiveClapsAmount_inst
	(
		.clock( clock ) ,	
		.nreset( nreset ) ,	
		.clap_valid( clap_valid ) ,	
		.clap_ready( clap_ready ) ,	
		.energy_valid( energy_valid ) ,	
		.energy_ready( energy_ready ) ,	
		.suc_claps_data( suc_claps_data ) ,
		.suc_claps_valid( suc_claps_valid ) ,	
		.suc_claps_ready( suc_claps_ready ) 	
	);

	ToggleLight #
	(
		.SUC_CLAPS_WIDTH( SUC_CLAPS_WIDTH ),
		.TOGLITE_ON_VAL( CLAPS_FOR_ON ),
		.TOGLITE_OFF_VAL( CLAPS_FOR_OFF )
	)
	ToggleLight_inst
	(
		.clock( clock ) ,	
		.nreset( nreset ) ,	
		.suc_claps_data( suc_claps_data ) ,	
		.suc_claps_valid( suc_claps_valid ) ,	
		.suc_claps_ready( suc_claps_ready ) ,	
		.toglite_state( toglite_state ) 	
	);

endmodule
