module snn_core(start, clk, rst_n, q_input, addr_input_unit, digit, done);

typedef enum reg[2:0] {IDLE, MAC1, MAC2, MAX, DONE} state;
state curr_state, next_state;

output logic [9:0] addr_input_unit;
output logic [3:0] digit;
output logic done;

input logic clk, start, rst_n;
input logic q_input;
logic we;
logic [14:0] hidden_weight_addr;
logic [7:0] q_extended, hidden_weight_q;
logic [7:0] a, b, lut_out, ram_hidden_data, output_weight_q, digit_prob;
logic [25:0] acc;
logic clr_n;
logic [10:0] addr_LUT;
logic [4:0] addr_ram_hidden;
logic [8:0] output_weight_addr;
logic [3:0] output_unit_addr;
logic [2:0] output_digit, digit_count;
logic select_input, increment_input, increment_output;

rom_hidden_weight hidden_weight(.addr(hidden_weight_addr), .clk(clk), .q(hidden_weight_q));
rom_output_weight output_weight(.addr(output_weight_addr), .clk(clk), .q(output_weight_q));
ram_hidden_unit hidden_unit(.data(lut_out), .addr(addr_ram_hidden), .clk(clk), .we(we), .q(ram_hidden_data));
rom_act_func_lut act_func_lut(.addr(addr_LUT + 11'h400), .clk(clk), .q(lut_out));
mac mac(.clk(clk), .a(a), .b(b), .acc(acc), .clr_n(clr_n), .rst_n(rst_n));
ram_output_unit output_unit(.data(lut_out), .addr(output_unit_addr), .clk(clk), .we(~we), .q(digit_prob));

assign q_extended = (q_input) ? 8'h7F : 8'h0;

assign hidden_weight_addr_max = hidden_weight_addr == 25087 ? 1 : 0;
assign addr_input_unit_max = addr_input_unit == 783 ? 1 : 0;
assign addr_ram_hidden_max = addr_ram_hidden == 31 ? 1 : 0;
assign output_weight_addr_max = output_weight_addr == 319 ? 1 : 0;
assign digit_max = digit_count == 9 ? 1 : 0;

always_ff @(posedge clk) begin
if(acc[25]==0 && |acc[24:17] == 1)
  addr_LUT = 11'h3ff;
else if(acc[25]==1 && &acc[24:17] == 0)
  addr_LUT = 11'h400;
else
  addr_LUT = acc[17:7];
end

assign a = select_input ? ram_hidden_data : q_extended;
assign b = select_input ? output_weight_q : hidden_weight_q;

assign max_prob = max_prob > digit_prob ? max_prob : digit_prob;
assign digit = max_prob > digit_prob ? digit : digit_count;

assign digit_count = (digit_max) ? 0 : digit_count + 1;

// FSM
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) begin
        curr_state <= IDLE;
      end
    else
        curr_state <= next_state;  

always_comb begin
  //default values
  select_input = 0;
  increment_input = 0;
  increment_output = 0;
  done = 0;
  clr_n = 0;
  we = 1;
  next_state = IDLE;

  case (curr_state)
    IDLE:
      if (start) begin					//start bit detected
        next_state = MAC1;
      end

    MAC1:
      if (hidden_weight_addr_max)	begin //at middle of start bit
        next_state = MAC2;
      end			
      else begin
        clr_n = 1;
        increment_input = 1;
        next_state = MAC1;
      end

    MAC2: begin
      we = 0;
      if (output_weight_addr_max) begin	//middle of a bit which isn't the stop bit
        next_state = MAX;
      end
      else begin
        increment_output = 1;
        next_state = MAC2;
      end
      select_input = 1;
      end

    MAX: begin
      if (digit_max) begin
        done = 1;
        next_state = DONE;
      end
      else begin
        next_state = MAX;
      end
      end

    DONE: next_state = IDLE;

    endcase
  end

//address input unit counter
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        addr_input_unit <= 4'b0;
    else
        if (addr_input_unit_max)
            addr_input_unit <= 4'b0;
        else
          if (increment_input)
            addr_input_unit <= addr_input_unit+1;

//hidden weight address counter
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        hidden_weight_addr <= 4'b0;
    else
        if (hidden_weight_addr_max)
          hidden_weight_addr <= 4'b0;
        else
          if (increment_input)
            hidden_weight_addr <= hidden_weight_addr+1;

//address ram hidden counter
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        addr_ram_hidden <= 4'b0;
    else
        if (addr_ram_hidden_max)
            addr_ram_hidden <= 4'b0;
        else
          if (increment_output)
            addr_ram_hidden <= addr_ram_hidden+1;

//output weight address counter
always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
        output_weight_addr <= 4'b0;
    else
        if (output_weight_addr_max)
            output_weight_addr <= 4'b0;
        else
          if (increment_output)
            output_weight_addr <= output_weight_addr+1;


endmodule
