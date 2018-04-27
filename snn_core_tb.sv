module snn_core_tb();

logic clk, rst_n, rx_rdy, tx_start, strt, done, q_input, we;
logic [3:0] digit;

snn_core iDUT_snn_core(.strt(strt), .q_input(q_input), .addr_input_unit(addr_reg), .digit(digit), .done(done));
ram iDUT_ram(.data(), .addr(addr_reg), .we(), .clk(clk), .q(q_input));

task check_digit(input logic[3:0] num);
    @(posedge done)
    if (digit == num)
        $display("Test passed: input: %d, digit: %d\n", num, digit);
    else
        $display("Test failed: input: %d, digit: %d\n", num, digit);
endtask

initial begin
    rst_n = 0;
    #5;
    rst_n = 1;
    check_digit();
end

always @(posedge clk) begin
    if (rst_n) begin
        strt = 0;
    end
    else begin
        start = 1;
    end
end
endmodule

module ram (
    input data,
    input [9:0] addr,
    input we, clk,
    output q);

// Declare the RAM variable
reg ram[2**9:0];

// Variable to hold the registered read address
logic [9:0] addr_reg;

initial begin
    readmemh("Initialization file", ram);
    
end

always @ (posedge clk)
begin
    addr_reg <= addr;
end 

assign q = ram[addr_reg];

endmodule


