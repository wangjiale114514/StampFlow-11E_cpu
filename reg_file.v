//寄存器堆

module reg_file (
    input wire clk,    //时钟

    input wire [31:0] reg_in1,          //寄存器写入内容
    input wire [31:0] reg_in2,         //mov
    input wire [31:0] reg_in3,        //alu_a
                                     //alu_b
    input wire [31:0] reg_in5,      //jump_a
                                   //jump_b
                                   //jump_c
    input wire [31:0] reg_in8,     //fpu_a
                                   //fpu_b
    input wire [31:0] reg_in10,    //imm_a
                                   //imm_b
                                     
    input wire [4:0] reg_search_in1,     //寄存器写入寻址
    input wire [4:0] reg_search_in2,    //mov
    input wire [4:0] reg_search_in3,   //alu_a
                                      //alu_b
    input wire [4:0] reg_search_in5, //jump_a
                                    //jump_b
                                    //jump_c
    input wire [4:0] reg_search_in8,//fpu_a
                                    //fpu_b
    input wire [4:0] reg_search_in10,//imm_a
                                     //imm_b

    input wire reg_in1_start,             //写入势能
    input wire reg_in2_start,            //mov
    input wire reg_in3_start,           //alu_a
                                       //alu_b
    input wire reg_in5_start,         //jump_a
                                     //jump_b
                                     //jump_c
    input wire reg_in8_start,        //fpu_a
                                     //fpu_b
    input wire reg_in10_start,       //imm_a
                                     //imm_b

    input wire [4:0] reg_search_out1,    //寄存器输出寻址
    input wire [4:0] reg_search_out2,   //mov
    input wire [4:0] reg_search_out3,  //alu_a
    input wire [4:0] reg_search_out4, //alu_b
    input wire [4:0] reg_search_out5, //jump_a
    input wire [4:0] reg_search_out6, //jump_b
    input wire [4:0] reg_search_out7, //jump_c
    input wire [4:0] reg_search_out8, //fpu_a
    input wire [4:0] reg_search_out9, //fpu_b
    input wire [4:0] reg_search_out10,//imm_a
    input wire [4:0] reg_search_out11,//imm_b

    output reg [31:0] reg_out1,          //寄存器输出
    output reg [31:0] reg_out2,         //mov
    output reg [31:0] reg_out3,        //alu_a
    output reg [31:0] reg_out4,       //alu_b
    output reg [31:0] reg_out5,      //jump_a
    output reg [31:0] reg_out6,      //jump_a
    output reg [31:0] reg_out7,      //jump_c
    output reg [31:0] reg_out8,       //fpu_a
    output reg [31:0] reg_out9,       //fpu_b
    output reg [31:0] reg_out10,       //imm_a
    output reg [31:0] reg_out11        //imm_b

);
    reg [31:0] reg_array [0:31];      //寄存器堆

    always @(posedge clk) begin    //输入赋值逻辑
        if (reg_in1_start) begin
            reg_array[reg_search_in1] <= reg_in1;
        end

        if (reg_in2_start) begin
            reg_array[reg_search_in2] <= reg_in2;
        end

        if (reg_in3_start) begin
            reg_array[reg_search_in3] <= reg_in3;
        end

//      if (reg_in4_start) begin
//          reg_array[reg_search_in4] <= reg_in4;
//      end

        if (reg_in5_start) begin
            reg_array[reg_search_in5] <= reg_in5;
        end

//      if (reg_in6_start) begin
//          reg_array[reg_search_in6] <= reg_in6;
//      end

//      if (reg_in7_start) begin
//          reg_array[reg_search_in7] <= reg_in7;
//      end

        if (reg_in8_start) begin
            reg_array[reg_search_in8] <= reg_in8;
        end

      if (reg_in9_start) begin
          reg_array[reg_search_in9] <= reg_in9;
      end

        if (reg_in10_start) begin
            reg_array[reg_search_in9] <= reg_in10;
        end

//      if (reg_in11_start) begin
//          reg_array[reg_search_in11] <= reg_in11;
//      end

    end

    always @(*) begin    //输出赋值逻辑
        reg_out1 <= reg_array[reg_search_out1];
        reg_out2 <= reg_array[reg_search_out2];
        reg_out3 <= reg_array[reg_search_out3];
        reg_out4 <= reg_array[reg_search_out4];
        reg_out5 <= reg_array[reg_search_out5];
        reg_out6 <= reg_array[reg_search_out6];
        reg_out7 <= reg_array[reg_search_out7];
        reg_out8 <= reg_array[reg_search_out8];
        reg_out9 <= reg_array[reg_search_out9];
        reg_out10 <= reg_array[reg_search_out10];
        reg_out11 <= reg_array[reg_search_out11];
    end
endmodule