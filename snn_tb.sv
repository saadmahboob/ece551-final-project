module snn_tb();

logic clk, rst_n, tx_rx, start, tx_rdy;
logic[3:0] digit_out;
logic[7:0] data_in, led;

snn snn_DUT(.clk(clk), .sys_rst_n(rst_n), .led(led), .uart_tx(digit_out), .uart_rx(tx_rx));
uart_tx tx_in(.clk(clk), .rst_n(rst_n), .tx_start(start), .tx_data(data_in), .tx(tx_rx), .tx_rdy(tx_rdy));
rom_tb rom_tb(.addr(addr), .clk(clk), .q(q));

task test_snn;
    input logic[3:0] target_digit;
    input logic[7:0] target_led;
    int i, j;
        for (i = 0; i < 98; ++i) begin
        @(posedge clk)
        start = 1;

        for (j = 0; j < 8; ++j)
            data_in[j] = rom_tb.rom[8 * i + j];

        @(posedge clk)
        data_in = 8'hFF;
        start = 0;
        @(posedge tx_rdy);
        end

    @(posedge snn_DUT.uart_tx_out.tx_rdy)

    if (digit_out == target_digit)
        $display("Test passed for target digit %d", target_digit);
    else
        $display("Test failed for target digit %d, output is %d", target_digit, digit_out);

    if (led == target_led)
        $display("Test passed for target LED %b, output is %b,", target_led, led);
    else
        $display("Test passed for target LED %b, output is %b,", target_led, led);
endtask


always
    #5 clk = ~clk;

initial begin
    rst_n = 0;
    clk = 0;
    start = 0;
    data_in = 8'h00;

    #10;
    rst_n = 1 ;
    test_snn(4'h9, 8'h09);
    $stop;
end

endmodule

module rom_tb (
    input [9:0] addr,
    input clk,
    output logic q);

    // Declare the ROM variable
    reg rom[2**10-1:0];
    initial
    readmemh("./File/input\ samples/ram_input_contents_sample_6.txt", rom);

    always @(posedge clk)
    begin
    q <= rom[addr];
    end
endmodule
