//处理mov指令以及加载高位立即数

module mov (
    input wire clk,                                   //时钟信号

    input wire [23:0] reg_start_flat,              //可运行指令列表  扁平
    input wire [703:0] reg_out_flat,              //指令列表  扁平
    
    output wire [23:0] stamp_flat,               //需要盖的章  扁平
    output reg [7:0] stamp_in,                 //盖章势能

    output wire [39:0] take_flat,                //写入alu需要取值的位置  扁平
    output reg [7:0] take_in,                  //写入势能


    output reg [4:0] reg_search_out2,        //读取寄存器内容寻址
    input wire [31:0] reg_out2,             //读取寄存器堆的输出内容

    output reg [4:0] reg_search_in2,      //写入寻址
    output reg [31:0] reg_in2,           //写入内容
    output reg reg_in2_start            //写入势能 
);  
    reg [4:0] next_pc;           //循环pc
    reg [31:0] next_data [31:0];  //数据存储器
    integer i;                    //声明循环变量

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
        next_pc = next_pc + 1;                     //pc+1
    end

    
    always @(*) begin                    //执行的处理逻辑
        take_in = 8'b00000000;
        stamp_in = 8'b00000000;
        reg_in2_start = 1'b0;         //寄存器写入势能清零

        for (i = 7; i > -1; i = i - 1) begin         //寻找最前端的命令遵循老人优先原则
            if ((reg_start[i] == 3'b100) && (reg_out[i][87:82] == 6'b101010)) begin        //符合的mov指令
                reg_search_out2 = reg_out[i][81:77];
                next_data[next_pc] = reg_out2;              //给寄存器赋值

                take[i] = next_pc;                        //处理写回的存储地址
                take_in[i] = 1'b1;                           //点一下势能

                stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                stamp[i][2] = 1'b1;                      //表示已经执行了
                stamp_in [i] = 1'b1;                    //点一下势能

                break;                                 //退出循环下一个周期再处理
            end
            else begin
                if ((reg_start[i] == 3'b100) && (reg_out[i][87:82] == 6'b101100)) begin    ////101100 NOT rs rd      //取反
                    reg_search_out2 = reg_out[i][81:77];
                    next_data[next_pc] = ~reg_out2;              //给寄存器赋值

                    take[i] = next_pc;                        //处理写回的存储地址
                    take_in[i] = 1'b1;                           //点一下势能

                    stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                    stamp[i][2] = 1'b1;                      //表示已经执行了
                    stamp_in [i] = 1'b1;                    //点一下势能

                    break;                                 //退出循环下一个周期再处理
                end
            end
        end

        for (i = 7; i > -1; i = i - 1) begin
        if ((reg_start[i] == 3'b001) && (reg_out[i][87:82] == 6'b101010)) begin    //101010 MOV rs rd           //移动
            reg_search_in2 = reg_out[i][71:67];        //输入寻址
            reg_in2 = next_data[reg_out[i][34:30]];    //给寄存器写回数值
            reg_in2_start = 1'b1;                      //点一下寄存器写入势能
            
            stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
            stamp[i][0] = 1'b1;                        //表示已经执行了
            stamp_in [i] = 1'b1;                       //点一下势能

            break;                                     //退出循环下一个周期再处理
        end
        else begin
            if ((reg_start[i] == 3'b001) && (reg_out[i][87:82] == 6'b001001)) begin    //001001 LUI  rt, imm        //加载高位立即数
                reg_search_in2 = reg_out[i][71:67];        //输入寻址
                reg_in2 = reg_out[i][66:35];               //给寄存器写回数值
                reg_in2_start = 1'b1;                      //点一下寄存器写入势能

                stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                stamp[i][0] = 1'b1;                        //表示已经执行了
                stamp_in [i] = 1'b1;                       //点一下势能

                break;                                     //退出循环下一个周期再处理
            end
            else begin
                if ((reg_start[i] == 3'b001) && (reg_out[i][87:82] == 6'b101100)) begin    //101100 NOT rs rd           //取反
                    reg_search_in2 = reg_out[i][71:67];        //输入寻址
                    reg_in2 = next_data[reg_out[i][34:30]];    //给寄存器写回数值
                    reg_in2_start = 1'b1;                      //点一下寄存器写入势能

                    stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
                    stamp[i][0] = 1'b1;                        //表示已经执行了
                    stamp_in [i] = 1'b1;                       //点一下势能

                    break;                                     //退出循环下一个周期再处理
                end
            end
        end
    end
    end

//    always @(*) begin    //处理写回逻辑
//    stamp_in = 8'b00000000;       //势能清零
//    reg_in2_start = 1'b0;         //寄存器写入势能清零
//    end
endmodule

//001001 LUI  rt, imm        //加载高位立即数**
//101010 MOV rs rd           //移动**
//101100 NOT rs rd           //取反**