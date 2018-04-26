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
	logic rx_rdy, tx_rdy, txrx;
	logic[7:0] uart_data;
	
	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
		uart_rx_ff <= 1'b1;
		uart_rx_synch <= 1'b1;
	end else begin
	  uart_rx_ff <= uart_rx;
	
	uart_rx_synch <= uart_rx_ff;
	end
	
	
	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".
	 uart_rx uart_rx_DUT(.clk(clk), .rst_n(sys_rst_n), .rx(uart_rx_synch), .rx_data(uart_data), .rx_rdy(txrx));
	 uart_tx uart_tx_DUT(.clk(clk), .rst_n(sys_rst_n), .tx_start(txrx), .tx_data(uart_data), .tx(uart_tx), .tx_rdy());
     snn_core core(.start(), .q_input(), .addr_input_unit(), .digit(), .done());
     ram test_data(.data(), .addr(addr_reg), .we(), .clk(clk), .q(q_input));

	/******************************************************
	LED
	******************************************************/
	assign led = uart_data;

endmodule
