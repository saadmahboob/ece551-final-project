module snn_core(start, clk, rst_n, q_input, addr_input_unit, digit, done);

  typedef enum reg[1:0] {IDLE, MAC1, MAC2, DONE} state;
  state curr_state, next_state;

  output logic [9:0] addr_input_unit;
  output logic [3:0] digit;
  output logic done;

  input logic clk, start, rst_n;
  input logic q_input;

  logic select_input, inc_input_addr, increment_output, write_hidden;
  logic mac_clr_n, output_clr, hidden_clr, addr_input_unit_clr, digit_clr;

  logic [7:0]   q_extended;
  logic [7:0]   ram_hidden_data;
  logic [5:0]   cnt_hidden;
  logic [7:0]   hidden_weight_q;

  //MAC stuff
  logic [7:0]   a, b, lut_out;
  logic [25:0]  acc;
  logic [10:0]  addr_LUT;

  //Max stuff
  logic [7:0]   output_weight_q, max_prob;
  logic check_max;
  logic [3:0]   digit_reg;
  logic [3:0]   cnt_output;

  rom_hidden_weight    hidden_weight(.addr({cnt_hidden[4:0], addr_input_unit[9:0]}), .clk(clk), .q(hidden_weight_q));
  rom_output_weight    output_weight(.addr({cnt_output[3:0], cnt_hidden[4:0]}), .clk(clk), .q(output_weight_q));
  ram_hidden_unit      hidden_unit(.data(lut_out), .addr(cnt_hidden [4:0]), .clk(clk), .we(write_hidden), .q(ram_hidden_data));
  rom_act_func_lut     act_func_lut(.addr(addr_LUT + 11'h400), .clk(clk), .q(lut_out));
  mac                  mac(.clk(clk), .a(a), .b(b), .acc(acc), .clr_n(mac_clr_n), .rst_n(rst_n), .addr_LUT(addr_LUT));

  assign q_extended = (q_input) ? 8'h7F : 8'h00;

  //MAC 1
  assign addr_input_unit_max = addr_input_unit == 10'h306 ? 1 : 0;
  assign cnt_hidden_max = cnt_hidden == 6'h20 ? 1 : 0;

  //MAC 2
  assign cnt_output_max =  (select_input) ? ((cnt_output == 4'ha) ? 1 : 0) : 0;
  assign cnt_hidden_max_out = cnt_hidden == 6'h22 ? 1 : 0;

  assign a = select_input ? ram_hidden_data : q_extended;
  assign b = select_input ? output_weight_q : hidden_weight_q;


 always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    max_prob <= 8'h00;
  else 
    if (digit_clr)
      max_prob <= 8'h00;
    else if (check_max)
      if (lut_out > max_prob)
        max_prob <= lut_out;

  always_ff @(posedge clk, negedge rst_n)
   if (!rst_n)
     digit <= 0;
  else
    if (digit_clr)
      digit <= 0;
    else if (check_max)
      if (lut_out > max_prob)
       digit <= digit_reg;

  // FSM
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      curr_state <= IDLE;
    else
      curr_state <= next_state;

  always_comb begin
    //default values
    select_input = 0;
    inc_input_addr = 0;
    increment_output = 0;
    done = 0;
    mac_clr_n = 0;
    output_clr = 0;
    hidden_clr = 0;
    addr_input_unit_clr = 0;
    digit_clr = 0;
    check_max = 0;
    next_state = IDLE;
    write_hidden = 0;
    addr_input_unit_clr = 0;

    case (curr_state)
      IDLE:
        if (start) begin    					//start bit detected
          next_state = MAC1;
          digit_clr = 1;
          addr_input_unit_clr = 1;
        end

      MAC1: begin
        output_clr = 1;
        if (!addr_input_unit_max)
          mac_clr_n = 1;
        else
          write_hidden = 1;

        if (cnt_hidden_max)	begin
          hidden_clr = 1;
          next_state = MAC2;
        end
        else begin
          inc_input_addr = 1;
          next_state = MAC1;
        end
      end

      MAC2: begin
        select_input = 1;

        if (digit_reg == 4'ha)
            next_state = DONE;
        else begin
          addr_input_unit_clr = 1;
          increment_output = 1;
          next_state = MAC2;
        end

        if (cnt_hidden == 0)
            mac_clr_n = 0;
        else if (!cnt_hidden_max_out)
            mac_clr_n = 1;
        else
          check_max = 1;
      end

      DONE: begin
        check_max = 0;
        done = 1;
        next_state = IDLE;
      end

      default:
        next_state = IDLE;

    endcase
  end

  //address input unit counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      addr_input_unit <= 10'h00;
    else
      if (addr_input_unit_clr)
        addr_input_unit <= 10'h22;
      else if (addr_input_unit_max)
        addr_input_unit <= 10'h0;
      else
        if (inc_input_addr)
          addr_input_unit <= addr_input_unit + 1;

  //hidden weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_hidden <= 6'b0;
    else
      if (hidden_clr)
        cnt_hidden <= 6'b0;
      else if (cnt_hidden_max_out)
        cnt_hidden <=6'b0;
      else if (addr_input_unit_max)
        cnt_hidden <= cnt_hidden + 1;
      else if (increment_output)
        cnt_hidden <= cnt_hidden + 1;

  //output weight address counter
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      cnt_output <= 4'h0;
    else
      if (output_clr)
        cnt_output <= 4'h0;
      else
        if (cnt_hidden_max)
          cnt_output <= cnt_output + 1;

  //digit of max prob needs to be one clock cycle behind input address
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      digit_reg <= 4'h0;
    else
      if (digit_clr)
        digit_reg <= 4'h0;
      else
        if (check_max)
          digit_reg <= digit_reg + 1;

endmodule
