module snn_tb();

//localparam BAUD_PERIOD = 52100;

logic clk, rst_n, tx_rx;
logic[7:0] digit_out;
logic snn_out;
logic data_rdy, byte_rdy, get_byte;
logic[7:0] new_byte, led;
logic[9:0] rom_addr;

snn snn_DUT(.clk(clk), .sys_rst_n(rst_n), .led(led), .uart_tx(snn_out), .uart_rx(tx_rx));
uart_rx rx_to_PC(.clk(clk), .rst_n(rst_n), .rx(snn_out), .rx_rdy(data_rdy), .rx_data(digit_out));
rom_tb rom_tb(.addr(rom_addr), .clk(clk), .q(q));
uart_tx tx_to_snn(.clk(clk), .rst_n(rst_n), .tx_start(byte_rdy), .tx_data(new_byte), .tx(tx_rx), .tx_rdy(get_byte));

task test_snn;
    input logic[3:0] target_digit;
    input logic[7:0] target_led;
    int i, j;
    byte_rdy = 0;
        for (i = 0; i < 98; ++i) begin
            //tx_rx = 0;                      //send start bit
            //#BAUD_PERIOD;                   //wait a baud period

            for (j = 0; j < 8; ++j) begin
                new_byte[j] = rom_tb.rom[8 * i + j]; //get new address to read from
            end
            @(posedge clk)  
            byte_rdy = 1;  
            
            @(posedge clk)
            byte_rdy = 0;

            @(posedge get_byte)
            rom_addr = 0;

           // @(posedge get_byte);
                
                //@(posedge clk)              //wait a clock cycle for data to be valid
                //tx_rx = q;                  //send data
                //#(BAUD_PERIOD - 1);           //wait a baud period
        end
            
            //tx_rx <= 1'b1;                     //send stop bit
            //#BAUD_PERIOD;                   //wait baud period before going to next data
        //end

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
        $readmemh("./Files/input\ samples/ram_input_contents_sample_2.txt", rom);

    always @(posedge clk) begin
        q <= rom[addr];
    end
endmodule
