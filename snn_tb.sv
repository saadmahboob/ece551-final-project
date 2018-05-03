module snn_tb();

localparam BAUD_PERIOD = 52100;

logic clk, rst_n, tx_rx;
logic[7:0] digit_out;
logic tx_out;
logic data_rdy;
logic[7:0] data_in, led;
logic[9:0] rom_addr;

snn snn_DUT(.clk(clk), .sys_rst_n(rst_n), .led(led), .uart_tx(tx_out), .uart_rx(tx_rx));
uart_rx rx_to_PC(.clk(clk), .rst_n(rst_n), .rx(tx_out), .rx_rdy(data_rdy), .rx_data(digit_out));
rom_tb rom_tb(.addr(rom_addr), .clk(clk), .q(q));

task test_snn;
    input logic[3:0] target_digit;
    input logic[7:0] target_led;
    int i, j;
        for (i = 0; i < 98; ++i) begin
            tx_rx = 0;                      //send start bit
            #BAUD_PERIOD;                   //wait a baud period

            for (j = 0; j < 8; ++j) begin
                rom_addr = 8 * i + j;           //get new address to read from
                @(posedge clk)              //wait a clock cycle for data to be valid
                tx_rx = q;                  //send data
                #(BAUD_PERIOD - 1);           //wait a baud period
            end
            
            tx_rx <= 1'b1;                     //send stop bit
            #BAUD_PERIOD;                   //wait baud period before going to next data
        end

    @(posedge data_rdy)
    if (digit_out[3:0] == target_digit)
        $display("Test passed for target digit %d", target_digit);
    else
        $display("Test failed for target digit %d, output is %d", target_digit, digit_out);

    if (led == target_led)
        $display("Test passed for target LED %b, output is %b,", target_led, led);
    else
        $display("Test passed for target LED %b, output is %b,", target_led, led);
    $stop;
endtask


always
    #10 clk = ~clk;

initial begin
    rst_n = 0;
    clk = 0;
    tx_rx = 1;
    data_in = 8'h00;
    rom_addr = 10'h0;

    #10;
    rst_n = 1;
    test_snn(4'h0, 8'h09);
end

endmodule

module rom_tb (
    input [9:0] addr,
    input clk,
    output logic q);

    // Declare the ROM variable
    reg rom[2**10-1:0];
    initial
        $readmemh("./Files/input\ samples/ram_input_contents_sample_0.txt", rom);

    always @(posedge clk) begin
        q <= rom[addr];
    end
endmodule
