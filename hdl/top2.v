module top2(
	input wire inclock,
	output wire spi_clock,
	output wire spi_chipselect,
	input wire spi_data,
	output wire toglite_state,
	output wire [6:0] debug);
	
	function integer clogb2 ( input integer bit_depth );                                   
		begin                                                                              
			for( clogb2=0; bit_depth>0; clogb2=clogb2+1 )                                      
				bit_depth = bit_depth >> 1;                                                    
		end                                                                                
	endfunction 
	
	localparam integer CLK_TRIG=8;
	localparam integer GRAB_TRIG=2048;
	localparam integer RAM_ADDR_WIDTH=4;
	localparam integer SAMPLE_WIDTH=16;
	localparam integer LAG=63;
	localparam integer DURATION=64;
	localparam integer SIGNAL_BIAS=-1918;
	localparam integer ENERGY_WIDTH=SAMPLE_WIDTH*2+clogb2(DURATION);
	localparam integer ENERGY_HIGH_THRESHOLD =  20000000;
	localparam integer ENERGY_LOW_THRESHOLD  =   7000000;
	localparam integer SAMPLE_HIGH_THRESHOLD = 30;
	localparam integer SAMPLE_MIDDLE_THRESHOLD = 5000;
	localparam integer SAMPLE_LOW_THRESHOLD = 5000;
	localparam integer CLAPS_SAMPLE_THRESHOLD = 40000;
	localparam integer CLAPS_WIDTH = 16;
	localparam integer TOGLITE_ON_VAL=2;
	localparam integer TOGLITE_OFF_VAL=3;
	
	wire clock, locked;
	wire [(SAMPLE_WIDTH/8)-1 : 0] sample_tstrb_sig;
	wire [SAMPLE_WIDTH-1:0] sample_data_sig;
	wire sample_ready_sig, sample_valid_sig;
	wire [ENERGY_WIDTH-1:0] energy_data_sig;
	wire energy_valid_sig, energy_ready_sig;
	wire [CLAPS_WIDTH-1:0] claps_data_sig;
	wire claps_valid_sig,claps_ready_sig;
	
	assign debug = (toglite_state==1)?2**7-1:0;
	
//	debug_0 (
//		.probe({sample_data_sig,sample_ready_sig,sample_valid_sig}),      //     probes.probe
//		.source_clk(clock), // source_clk.clk
//		.source(),     //    sources.source
//		.source_ena(locked)  //           .source_ena
//	);
	
	altpll_0 altpll_0_inst (
		.inclk0(inclock),
		.c0(clock),
		.locked(locked));
	
	GetSignal #(
		.CLK_TRIG(CLK_TRIG),
		.GRAB_TRIG(GRAB_TRIG),
		.RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
		.C_M00_AXIS_TDATA_WIDTH(SAMPLE_WIDTH)
	) GetSignal_inst (
		.m00_axis_aclk(clock),
		.m00_axis_aresetn(1'b1),
		.m00_axis_tvalid(sample_valid_sig),
		.m00_axis_tdata(sample_data_sig),
		.m00_axis_tstrb(sample_tstrb_sig),
		.m00_axis_tready(sample_ready_sig),
		.spi_clock(spi_clock),
		.spi_chipselect(spi_chipselect),
		.spi_data(spi_data));

	ComputeEnergy #(
		.SAMPLE_WIDTH(SAMPLE_WIDTH),
		.ENERGY_WIDTH(ENERGY_WIDTH), 
		.SIGNAL_BIAS(SIGNAL_BIAS),
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
		
	DetermineClap #(
		.ENERGY_WIDTH(ENERGY_WIDTH),
		.ENERGY_HIGH_THRESHOLD(ENERGY_HIGH_THRESHOLD),
		.ENERGY_LOW_THRESHOLD(ENERGY_LOW_THRESHOLD),
		.SAMPLE_HIGH_THRESHOLD(SAMPLE_HIGH_THRESHOLD),
		.SAMPLE_MIDDLE_THRESHOLD(SAMPLE_MIDDLE_THRESHOLD),
		.SAMPLE_LOW_THRESHOLD(SAMPLE_LOW_THRESHOLD),
		.CLAPS_SAMPLE_THRESHOLD(CLAPS_SAMPLE_THRESHOLD),
		.CLAPS_OUT_WIDTH(CLAPS_WIDTH)
	) DetermineClap_inst (
		.clock(clock) ,	// input  clock_sig
		.energy_data(energy_data_sig) ,	// input [ENERGY_WIDTH-1:0] energy_data_sig
		.energy_valid(energy_valid_sig) ,	// input  energy_valid_sig
		.energy_ready(energy_ready_sig) ,	// output  energy_ready_sig
		.claps_out_data(claps_data_sig) ,	// output [CLAPS_OUT_WIDTH-1:0] claps_out_data_sig
		.claps_out_valid(claps_valid_sig) ,	// output  claps_out_valid_sig
		.claps_out_ready(claps_ready_sig));
	
	ToggleLight #(
		.CLAPS_WIDTH(CLAPS_WIDTH),
		.TOGLITE_ON_VAL(TOGLITE_ON_VAL),
		.TOGLITE_OFF_VAL(TOGLITE_OFF_VAL)
	) ToggleLight_inst (
		.clock(clock) ,	// input  clock_sig
		.claps_data(claps_data_sig) ,	// input [CLAPS_WIDTH-1:0] claps_data_sig
		.claps_valid(claps_valid_sig),	// input  claps_valid_sig
		.claps_ready(claps_ready_sig),	// output  claps_ready_sig
		.toglite_state(toglite_state));

endmodule
