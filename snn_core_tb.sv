module snn_core_tb();

logic clk, rst_n, strt, done, q_input;
//output from snn_core, compare to target digit
logic [3:0] digit;
//input to ram, output from snn_core
logic [9:0] addr_reg;

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

snn_core iDUT_snn_core(.start(strt), .q_input(q_input), .addr_input_unit(addr_reg), .digit(digit), .done(done), .rst_n(rst_n), .clk(clk));
ram iDUT_ram(.data(), .addr(addr_reg), .we(), .clk(clk), .q(q_input));

task check_digit(input logic[3:0] num, input string input_sample);
    //update ram with current input cycle
    $readmemb(input_sample, iDUT_ram.ram);
    //assert strt to snn_core for single clock edge
    @ (posedge clk)
    strt = 1;
    @ (posedge clk)
    strt = 0;
    //wait for response from snn_core
    @(posedge done)
    if (digit == num)
        $display("Test passed: input: %d, digit: %d\n", num, digit);
    else
        $display("Test failed: input: %d, digit: %d\n", num, digit);
endtask

initial begin
    clk=0;
    rst_n = 0;
    strt = 0;
    #5;
    rst_n = 1;
    //check for each sample file
    check_digit(0, input_0);
    //input 1 should be incorrect recognition (2)
    check_digit(2, input_1);
    check_digit(2, input_2);
    check_digit(3, input_3);
    check_digit(4, input_4);
    //input 5 should be incorrect recognition (1)
    check_digit(1, input_5);
    check_digit(6, input_6);
    check_digit(7, input_7);
    check_digit(8, input_8);
    //input 9 should be incorrect recognition (0)
    check_digit(0, input_9);
    $stop;
end

always
  #10 clk = ~clk;

endmodule

//equivalent of ram input unit in snn
module ram (
    input data,
    input [9:0] addr,
    input we, clk,
    output q);

// Declare the RAM variable
reg ram[(2**10)-1:0];

// Variable to hold the registered read address
logic [9:0] addr_reg;

initial begin
    //initialize with all zeros
    $readmemb("./Files/memory\ initialization\ files/ram_input_contents.txt", ram);

end

always @ (posedge clk)
begin
    addr_reg <= addr;
end

assign q = ram[addr_reg];

endmodule
