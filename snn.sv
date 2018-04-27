module snn(clk, sys_rst_n, led, uart_tx, uart_rx);
		
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	output logic [7:0] led;	// Drives LEDs of DE0 nano board
	
	input uart_rx;
	output uart_tx;

	logic rst_n;				 	// Synchronized active low reset
	
	logic uart_rx_ff, uart_rx_synch;

	/******************************************************
	Reset synchronizer
	******************************************************/
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
	
	/******************************************************
	UART
	******************************************************/
	
	// Declare wires below
	logic rx_rdy, tx_rdy, snn_done, q_input, ram_in;
	logic[7:0] rx_data, tx_data;
	logic[3:0] digit;
	logic[9:0] addr_input_unit, write_address, read_address;

	assign addr_input_unit = write_enable ? write_address : read_address;

	//control FSM wires
	logic snn_start, write_enable, tx_rdy, shift;
	logic [3:0]shift_cnt;

	uart_rx uart_rx_in(.clk(clk), .rst_n(sys_rst_n), .rx(uart_rx_synch), .rx_data(rx_data), .rx_rdy(rx_rdy));
	
	ram test_data(.data(rx_data[0]), .addr(addr_input_unit), .we(write_enable), .clk(clk), .q(q_input));
	//logic between test_data and core: q_input. addr_input_unit
	snn_core core(.start(snn_start), .q_input(q_input), .addr_input_unit(read_address), .digit(digit), .done(snn_done));
	//logic between core and tx_out: snn_done, digit
	uart_tx uart_tx_out(.clk(clk), .rst_n(sys_rst_n), .tx_start(snn_done), .tx_data(tx_data), .tx(uart_tx), .tx_rdy());
	
	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			uart_rx_ff <= 1'b1;
			uart_rx_synch <= 1'b1;
		end
	 else begin
	  uart_rx_ff <= uart_rx;
	  uart_rx_synch <= uart_rx_ff;
	  if (write_enable)
		write_address <= write_address + 1;
	end

	always_ff @(posedge clk) 
		if (shift) begin
			rx_data <= {1'b0, rx_data[7:1]};
			shift_cnt <= shift_cnt + 1;
			write_address <= write_address + 1;
		end
		else begin
			shift_cnt <= 3'h0;
			write_address <= 10'h0;
		end


	assign max_shift = (shift_cnt == 3'h7) ? 1 : 0;
	assign max_addr = (write_addr == 10'h310) ? 1: 0;
	
	
	assign tx_data = {4'h0, digit[3:0]};


	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".

	//control FSM
	typedef enum reg[1:0] {IDLE, LOAD, READ} state_t;
	state_t state, next_state;

	always_ff (@posedge clk, negedge sys_rst_n) {
		if (!rst_n)
        	state <= IDLE;
    	else
    		state <= nxt_state;
	}

	always_comb begin
		next_state = IDLE;
		snn_start = 0;
		write = 0;
		shift = 0;

		case(state)
			IDLE:
				if(rx_rdy) begin
					next_state = LOAD;
					write_enable = 1;
				end
			LOAD:
				shift = 1;
				write_enable = 1;
				if (~max_shift)
					next_state = LOAD;
				else if (addr_max)
					next_state = READ;
			READ:
				snn_start = 1;
				if (~done)
					next_state = READ;
			endcase
	end

	

					
					





     
	 
	 

	/******************************************************
	LED
	******************************************************/
	assign led = tx_data;

endmodule
