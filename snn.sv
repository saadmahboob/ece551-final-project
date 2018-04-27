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
	logic[9:0] addr_input_unit;

	//control FSM wires
	logic snn_start, write_enable, tx_rdy;

	uart_rx uart_rx_in(.clk(clk), .rst_n(sys_rst_n), .rx(uart_rx_synch), .rx_data(rx_data), .rx_rdy(rx_rdy));
	//logic between rx_in and tx_to_ram: rx_data, rx_rdy
	uart_tx tx_to_ram(.clk(clk), .rst_n(sys_rst_n), .tx_start(rx_rdy), .tx_data(rx_data), .tx(ram_in), .tx_rdy(tx_rdy));
	//logic between tx_to_ram and test_data: ram_in
	ram test_data(.data(ram_in), .addr(addr_input_unit), .we(write_enable), .clk(clk), .q(q_input));
	//logic between test_data and core: q_input. addr_input_unit
	snn_core core(.start(snn_start), .q_input(q_input), .addr_input_unit(addr_input_unit), .digit(digit), .done(snn_done));
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
	end
	
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
		write_enable = 0;

		case(state)
			IDLE:
				if()


     
	 
	 

	/******************************************************
	LED
	******************************************************/
	assign led = tx_data;

endmodule
