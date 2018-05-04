/* Module for an 8-bit UART receiver.
 * It takes clock, reset_n, input signal as inputs
 * and outputs when the data is ready and the data.
 *
 */
 module uart_rx(clk, rst_n, rx, rx_rdy, rx_data);

	input clk, rst_n, rx;
	output logic rx_rdy;
	output reg [7:0] rx_data;

	reg [3:0] bit_cnt;		//counter to count total bits of data received
	reg[11:0] baud_cnt;		//baud counter

	logic clr_shitf_reg, clr_baud, shitf;
	logic half_baud, full_baud, bit_full;

	typedef enum reg[1:0] {IDLE, FRONT_PORCH, BACK_PORCH, RX} state_t;
	state_t state, next_state;

	assign half_baud = (baud_cnt == 1302) ? 1 : 0;
	assign full_baud = (baud_cnt == 2604) ? 1 : 0;
	assign bit_full = (bit_cnt == 4'h8) ? 1 : 0;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <=next_state;

	always_comb begin
		//default values
		clr_baud = 1;
		clr_shitf_reg = 1;
		shitf = 0;
		next_state = IDLE;
		rx_rdy = 0;

		case (state)
			IDLE:
				if (!rx) begin					//start bit detected
					next_state = FRONT_PORCH;
					clr_baud = 0;
				end

			FRONT_PORCH:
				if (half_baud)					//at middle of start bit
					next_state = RX;
				else begin
					next_state = FRONT_PORCH;
					clr_baud = 0;
				end

			RX:
				if (!bit_full && full_baud) begin	//middle of a bit which isn't the stop bit
					next_state = RX;
					shitf = 1;
					clr_shitf_reg = 0;
				end
				else if (bit_full) begin		//all bits received
					next_state = BACK_PORCH;
					clr_shitf_reg = 0;
				end
				else begin
					next_state = RX;
					clr_baud = 0;
					clr_shitf_reg = 0;
				end

			BACK_PORCH:
				if (rx && half_baud) begin		//at middle of stop bit
					next_state = IDLE;
					rx_rdy = 1;
				end
				else if (half_baud)
					next_state = IDLE;
				else begin
					next_state = BACK_PORCH;
					clr_baud = 0;
				end
			endcase
		end

	//data output register
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			rx_data <= 8'h00;
		else if (shitf)
			rx_data <= {rx, rx_data[7:1]};

	//baud counter
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			baud_cnt <= 12'h000;
		else
			baud_cnt <= clr_baud ? 0 : baud_cnt + 1;

	//bit counter
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			bit_cnt <= 4'h0;
		else
			if (clr_shitf_reg)
				bit_cnt <= 4'h0;
			else if (full_baud)
				bit_cnt <= bit_cnt + 1;

endmodule
