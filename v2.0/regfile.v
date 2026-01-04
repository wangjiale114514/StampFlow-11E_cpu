//reg file 255个,最高8位1
//每个周期会输出四个现空表
//写入根据顺序写入现空表（取指顺序）
//不要直接压实排序，直接写入四个对应的空表即可
//写入的RAT表要有前后的优先级

module regfile (
    input wire clk,    //时钟
    input wire reset,  //复位

    //来自id(RAT)
    output reg [255:0] rat_file,    //RAT out
    //输入更改RAT
    output reg [31:0] rat_now_null, //RAT现空表
    input wire [19:0] rat_wire,     //RAT更新内容
    input wire [3:0] rat_wire_en,   //RAT写入势能

    //来自ROB的退休
    
    //来自bp错误清空流水线
    input wire bp_reset
);

    //定义循环变量
    integer i;
    integer d;
    integer g; 

    //reg file
    reg [63:0] reg_file [0:256];    //regfile
    reg rob_out [0:256];            //退休标签（只有被更改退休之后的reg才能重新分配）(1为未退休)（开头被分配写入的时候）
    reg rat_out [0:256];            //在不在rat内，（1为在rat内）

    //RAT
    reg [7:0] rat_pc;    //RAT指针（搜寻空闲空间）
    //输出映射
    reg [7:0] rat [0:31];
    assign rat_file[7:0] = rat[0];
    assign rat_file[15:8] = rat[1];
    assign rat_file[23:16] = rat[2];
    assign rat_file[31:24] = rat[3];
    assign rat_file[39:32] = rat[4];
    assign rat_file[47:40] = rat[5];
    assign rat_file[55:48] = rat[6];
    assign rat_file[63:56] = rat[7];
    assign rat_file[71:64] = rat[8];
    assign rat_file[79:72] = rat[9];
    assign rat_file[87:80] = rat[10];
    assign rat_file[95:88] = rat[11];
    assign rat_file[103:96] = rat[12];
    assign rat_file[111:104] = rat[13];
    assign rat_file[119:112] = rat[14];
    assign rat_file[127:120] = rat[15];
    assign rat_file[135:128] = rat[16];
    assign rat_file[143:136] = rat[17];
    assign rat_file[151:144] = rat[18];
    assign rat_file[159:152] = rat[19];
    assign rat_file[167:160] = rat[20];
    assign rat_file[175:168] = rat[21];
    assign rat_file[183:176] = rat[22];
    assign rat_file[191:184] = rat[23];
    assign rat_file[199:192] = rat[24];
    assign rat_file[207:200] = rat[25];
    assign rat_file[215:208] = rat[26];
    assign rat_file[223:216] = rat[27];
    assign rat_file[231:224] = rat[28];
    assign rat_file[239:232] = rat[29];
    assign rat_file[247:240] = rat[30];
    assign rat_file[255:248] = rat[31];

    //RAT标签更新
    always @(*) begin
        for (i = 0; i < 256; i = i + 1) begin
            for (g = 0; g < 32; g = g + 1) begin
                if (rat[g] == i) begin
                    rat_out[i] <= 1'b1;    //在重命名表中
                end
                else begin
                    rat_out[i] <= 1'b0;    //不在重命名表中
                end
            end
        end
    end
    
    
endmodule