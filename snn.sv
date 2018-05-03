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
	logic[7:0] rx_data, tx_data, rx;
	logic[3:0] digit;
	logic[9:0] addr_input_unit, write_addr, read_addr;

	//control FSM wires
	logic snn_start, write_enable, shift_cnt_en, shift_wa_en, clr_cnt, clr_wa;
	logic [3:0]shift_cnt;

	assign addr_input_unit = write_enable ? write_addr : read_addr;

	uart_rx uart_rx_in(.clk(clk), .rst_n(sys_rst_n), .rx(uart_rx_synch), .rx_data(rx_data), .rx_rdy(rx_rdy));
	ram_input test_data(.data(rx[0]), .addr(addr_input_unit), .we(write_enable), .clk(clk), .q(q_input));
	//logic between test_data and core: q_input. addr_input_unit
	snn_core core(.start(snn_start), .q_input(q_input), .addr_input_unit(read_addr), .digit(digit), .done(snn_done), .clk(clk), .rst_n(rst_n));
	//logic between core and tx_out: snn_done, digitq_inpu
	uart_tx uart_tx_out(.clk(clk), .rst_n(sys_rst_n), .tx_start(snn_done), .tx_data(tx_data), .tx(uart_tx), .tx_rdy());

//	assign rx = rx_data;
	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			uart_rx_ff <= 1'b1;
			uart_rx_synch <= 1'b1;
		end
	 	else begin
	  		uart_rx_ff <= uart_rx;
	  		uart_rx_synch <= uart_rx_ff;
	end

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) 
			shift_cnt <= 3'h0;
		else
			if (shift_cnt_en) 
				shift_cnt <= shift_cnt + 1;
			else if (clr_cnt)
				shift_cnt <=0;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) 
			write_addr <= 10'h0;
		else
			if (shift_wa_en) 
				write_addr <= write_addr + 1;
			else if (clr_wa)
				write_addr <=0;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			rx <= 0;
		else if (rx_rdy)
			rx <= rx_data;
		else if (shift_cnt_en)
			rx <= {1'b0, rx[7:1]};



	assign max_shift = (shift_cnt == 3'h7) ? 1 : 0;
	assign max_addr = (write_addr == 10'h30f) ? 1 : 0;
	assign tx_data = {4'h0, digit[3:0]};


	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".

	//control FSM
	typedef enum reg[1:0] {IDLE, LOAD, BACK_PORCH, READ} state_t;
	state_t state, next_state;

	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
        	state <= IDLE;
    	else
    		state <= next_state;

	always_comb begin
		next_state = IDLE;
		snn_start = 0;
		write_enable = 0;
		shift_cnt_en = 0;
		shift_wa_en = 0;
		clr_cnt = 1;
		clr_wa = 0;

		case(state)
			IDLE:
				if(rx_rdy) begin
					// write_enable = 1;
					// shift_cnt_en = 1;
					//shift_wa_en = 1;
					next_state = LOAD;
				end

			LOAD: begin
				write_enable = 1;
				shift_cnt_en = 1;
				shift_wa_en = 1;
				if (~max_shift)
					next_state = LOAD;
				else if (max_addr)
					next_state = READ;
			end

			BACK_PORCH: begin
				next_state = READ;
			end
			
			READ: begin
				snn_start = 1;
				if (~snn_done)
					next_state = READ;
			end
			endcase
	end



	/******************************************************
	LED
	******************************************************/
	assign led = tx_data;

endmodule

module ram_input (
	input data,
	input [9:0] addr,
	input we, clk,
	output q);
	// Declare the RAM variable
	reg [7:0] ram[2**10-1:0];
	// Variable to hold the registered read address
	reg [9:0] addr_reg;
	initial
		$readmemh("./Files/memory\ initialization\ files/ram_input_contents.txt", ram);

	always @ (posedge clk) begin
	if (we) // Write
		ram[addr] <= data;
	addr_reg <= addr;
	end

	assign q = ram[addr_reg];
endmodule
