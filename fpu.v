//fpu浮点数运算单元

`include "float.v"
module fpu (
    input wire clk,                                   //时钟信号

    input wire [23:0] reg_start_flat,              //可运行指令列表  扁平
    input wire [703:0] reg_out_flat,              //指令列表  扁平
    
    output wire [23:0] stamp_flat,               //需要盖的章  扁平
    output reg [7:0] stamp_in,                 //盖章势能

    output wire [39:0] take_flat,                //写入alu需要取值的位置  扁平
    output reg [7:0] take_in,                  //写入势能

    //A位 (rs)
    output reg [4:0] reg_search_out8,        //A位_读取寄存器内容寻址
    input wire [31:0] reg_out8,             //A位_读取寄存器堆的输出内容

    //(rd)
    output reg [4:0] reg_search_in8,      //A位_写入寻址
    output reg [31:0] reg_in8,           //A位_写入内容
    output reg reg_in8_start,            //A位_写入势能 

    //B位(只需要输出) (rt)
    output reg [4:0] reg_search_out9,        //A位_读取寄存器内容寻址
    input wire [31:0] reg_out9             //A位_读取寄存器堆的输出内容
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

    //实例化浮点数运算库
    wire [3:0] op;
    wire [31:0] a;
    wire [31:0] b;
    wire [31:0] c;
    
    float u_float (
        .o(op),    //操作码
        .a(a),     //操作数a
        .b(b),     //操作数b
        .c(c)      //结果位
    );

    reg [3:0] float_op;    //重新定义操作数
    reg [31:0] float_a;
    reg [31:0] float_b;
    wire [31:0] float_c;

    assign op = float_op;  //建立连接
    assign a = float_a;
    assign b = float_b;
    assign float_c = c;

    //浮点数处理库
    //测试用
    //0001加法
    //0010乘法
    //0011除法
    //0100整数转浮点数
    //0101浮点数转整数
    //0110判断大于
    //0111判断小于
    //1000判断不等于
    //1001判断等于

    always @(posedge clk) begin
        next_pc = next_pc + 1;                     //pc+1
    end
    always @(*) begin        //执行的处理逻辑
        take_in = 8'b00000000;    //take复位
        stamp_in = 8'b00000000;   //stamp复位
        reg_in8_start = 1'b0;     //寄存器写入势能清零

        begin : fpu_ex
        for (i = 7; i > -1; i = i - 1) begin    //寻找最前端的命令遵循老人优先原则
            if (reg_start[i] == 3'b100) begin
                case (reg_out[i][87:82])

                   6'b100000: begin                          //100000 FADD rs, rt, rd    //加法
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0001;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rt[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b100001: begin                    //100001 FSUB rs, rt, rd         //减法
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0001;                                                 //操作码
                        float_a = next_data_rs[next_pc];                                    //操作数a
                        float_b = {~next_data_rt[next_pc][31],next_data_rt[next_pc][30:0]}; //操作数b(符号位取反代表减法)

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b100010: begin                    //100010 FMULT rs,rt, rd         //乘法
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0010;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rt[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b100011: begin                    //100011 FDIV rs, rt, rd         //除法
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0011;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rt[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end
                    
                    6'b100100: begin                    //100100 FUCK rs，rt, rd         //比较>
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0110;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rt[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b100101: begin                    //100101 FKCU rs, rt, rd         //比较<（比较结果会存到rd寄存器(全部为1，否则为0)
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0111;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rt[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b100110: begin                    //100110 FKCK rs, rt, sa         //比较=
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b1001;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rt[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b100111: begin                    //100111 FKNK rs, rt, sa         //比较不等于
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b1000;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rt[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b101000: begin                    //101000 FAND rs, rt, rd         //平方运算
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0010;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rs[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b101110: begin                    //101110 FTI rs rd               //浮点数转整数
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0101;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rs[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end

                    6'b101111: begin                    //101111 ITF rs rd               //整数转浮点数
                        reg_search_out8 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out8;

                        reg_search_out9 = reg_out[i][76:72];                             //给rt赋值
                        next_data_rt[next_pc] = reg_out9;

                        float_op = 4'b0100;              //操作码
                        float_a = next_data_rs[next_pc]; //操作数a
                        float_b = next_data_rs[next_pc]; //操作数b

                        next_data_rd[next_pc] = float_c;    //给rd赋值

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable fpu_ex;                                 //退出循环下一个周期再处理
                    end
                endcase
            end
        end
        end
        
        begin : fpu_wb
        for (i = 7; i > -1; i = i - 1) begin    //老人优先原则
            if (reg_start[i] == 3'b001) begin
                case (reg_out[i][87:82])        //查看具体情况

                    6'b100000: begin    //100000 FADD rs, rt, rd      //加法
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b100001: begin    //100001 FSUB rs, rt, rd      //减法
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b100010: begin //100010 FMULT rs,rt, rd         //乘法
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b100011: begin //100011 FDIV rs, rt, rd         //除法
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b100100: begin //100100 FUCK rs，rt, rd         //比较>
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b100101: begin //100101 FKCU rs, rt, rd         //比较<（比较结果会存到rd寄存器(全部为1，否则为0)
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b100110: begin //100110 FKCK rs, rt, sa         //比较=
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b100111: begin //100111 FKNK rs, rt, sa         //比较不等于
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b101000: begin //101000 FAND rs, rt, rd         //平方运算
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b101110: begin //101110 FTI rs rd               //浮点数转整数
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end

                    6'b101111: begin //101111 ITF rs rd               //整数转浮点数
                        reg_search_in8 = reg_out[i][71:67];           //输入寻址
                        reg_in8 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
                        reg_in8_start = 1'b1;                         //点一下寄存器写入势能

                        stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                        stamp[i][0] = 1'b1;                        //表示已经执行了
                        stamp_in [i] = 1'b1;                       //点一下势能
                        disable fpu_wb;                                     //退出循环下一个周期再处理
                    end
                endcase
            end
        end
        end
        
    end

 //   always @(*) begin                                       //处理写回
 //       stamp_in = 8'b00000000;       //势能清零
 //       reg_in8_start = 1'b0;         //寄存器写入势能清零
 //   end
endmodule

//9.浮点数运算单元
//100000 FADD rs, rt, rd          //加法**
//100001 FSUB rs, rt, rd         //减法**
//100010 FMULT rs,rt, rd         //乘法**
//100011 FDIV rs, rt, rd         //除法**
//100100 FUCK rs，rt, rd         //比较>**
//100101 FKCU rs, rt, rd         //比较<（比较结果会存到rd寄存器(全部为1，否则为0)**
//100110 FKCK rs, rt, sa         //比较=**
//100111 FKNK rs, rt, sa         //比较不等于**
//101000 FAND rs, rt, rd         //平方运算**
//101001 FSAD rs, rd             //开平方根*//

//101110 FTI rs rd               //浮点数转整数**
//101111 ITF rs rd               //整数转浮点数**
