  module snn_tb();
 
   logic clk, rst_n, tx_rx;
   //final output to be compared to target
   logic[7:0] digit_out;
   //uart output from snn
   logic snn_out;
   //signals for tx sending to snn
   logic data_rdy, byte_rdy, get_byte;
   logic[7:0] new_byte, led;
   //never actually changed, just used to prevent x's from rom output
   logic[9:0] rom_addr;
 
   //input sample file paths
   localparam string input_0 = "./Files/input\ samples/ram_input_contents_sample_0.txt";
   localparam string input_1 = "./Files/input\ samples/ram_input_contents_sample_1.txt";
   localparam string input_2 = "./Files/input\ samples/ram_input_contents_sample_2.txt";
   localparam string input_3 = "./Files/input\ samples/ram_input_contents_sample_3.txt";
   localparam string input_4 = "./Files/input\ samples/ram_input_contents_sample_4.txt";
   localparam string input_5 = "./Files/input\ samples/ram_input_contents_sample_5.txt";
   localparam string input_6 = "./Files/input\ samples/ram_input_contents_sample_6.txt";
   localparam string input_7 = "./Files/input\ samples/ram_input_contents_sample_7.txt";
   localparam string input_8 = "./Files/input\ samples/ram_input_contents_sample_8.txt";
   localparam string input_9 = "./Files/input\ samples/ram_input_contents_sample_9.txt";
 
   snn snn_DUT(.clk(clk), .sys_rst_n(rst_n), .led(led), .uart_tx(snn_out), .uart_rx(tx_rx));
   //receives digit from snn
   uart_rx rx_to_PC(.clk(clk), .rst_n(rst_n), .rx(snn_out), .rx_rdy(data_rdy), .rx_data(digit_out));
   //stores initial input sample file values
   rom_tb rom_tb(.addr(rom_addr), .clk(clk), .q(q));
   //send input sample to snn
   uart_tx tx_to_snn(.clk(clk), .rst_n(rst_n), .tx_start(byte_rdy), .tx_data(new_byte), .tx(tx_rx), .tx_rdy(get_byte));
 
   task test_snn;
     input logic[3:0] target_digit;
     input logic[7:0] target_led;
     input string input_sample;
     int i, j;
     //update input sample
     $readmemh(input_sample, rom_tb.rom);
     //data initially garbage
     byte_rdy = 0;

     //i is current byte
     for (i = 0; i < 98; ++i) begin
        //j is current bit in the byte
       for (j = 0; j < 8; ++j) begin
            //force values in tx data input to new byte of values in rom
           new_byte[j] = rom_tb.rom[8 * i + j]; //get new address to read from
       end

       //assert ready to tx for one clock cycle
       @(posedge clk)
       byte_rdy = 1;
 
       @(posedge clk)
       byte_rdy = 0;
 
       //wait for tx to be ready for new byte before continuing loop
       @(posedge get_byte)
       rom_addr = 0;
     end
 
    //wait for response from snn
     @(posedge data_rdy)
     if (digit_out[3:0] == target_digit)
       $display("Test passed for target digit %d", target_digit);
     else
       $display("Test failed for target digit %d, output is %d", target_digit, digit_out);
 
     if (led == target_led)
       $display("Test passed for target LED %b, output is %b,", target_led, led);
     else
       $display("Test failed for target LED %b, output is %b,", target_led, led);
   endtask
 
 
   always
     #10 clk = ~clk;
 
   initial begin
     rst_n = 0;
     clk = 0;
     rom_addr = 10'h0;
     #10;
     rst_n = 1;
     //test for all input samples
     test_snn(4'h0, 8'h00, input_0);
     test_snn(4'h2, 8'h02, input_1);
     test_snn(4'h2, 8'h02, input_2);
     test_snn(4'h3, 8'h03, input_3);
     test_snn(4'h4, 8'h04, input_4);
     test_snn(4'h1, 8'h01, input_5);
     test_snn(4'h6, 8'h06, input_6);
     test_snn(4'h7, 8'h07, input_7);
     test_snn(4'h8, 8'h08, input_8);
     test_snn(4'h0, 8'h00, input_9);
     $stop;
   end
 
 endmodule
 
 //allows access to input file contents, initialized to zeros
 module rom_tb (
   input [9:0] addr,
   input clk,
   output logic q);
 
   // Declare the ROM variable
   reg rom[2**10-1:0];
   initial
       $readmemh("./Files/memory\ initialization\ files/ram_input_contents.txt", rom);
 
   always @(posedge clk) begin
       q <= rom[addr];
   end
 endmodule