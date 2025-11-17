//访存操作
module imm (
    input wire clk,                                   //时钟信号
    input wire reset,                                 //复位

    input wire [23:0] reg_start_flat,              //可运行指令列表  扁平
    input wire [703:0] reg_out_flat,              //指令列表  扁平
    
    output wire [23:0] stamp_flat,               //需要盖的章  扁平
    output reg [7:0] stamp_in,                 //盖章势能

    output wire [39:0] take_flat,                //写入alu需要取值的位置  扁平
    output wire [7:0] take_in,                  //写入势能    //永远不用

    //A位 (rs)
    output reg [4:0] reg_search_out10,        //A位_读取寄存器内容寻址
    input wire [31:0] reg_out10,             //A位_读取寄存器堆的输出内容

    //(rd)
    output reg [4:0] reg_search_in10,      //A位_写入寻址
    output reg [31:0] reg_in10,           //A位_写入内容
    output reg reg_in10_start,            //A位_写入势能

    //B位
     output reg [4:0] reg_search_out11,       //B位_读取寄存器内容寻址
     input wire [31:0] reg_out11,             //B位_读取寄存器堆的输出内容

    //访存位
    output reg [31:0] addr_b,            //寻址线
    output reg [3:0] addr_b_start,      //写入势能
    output reg [31:0] addr_b_write,    //addr_b写入内容
    input wire [31:0] addr_b_read     //addr_b读取内容
);

    assign take_in = 8'b0;            //因为用不到所以永远为0

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

    always @(*) begin        //访存的处理逻辑

        if (reset) begin                            //处理复位
            for (i = 7; i > -1; i = i - 1) begin
                stamp[i] <= 3'b0;
                take[i] <= 5'b0;
            end
            reg_search_out10 <= 5'b0;
            reg_search_in10 <= 5'b0;
            reg_in10 <= 32'b0;
            reg_in10_start <= 1'b0;
            reg_search_out11 <= 5'b0;
            addr_b <= 32'b0;
            addr_b_start <= 4'b0;
            addr_b_write <= 32'b0;
            stamp_in <= 8'b0;
        end

        stamp_in = 8'b00000000;
        reg_in10_start = 1'b0;
        addr_b_start = 1'b0;
        begin : imm
        for (i = 7; i > -1; i = i - 1) begin                                        
            if ((reg_out[i][87:82] == 001100) && (reg_start[i] == 3'b010)) begin    //001100 LB   rs rd  // 加载字节*    rs为要要加载哪个地址的东西，rd是加载到寄存器什么地方
                reg_search_out10 = reg_out[i][81:77];      //寻找寄存器地址
                addr_b = reg_out10;                        //寻址

                reg_search_in10 = reg_out[i][71:67];       //写入寻址
                reg_in10 = addr_b_read;                    //规定写入内容
                reg_in10_start = 1'b1;                     //点势能
                
                stamp[i][2] = reg_out[i][2];               //第一位和最后一位不变，中间的变1
                stamp[i][1] = 1'b1;
                stamp[i][0] = reg_out[i][0];             
                stamp_in[i] = 1'b1;                        //势能

                disable imm;
            end

            if ((reg_out[i][87:82] == 001101) && (reg_start[i] == 3'b010)) begin    //001101 SB   rs rd  // 存储字节*    rs是存储到哪个地址，rd是存储的东西
                reg_search_out10 = reg_out[i][81:77];      //寻找寄存器地址
                addr_b = reg_out10;                        //寻址

                reg_search_out11 = reg_out[i][71:67];
                addr_b_write = reg_out11;
                addr_b_start = 1'b1;

                stamp[i][2] = reg_out[i][2];               //第一位和最后一位不变，中间的变1
                stamp[i][1] = 1'b1;
                stamp[i][0] = reg_out[i][0];             
                stamp_in[i] = 1'b1;                        //势能

                disable imm;
            end
        end
        end
    end
endmodule

//3. 访存指令
//001010 W   rt, offset(rs)  // 加载字//*
//001011 W   rt, offset(rs)  // 存储字//*
//001100 LB   rs rd  // 加载字节*    rs为要要加载哪个地址的东西，rd是加载到寄存器什么地方
//001101 SB   rs rd  // 存储字节*    rs是存储到哪个地址，rd是存储的东西