
`timescale 1 ns / 1 ps

////////////////////////////////////////////////
// Intended to sample and buffer audio samples from the Digilent PmodMIC
////////////////////////////////////////////////

module GetSignal #
    (
        parameter integer CLK_TRIG=2,
        parameter integer GRAB_TRIG=128,
        parameter integer RAM_ADDR_WIDTH=3,
        parameter integer C_M00_AXIS_TDATA_WIDTH=16
    )
    (
        input wire  m00_axis_aclk,
        input wire m00_axis_aresetn,
        output wire  m00_axis_tvalid,
        output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
        output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
        input wire  m00_axis_tready,
        output wire spi_clock,
        output wire spi_chipselect,
        input wire spi_data
    );

    wire spi2driver_ready;
    wire spi2driver_valid;
    wire [ C_M00_AXIS_TDATA_WIDTH-1:0 ] spi2driver_data;
    
    wire driver2fifo_valid;
    wire [ C_M00_AXIS_TDATA_WIDTH-1:0 ] driver2fifo_data;

    assign m00_axis_tstrb = {(C_M00_AXIS_TDATA_WIDTH/8){1'b1}};

    spimaster #(
        .CLK_TRIG( CLK_TRIG ),
        .SAMPLE_WIDTH( C_M00_AXIS_TDATA_WIDTH )
    ) spimaster_inst (
        .clock( m00_axis_aclk ),
        .spi_clock( spi_clock ),
        .spi_chipselect( spi_chipselect ),
        .spi_data( spi_data ),
        .axis_master_ready( spi2driver_ready ),
        .axis_master_valid( spi2driver_valid ),
        .axis_master_data( spi2driver_data ) );
        
    driver #(
        .GRAB_TRIG( GRAB_TRIG ),
        .SAMPLE_WIDTH( C_M00_AXIS_TDATA_WIDTH )
    ) driver_inst (
        .clock( m00_axis_aclk ),
        .axis_slave_ready( spi2driver_ready ),
        .axis_slave_valid( spi2driver_valid ),
        .axis_slave_data( spi2driver_data ),
        .axis_master_valid( driver2fifo_valid ),
        .axis_master_data( driver2fifo_data ) );
        
    fifo #(
        .RAM_ADDR_WIDTH( RAM_ADDR_WIDTH ),
        .FIFO_WIDTH( C_M00_AXIS_TDATA_WIDTH ) 
    ) fifo_inst (
        .clock( m00_axis_aclk ),
        .nreset( m00_axis_aresetn ),
        .reset( 0 ),
		  .in_stb( driver2fifo_valid ),
        .in_ack(),
        .in_data( driver2fifo_data ),
        .out_stb( m00_axis_tvalid ),
        .out_ack( m00_axis_tready ),
        .out_data( m00_axis_tdata ) );

endmodule
