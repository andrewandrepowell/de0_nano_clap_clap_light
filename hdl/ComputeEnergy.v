`timescale 1 ns / 1 ps

module ComputeEnergy #
	(
		parameter integer SAMPLE_WIDTH=16,
		parameter integer ENERGY_WIDTH=32,
		parameter integer SIGNAL_BIAS=-32,
		parameter integer DURATION=16,
		parameter integer LAG=15
	)
	(
		input wire clock,
		input wire [SAMPLE_WIDTH-1:0] sample_data,
		input wire sample_valid,
		output reg sample_ready=0,
		output reg [ENERGY_WIDTH-1:0] energy_data=0,
		output reg energy_valid=0,
		input wire energy_ready
	);
	
	localparam integer START_COMPUTE=DURATION-LAG;
	
	localparam integer SS_WAIT_FOR_SAMPLE=0,SS_SHIFT_IN_SAMPLE=1;
	integer sample_state=SS_WAIT_FOR_SAMPLE;
	integer sample_ptr=0;
	reg [SAMPLE_WIDTH-1:0] sample_buff=0;
	reg [SAMPLE_WIDTH-1:0] sample_fifo [0:DURATION-1];
	initial
		begin : process_initialize
			integer each_sample;
			for (each_sample=0;each_sample<DURATION;each_sample=each_sample+1)
				sample_fifo[each_sample] <= 0;
		end

	localparam integer CS_WAIT_FOR_VALID=0,CS_COMPUTE_ENERGY=1;
	integer compute_state=CS_WAIT_FOR_VALID;
	integer compute_cnt=0;
	integer compute_ptr=0;
	reg [SAMPLE_WIDTH*2-1:0] compute_square=0;
	reg compute_valid=0;
	reg [ENERGY_WIDTH-1:0] compute_total=0;

	reg final_valid=0;
	reg [ENERGY_WIDTH-1:0] final_data=0;
	

	// Sample new data into fifo.
	always @(posedge clock) 
		case (sample_state)
		SS_WAIT_FOR_SAMPLE:
			begin
				compute_valid <= 0;
				if (sample_valid==1&&sample_ready==1)
					begin
						sample_ready <= 0;
						sample_ptr <= (DURATION-1);
						sample_buff <= sample_data;
						sample_state <= SS_SHIFT_IN_SAMPLE;
					end
				else
					begin
						sample_ready <= 1;
					end
			end
		SS_SHIFT_IN_SAMPLE:
			begin
				if (sample_ptr!=0)
					begin
						sample_fifo[sample_ptr] <= sample_fifo[sample_ptr-1];
						sample_ptr <= sample_ptr-1;
					end
				else
					begin
						sample_fifo[0] <= sample_buff+SIGNAL_BIAS;
						if (compute_cnt==(START_COMPUTE-1))
							begin
								compute_cnt <= 0;
								compute_valid <= 1;
							end
						else
							begin
								compute_cnt <= compute_cnt+1;
							end
						sample_state <= SS_WAIT_FOR_SAMPLE;
					end
			end
		endcase
			
	// Compute the energy.
	always @(posedge clock) 
		case (compute_state)
		CS_WAIT_FOR_VALID:
			begin
				final_valid <= 0;
				if (compute_valid==1)
					begin
						compute_ptr <= 0;
						compute_total <= 0;
						compute_state <= CS_COMPUTE_ENERGY;
					end
			end
		CS_COMPUTE_ENERGY:
			begin
				if (compute_ptr!=DURATION)
					begin 
						compute_square = 
							$signed(sample_fifo[compute_ptr])*
							$signed(sample_fifo[compute_ptr]);
						compute_total = compute_total+compute_square;
						compute_ptr <= compute_ptr+1;
					end
				else
					begin
						final_valid <= 1;
						final_data <= compute_total;
						compute_state <= CS_WAIT_FOR_VALID;
					end
			end
		endcase
		
	// Output the resultant energy.
	always @(posedge clock)
		if (final_valid==1)
			begin
				energy_data <= final_data;
				energy_valid <= 1;
			end
		else if (energy_valid==1&&energy_ready==1)
			begin
				energy_valid <= 0;
			end

	
endmodule 