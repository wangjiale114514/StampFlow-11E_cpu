//处理alu指令
//处理执行要做的几步：
//1.每次只能找一个命令进行处理，不能多命令
//2.先获取哪些命令能运行，然后知道运行啥命令，比如运行加法，首先把命令中要运行的寄存器里面的内容读取出来rs和rt的内容
//然后把他存在next_pc所指的next_data的相对应位置，一次计算到next_data_c，然后给命令单位传一个已执行的章然后点一下势能，然后再给命令传一个take也就是这三个数存在了哪里，再给take一个势能
//下一个时间清零。
//写回只要点一下写回的章然后按标记位取出标记的东西给寄存器组完成写回
//最后需要写fpu，alu，mov的信号的take和stamp的势能信号和东西的汇总器 （也就是写回汇总）

module alu (
    input wire clk,                                   //时钟信号

    input wire [23:0] reg_start_flat,              //可运行指令列表  扁平
    input wire [703:0] reg_out_flat,              //指令列表  扁平
    
    output wire [23:0] stamp_flat,               //需要盖的章  扁平
    output reg [7:0] stamp_in,                 //盖章势能

    output wire [39:0] take_flat,                //写入alu需要取值的位置  扁平
    output reg [7:0] take_in,                  //写入势能

    //A位 (rs)
    output reg [4:0] reg_search_out3,        //A位_读取寄存器内容寻址
    input wire [31:0] reg_out3,             //A位_读取寄存器堆的输出内容

    //(rd)
    output reg [4:0] reg_search_in3,      //A位_写入寻址
    output reg [31:0] reg_in3,           //A位_写入内容
    output reg reg_in3_start,            //A位_写入势能 

    //B位(只需要输出) (rt)
    output reg [4:0] reg_search_out4,        //A位_读取寄存器内容寻址
    input wire [31:0] reg_out4             //A位_读取寄存器堆的输出内容

);  

    reg [4:0] next_pc;              //循环pc
    reg [31:0] next_data_rs [0:31];  //数据存储器rs
    reg [31:0] next_data_rt [0:31];  //数据存储器rt/立即数
    reg [31:0] next_data_rd [0:31];  //数据存储器rd
    integer i;                      //声明循环变量

    //扁平信号转换为列表
    reg [2:0] stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    reg [4:0] take [7:0];                    //写入alu需要取值的位置  扁平
    wire [2:0] reg_start [7:0];                //可运行指令列表 [a-h]按照顺序输出    扁平
    wire [87:0] reg_out [7:0];                 //各自输出 [a-h]                    扁平
    
    //stamp
    assign stamp_flat[2:0] = stamp[0];
    assign stamp_flat[5:3] = stamp[1];
    assign stamp_flat[8:6] = stamp[2];
    assign stamp_flat[11:9] = stamp[3];
    assign stamp_flat[14:12] = stamp[4];
    assign stamp_flat[17:15] = stamp[5];
    assign stamp_flat[20:18] = stamp[6];
    assign stamp_flat[23:21] = stamp[7];

    //take
    assign take_flat[4:0] = take[0]; 
    assign take_flat[9:5] = take[1];
    assign take_flat[14:10] = take[2];
    assign take_flat[19:15] = take[3];
    assign take_flat[24:20] = take[4];
    assign take_flat[29:25] = take[5];
    assign take_flat[34:30] = take[6];
    assign take_flat[39:35] = take[7];

    //reg_start
    assign reg_start[0] = reg_start_flat[2:0];
    assign reg_start[1] = reg_start_flat[5:3];
    assign reg_start[2] = reg_start_flat[8:6];
    assign reg_start[3] = reg_start_flat[11:9];
    assign reg_start[4] = reg_start_flat[14:12];
    assign reg_start[5] = reg_start_flat[17:15];
    assign reg_start[6] = reg_start_flat[20:18];
    assign reg_start[7] = reg_start_flat[23:21];

    //reg_out
    assign reg_out[0] = reg_out_flat[87:0];
    assign reg_out[1] = reg_out_flat[175:88];
    assign reg_out[2] = reg_out_flat[263:176];
    assign reg_out[3] = reg_out_flat[351:264];
    assign reg_out[4] = reg_out_flat[439:352];
    assign reg_out[5] = reg_out_flat[527:440];
    assign reg_out[6] = reg_out_flat[615:528];
    assign reg_out[7] = reg_out_flat[703:616];



    always @(posedge clk) begin
        next_pc <= next_pc + 1;                     //pc+1
    end

    always @(*) begin    //执行的处理逻辑
        take_in = 8'b00000000;
        stamp_in = 8'b00000000;
        reg_in3_start = 1'b0;         //寄存器写入势能清零

        for (i = 7; i > -1; i = i - 1) begin    //寻找最前端的命令遵循老人优先原则
            if (reg_start[i] == 3'b100) begin
                case (reg_out[i][87:82])

                    //1. 算术运算指令
                    6'b000000: begin                          //000000 ADD rs, rt, rd    //加法
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] + next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b000001: begin                          //000001 SUB rs, rt, rd    //减法
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] - next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end
                    
                    6'b000010: begin                          //000010 AND rd, rs, rt    //按位与运算
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] & next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b000011: begin                          //000011 R  rd, rs, rt     //按位或运算
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] | next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b000100: begin                          //000100 XOR rd, rs, rt    //按位异或运算
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] ^ next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b000101: begin                          //000101 SLT rd, rs, rt    //小于置位
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        if (next_data_rs[next_pc] < next_data_rt[next_pc]) begin         //给rd赋值
                            next_data_rd[next_pc] = 32'b11111111111111111111111111111111;
                        end
                        else begin
                            next_data_rd[next_pc] = 32'b00000000000000000000000000000000;
                        end

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    //2.立即数指令
                    6'b000110: begin                        //000110 ADDI rs, rd, imm    //立即数加法
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        next_data_rt[next_pc] = reg_out[i][66:35];                       //给rt赋值立即数

                        next_data_rd[next_pc] = next_data_rs[next_pc] + next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b000111: begin                        //000111 ANDI rt, rs, imm    //立即数与
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        next_data_rt[next_pc] = reg_out[i][66:35];                       //给rt赋值立即数

                        next_data_rd[next_pc] = next_data_rs[next_pc] & next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b001000: begin                        //001000 ORI  rt, rs, imm    //立即数或
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        next_data_rt[next_pc] = reg_out[i][66:35];                       //给rt赋值立即数

                        next_data_rd[next_pc] = next_data_rs[next_pc] | next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    //6. 移位指令
                    6'b010110: begin                       //010110 SLL  rd, rt, sa      //逻辑左移
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] << next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b010111: begin                       //010111 SRL  rd, rt, sa      //逻辑右移
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] >> next_data_rt[next_pc];   //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b011000: begin                       //011000 SRA  rd, rt, sa      //算术右移
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] >>> next_data_rt[next_pc];  //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b011001: begin                       //011001 CNM  rd, rt, sa      //算数左移
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] <<< next_data_rt[next_pc];  //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    //8. 乘除指令
                    6'b011110: begin                   //011110 MULT rs, rt, rd          //乘法
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] * next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                    6'b011111: begin                   //011111 DIV  rs, rt, rd          //除法
                        reg_search_out3 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out3;

                        reg_search_out4 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out4;

                        next_data_rd[next_pc] = next_data_rs[next_pc] / next_data_rt[next_pc];    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        break;                                 //退出循环下一个周期再处理
                    end

                endcase
            end
        end

        for (i = 7; i > -1; i = i - 1) begin    //老人优先
            if (reg_start[i] == 3'b001) begin
                case (reg_out[i][87:82])        //查看具体情况
                    //1.算数运算指令
                    6'b000000: begin    //000000 ADD rs, rt, rd       //加法
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b000001: begin    //000001 SUB rs, rt, rd       //减法
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b000010: begin    //000010 AND rd, rs, rt       //按位与运算
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b000011: begin    //000011 R  rd, rs, rt        //按位或运算*
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b000100: begin    //000100 XOR rd, rs, rt       //按位异或运算
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b000101: begin    //000101 SLT rd, rs, rt       //小于置位*
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    //2.立即数命令
                    6'b000110: begin    //000110 ADDI rt, rs, imm     //立即数加法
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b000111: begin    //000111 ANDI rt, rs, imm     //立即数与
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b001000: begin    //001000 ORI  rt, rs, imm     //立即数或
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    //6.移位指令
                    6'b010110: begin    //010110 SLL  rd, rt, sa      //逻辑左移
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b010111: begin    //010111 SRL  rd, rt, sa      //逻辑右移
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b011000: begin    //011000 SRA  rd, rt, sa      //算术右移
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b011001: begin    //011001 CNM  rd, rt, sa      //算数左移
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    //8.乘法命令
                    6'b011110: begin    //011110 MULT rs, rt, rd      //乘法
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end

                    6'b011111: begin    //011111 DIV  rs, rt, rd      //除法
                        reg_search_in3 = reg_out[i][71:67];           //输入寻址
                        reg_in3 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in3_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        break;                                     //退出循环下一个周期再处理
                    end 
                endcase
            end
        end
    end

//    always @(*) begin                                       //处理写回
//        stamp_in = 8'b00000000;       //势能清零
//        reg_in3_start = 1'b0;         //寄存器写入势能清零
//       
//    end
endmodule

//alu该处理的指令：
//1. 算术运算指令
//000000 ADD rs, rt, rd    //加法**
//000001 SUB rs, rt, rd    //减法**
//000010 AND rd, rs, rt    //按位与运算**
//000011 R  rd, rs, rt     //按位或运算**
//000100 XOR rd, rs, rt    //按位异或运算**
//000101 SLT rd, rs, rt    //小于置位**

//2. 立即数指令
//000110 ADDI rt, rs, imm    //立即数加法**
//000111 ANDI rt, rs, imm    //立即数与**
//001000 ORI  rt, rs, imm    //立即数或**

//6. 移位指令
//010110 SLL  rd, rt, sa      //逻辑左移**
//010111 SRL  rd, rt, sa      //逻辑右移**
//011000 SRA  rd, rt, sa      //算术右移**
//011001 CNM  rd, rt, sa      //算数左移**

//8. 乘除指令
//011110 MULT rs, rt, rd          //乘法**
//011111 DIV  rs, rt, rd          //除法**