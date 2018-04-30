module snn_core_tb();

logic clk, rst_n, strt, done, q_input;
logic [3:0] digit;
logic [9:0] addr_reg;

snn_core iDUT_snn_core(.start(strt), .q_input(q_input), .addr_input_unit(addr_reg), .digit(digit), .done(done), .rst_n(rst_n), .clk(clk));
ram iDUT_ram(.data(), .addr(addr_reg), .we(), .clk(clk), .q(q_input));

task check_digit(input logic[3:0] num);
    @(posedge done)
    if (digit == num)
        $display("Test passed: input: %d, digit: %d\n", num, digit);
    else
        $display("Test failed: input: %d, digit: %d\n", num, digit);
    $stop();
endtask

initial begin
    clk=0;
    rst_n = 0;
    #5;
    rst_n = 1;
    check_digit(6);
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        strt = 0;
    end
    else begin
        strt = 1;
    end
end

always
  #10 clk = ~clk;

endmodule

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
    $readmemb("./Files/input\ samples/ram_input_contents_sample_9.txt", ram);

end

always @ (posedge clk)
begin
    addr_reg <= addr;
end

assign q = ram[addr_reg];

endmodule
