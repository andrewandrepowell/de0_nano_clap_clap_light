module top2(
	input wire clock,
	input wire nreset, // This will later get removed.
	output wire spi_clock,
	output wire spi_chipselect,
	input wire spi_data,
	output wire toglite_state);
	
	function integer clogb2 ( input integer bit_depth );                                   
		begin                                                                              
			for( clogb2=0; bit_depth>0; clogb2=clogb2+1 )                                      
				bit_depth = bit_depth >> 1;                                                    
		end                                                                                
	endfunction 
	
	localparam integer CLOCK_PERIOD=10;
	localparam integer CLK_TRIG=2;
	localparam integer GRAB_TRIG=128;
	localparam integer RAM_ADDR_WIDTH=2;
	localparam integer SAMPLE_WIDTH=16;
	localparam integer LAG=15;
	localparam integer DURATION=16;
	localparam integer ENERGY_WIDTH= SAMPLE_WIDTH*2+clogb2(DURATION);
	
	wire [(SAMPLE_WIDTH/8)-1 : 0] sample_tstrb_sig;
	wire [SAMPLE_WIDTH-1:0] sample_data_sig;
	wire sample_ready_sig, sample_valid_sig;
	wire [ENERGY_WIDTH-1:0] energy_data_sig;
	wire energy_valid_sig, energy_ready_sig;
	
	GetSignal #(
		.CLK_TRIG( CLK_TRIG ),
		.GRAB_TRIG( GRAB_TRIG ),
		.RAM_ADDR_WIDTH( RAM_ADDR_WIDTH ),
		.C_M00_AXIS_TDATA_WIDTH( SAMPLE_WIDTH )
	) GetSignal_inst (
		.m00_axis_aclk( clock ),
		.m00_axis_aresetn( nreset ),
		.m00_axis_tvalid( sample_valid_sig ),
		.m00_axis_tdata( sample_data_sig ),
		.m00_axis_tstrb( sample_tstrb_sig ),
		.m00_axis_tready( sample_ready_sig ),
		.spi_clock( spi_clock ),
		.spi_chipselect( spi_chipselect ),
		.spi_data( spi_data ) );

	ComputeEnergy #(
		.SAMPLE_WIDTH(SAMPLE_WIDTH),
		.ENERGY_WIDTH(ENERGY_WIDTH), 
		.DURATION(DURATION),
		.LAG(LAG)
	) ComputeEnergy_inst (
		.clock(clock),	// input  clock_sig
		.sample_data(sample_data_sig),	// input [SAMPLE_WIDTH-1:0] sample_data_sig
		.sample_valid(sample_valid_sig),	// input  sample_valid_sig
		.sample_ready(sample_ready_sig),	// output  sample_ready_sig
		.energy_data(energy_data_sig),	// output [ENERGY_WIDTH-1:0] energy_data_sig
		.energy_valid(energy_valid_sig),	// output  energy_valid_sig
		.energy_ready(energy_ready_sig));

endmodule
