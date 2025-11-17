//汇集信号器
//汇集信号章,take写回内容

module pool (
    //输入
    //alu
    input wire reset,                                 //复位

    input wire [23:0] alu_stamp_flat,               //需要盖的章  扁平
    input wire [7:0] alu_stamp_in,                 //盖章势能

    input wire [39:0] alu_take_flat,                //写入alu需要取值的位置  扁平
    input wire [7:0] alu_take_in,                  //写入势能

    //fpu
    input wire [23:0] fpu_stamp_flat,               //需要盖的章  扁平
    input wire [7:0] fpu_stamp_in,                 //盖章势能

    input wire [39:0] fpu_take_flat,                //写入alu需要取值的位置  扁平
    input wire [7:0] fpu_take_in,                  //写入势能

    //imm
    input wire [23:0] imm_stamp_flat,               //需要盖的章  扁平
    input wire [7:0] imm_stamp_in,                 //盖章势能

    input wire [39:0] imm_take_flat,                //写入alu需要取值的位置  扁平
    input wire [7:0] imm_take_in,                  //写入势能

    //jump
    input wire [23:0] jump_stamp_flat,               //需要盖的章  扁平
    input wire [7:0] jump_stamp_in,                 //盖章势能

    input wire [39:0] jump_take_flat,                //写入alu需要取值的位置  扁平
    input wire [7:0] jump_take_in,                  //写入势能

    //mov
    input wire [23:0] mov_stamp_flat,               //需要盖的章  扁平
    input wire [7:0] mov_stamp_in,                 //盖章势能

    input wire [39:0] mov_take_flat,                //写入alu需要取值的位置  扁平
    input wire [7:0] mov_take_in,                  //写入势能

    //输出
    //conveyor
    output wire [23:0] conveyor_stamp_flat,               //8个寄存器章 [a-h]    扁平
    output reg [7:0] conveyor_stamp_in,                 //8个寄存器章势能 [a-h]

    output wire [39:0] conveyor_take_flat,               //写入alu需要取值的位置  扁平
    output reg [7:0] conveyor_take_in                    //写入势能
);
    
    //alu
    wire [2:0] alu_stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    wire [4:0] alu_take [7:0];                    //写入alu需要取值的位置  扁平

    //fpu
    wire [2:0] fpu_stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    wire [4:0] fpu_take [7:0];                    //写入alu需要取值的位置  扁平

    //imm
    wire [2:0] imm_stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    wire [4:0] imm_take [7:0];                    //写入alu需要取值的位置  扁平

    //jump
    wire [2:0] jump_stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    wire [4:0] jump_take [7:0];                    //写入alu需要取值的位置  扁平

    //mov
    wire [2:0] mov_stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    wire [4:0] mov_take [7:0];                    //写入alu需要取值的位置  扁平

    //conveyor
    reg [2:0] conveyor_stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    reg [4:0] conveyor_take [7:0];                    //写入alu需要取值的位置  扁平

    //分信号
    //alu
    assign alu_stamp[0] = alu_stamp_flat[2:0];            //stamp
    assign alu_stamp[1] = alu_stamp_flat[5:3];
    assign alu_stamp[2] = alu_stamp_flat[8:6];
    assign alu_stamp[3] = alu_stamp_flat[11:9];
    assign alu_stamp[4] = alu_stamp_flat[14:12];
    assign alu_stamp[5] = alu_stamp_flat[17:15];
    assign alu_stamp[6] = alu_stamp_flat[20:18];
    assign alu_stamp[7] = alu_stamp_flat[23:21];

    assign alu_take[0] = alu_take_flat[4:0];              //take
    assign alu_take[1] = alu_take_flat[9:5];
    assign alu_take[2] = alu_take_flat[14:10];
    assign alu_take[3] = alu_take_flat[19:15];
    assign alu_take[4] = alu_take_flat[24:20];
    assign alu_take[5] = alu_take_flat[29:25];
    assign alu_take[6] = alu_take_flat[34:30];
    assign alu_take[7] = alu_take_flat[39:35];

    //fpu
    assign fpu_stamp[0] = fpu_stamp_flat[2:0];            //stamp
    assign fpu_stamp[1] = fpu_stamp_flat[5:3];
    assign fpu_stamp[2] = fpu_stamp_flat[8:6];
    assign fpu_stamp[3] = fpu_stamp_flat[11:9];
    assign fpu_stamp[4] = fpu_stamp_flat[14:12];
    assign fpu_stamp[5] = fpu_stamp_flat[17:15];
    assign fpu_stamp[6] = fpu_stamp_flat[20:18];
    assign fpu_stamp[7] = fpu_stamp_flat[23:21];

    assign fpu_take[0] = fpu_take_flat[4:0];              //take
    assign fpu_take[1] = fpu_take_flat[9:5];
    assign fpu_take[2] = fpu_take_flat[14:10];
    assign fpu_take[3] = fpu_take_flat[19:15];
    assign fpu_take[4] = fpu_take_flat[24:20];
    assign fpu_take[5] = fpu_take_flat[29:25];
    assign fpu_take[6] = fpu_take_flat[34:30];
    assign fpu_take[7] = fpu_take_flat[39:35];

    //imm
    assign imm_stamp[0] = imm_stamp_flat[2:0];            //stamp
    assign imm_stamp[1] = imm_stamp_flat[5:3];
    assign imm_stamp[2] = imm_stamp_flat[8:6];
    assign imm_stamp[3] = imm_stamp_flat[11:9];
    assign imm_stamp[4] = imm_stamp_flat[14:12];
    assign imm_stamp[5] = imm_stamp_flat[17:15];
    assign imm_stamp[6] = imm_stamp_flat[20:18];
    assign imm_stamp[7] = imm_stamp_flat[23:21];

    assign imm_take[0] = imm_take_flat[4:0];              //take
    assign imm_take[1] = imm_take_flat[9:5];
    assign imm_take[2] = imm_take_flat[14:10];
    assign imm_take[3] = imm_take_flat[19:15];
    assign imm_take[4] = imm_take_flat[24:20];
    assign imm_take[5] = imm_take_flat[29:25];
    assign imm_take[6] = imm_take_flat[34:30];
    assign imm_take[7] = imm_take_flat[39:35];

    //jump
    assign jump_stamp[0] = jump_stamp_flat[2:0];            //stamp
    assign jump_stamp[1] = jump_stamp_flat[5:3];
    assign jump_stamp[2] = jump_stamp_flat[8:6];
    assign jump_stamp[3] = jump_stamp_flat[11:9];
    assign jump_stamp[4] = jump_stamp_flat[14:12];
    assign jump_stamp[5] = jump_stamp_flat[17:15];
    assign jump_stamp[6] = jump_stamp_flat[20:18];
    assign jump_stamp[7] = jump_stamp_flat[23:21];

    assign jump_take[0] = jump_take_flat[4:0];              //take
    assign jump_take[1] = jump_take_flat[9:5];
    assign jump_take[2] = jump_take_flat[14:10];
    assign jump_take[3] = jump_take_flat[19:15];
    assign jump_take[4] = jump_take_flat[24:20];
    assign jump_take[5] = jump_take_flat[29:25];
    assign jump_take[6] = jump_take_flat[34:30];
    assign jump_take[7] = jump_take_flat[39:35];

    //mov
    assign mov_stamp[0] = mov_stamp_flat[2:0];            //stamp
    assign mov_stamp[1] = mov_stamp_flat[5:3];
    assign mov_stamp[2] = mov_stamp_flat[8:6];
    assign mov_stamp[3] = mov_stamp_flat[11:9];
    assign mov_stamp[4] = mov_stamp_flat[14:12];
    assign mov_stamp[5] = mov_stamp_flat[17:15];
    assign mov_stamp[6] = mov_stamp_flat[20:18];
    assign mov_stamp[7] = mov_stamp_flat[23:21];

    assign mov_take[0] = mov_take_flat[4:0];              //take
    assign mov_take[1] = mov_take_flat[9:5];
    assign mov_take[2] = mov_take_flat[14:10];
    assign mov_take[3] = mov_take_flat[19:15];
    assign mov_take[4] = mov_take_flat[24:20];
    assign mov_take[5] = mov_take_flat[29:25];
    assign mov_take[6] = mov_take_flat[34:30];
    assign mov_take[7] = mov_take_flat[39:35];

    //conveyor
    assign conveyor_stamp_flat[2:0] = conveyor_stamp[0];                    //stamp
    assign conveyor_stamp_flat[5:3] = conveyor_stamp[1];
    assign conveyor_stamp_flat[8:6] = conveyor_stamp[2];
    assign conveyor_stamp_flat[11:9] = conveyor_stamp[3];
    assign conveyor_stamp_flat[14:12] = conveyor_stamp[4];
    assign conveyor_stamp_flat[17:15] = conveyor_stamp[5];
    assign conveyor_stamp_flat[20:18] = conveyor_stamp[6];
    assign conveyor_stamp_flat[23:21] = conveyor_stamp[7];

    assign conveyor_take_flat[4:0] = conveyor_take[0];                      //take
    assign conveyor_take_flat[9:5] = conveyor_take[1];
    assign conveyor_take_flat[14:10] = conveyor_take[2];
    assign conveyor_take_flat[19:15] = conveyor_take[3];
    assign conveyor_take_flat[24:20] = conveyor_take[4];
    assign conveyor_take_flat[29:25] = conveyor_take[5];
    assign conveyor_take_flat[34:30] = conveyor_take[6];
    assign conveyor_take_flat[39:35] = conveyor_take[7];

    integer i;                      //声明循环变量

    //仲裁得信号
    always @(*) begin
        if (reset) begin           //复位
            for (i = 7; i > -1; i = i - 1) begin
                conveyor_stamp[i] <= 3'b0; 
                conveyor_take[i] <= 5'b0;
            end

            conveyor_stamp_in <= 8'b0;
            conveyor_take_in <= 8'b0;
        end

        conveyor_take_in = 8'b00000000;        //初始化conveyor信号
        conveyor_stamp_in = 8'b00000000;

        for (i = 7; i > -1; i = i - 1) begin                    //alu
            if (alu_stamp_in[i] == 1'b1) begin                  //stamp
                conveyor_stamp[i] = alu_stamp[i];//赋值
                conveyor_stamp_in[i] = 1'b1;     //激活势能
            end
            if (alu_take_in[i] == 1'b1) begin                   //take
                conveyor_take[i] = alu_take[i];  //赋值
                conveyor_take_in[i] = alu_take_in[i];//激活势能
            end
        end

        for (i = 7; i > -1; i = i - 1) begin                    //fpu
            if (fpu_stamp_in[i] == 1'b1) begin                  //stamp
                conveyor_stamp[i] = fpu_stamp[i];//赋值
                conveyor_stamp_in[i] = 1'b1;     //激活势能
            end
            if (fpu_take_in[i] == 1'b1) begin                   //take
                conveyor_take[i] = fpu_take[i];  //赋值
                conveyor_take_in[i] = fpu_take_in[i];//激活势能
            end
        end

        for (i = 7; i > -1; i = i - 1) begin                    //imm
            if (imm_stamp_in[i] == 1'b1) begin                  //stamp
                conveyor_stamp[i] = imm_stamp[i];//赋值
                conveyor_stamp_in[i] = 1'b1;     //激活势能
            end
            if (imm_take_in[i] == 1'b1) begin                   //take
                conveyor_take[i] = imm_take[i];  //赋值
                conveyor_take_in[i] = imm_take_in[i];//激活势能
            end
        end

        for (i = 7; i > -1; i = i - 1) begin                    //jump
            if (jump_stamp_in[i] == 1'b1) begin                  //stamp
                conveyor_stamp[i] = jump_stamp[i];//赋值
                conveyor_stamp_in[i] = 1'b1;     //激活势能
            end
            if (jump_take_in[i] == 1'b1) begin                   //take
                conveyor_take[i] = jump_take[i];  //赋值
                conveyor_take_in[i] = jump_take_in[i];//激活势能
            end
        end

        for (i = 7; i > -1; i = i - 1) begin                    //mov
            if (mov_stamp_in[i] == 1'b1) begin                  //stamp
                conveyor_stamp[i] = mov_stamp[i];//赋值
                conveyor_stamp_in[i] = 1'b1;     //激活势能
            end
            if (jump_take_in[i] == 1'b1) begin                   //take
                conveyor_take[i] = mov_take[i];  //赋值
                conveyor_take_in[i] = mov_take_in[i];//激活势能
            end
        end
    end

endmodule