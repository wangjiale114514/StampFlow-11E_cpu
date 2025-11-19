//处理jump的所有指令，检测有没有依赖问题'
//处理执行要做的几步：
//1.每次只能找一个命令进行处理，不能多命令
//2.先获取哪些命令能运行，然后知道运行啥命令，比如运行加法，首先把命令中要运行的寄存器里面的内容读取出来rs和rt的内容
//然后把他存在next_pc所指的next_data的相对应位置，一次计算到next_data_c，然后给命令单位传一个已执行的章然后点一下势能，然后再给命令传一个take也就是这三个数存在了哪里，再给take一个势能
//下一个时间清零。
//写回只要点一下写回的章然后按标记位取出标记的东西给寄存器组完成写回
//最后需要写fpu，alu，mov的信号的take和stamp的势能信号和东西的汇总器 （也就是写回汇总）

//处理jump类型的命令的时候如果发现有依赖问题的时候也暂停流水线让他们的依赖项跑完之后再进行运行操作，否则的话就会导致一些处理的问题
//处理jump命令的时候还要有控制pc的引脚，跳转引脚，流水线暂停引脚，还有输入跳转偏移量的势能，因为有rs和rd也就是跳转和跳转链接的问题也就是说还要有写回和读取寄存器内容的引脚

//寄存器组5-6编号为jump的编号，5为a位，6为b位

//jump阶段一旦找到找到就在下一个周期把前面的命令设为三个1即代表清空流水线，避免被重复执行，还有就是一定要在第一个阶段发现有依赖问题就暂停流水线直到没有依赖问题

module jump (
    input wire clk,                                   //时钟信号
    input wire reset,                                 //复位

    input wire [23:0] reg_start_flat,              //可运行指令列表  扁平
    input wire [703:0] reg_out_flat,              //指令列表  扁平

    output wire [23:0] stamp_flat,               //需要盖的章  扁平
    output reg [7:0] stamp_in,                 //盖章势能

    output wire [39:0] take_flat,                //写入alu需要取值的位置  扁平
    output reg [7:0] take_in,                  //写入势能

    //A位 (rs)
    output reg [4:0] reg_search_out5,        //A位_读取寄存器内容寻址
    input wire [31:0] reg_out5,             //A位_读取寄存器堆的输出内容

    //(rd) 写入
    output reg [4:0] reg_search_in5,      //A位_写入寻址
    output reg [31:0] reg_in5,           //A位_写入内容
    output reg reg_in5_start,           //A位_写入势能 

    //B位(只需要输出) (rt)
    output reg [4:0] reg_search_out6,        //A位_读取寄存器内容寻址
    input wire [31:0] reg_out6,             //A位_读取寄存器堆的输出内容

    //rd(读取)
    output reg [4:0] reg_search_out7,        //C位_读取寄存器内容寻址
    input wire [31:0] reg_out7,             //C位_读取寄存器堆的输出内容

    //流水线控制执行引脚
    output reg stop,                           //流水线暂停势能
    output reg jump_start,                     //跳转势能
    output reg [31:0] pc_jump,                 //跳转偏移量

    input wire [31:0] pc_out                   //pc的输出
);

    reg [4:0] next_pc;              //循环pc
    reg [31:0] next_data_rs [31:0];  //数据存储器rs
    reg [31:0] next_data_rt [31:0];  //数据存储器rt/立即数
    reg [31:0] next_data_rd [31:0];  //数据存储器rd
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

    always @(*) begin                             //流水线暂停检测
        if (
            (reg_out[0][87:82] == 6'b001110)||    //001110 BEQ  rs, rt, offset  // 相等分支
            (reg_out[0][87:82] == 6'b001111)||    //001111 BNE  rs, rt, offset  // 不等分支
            (reg_out[0][87:82] == 6'b010000)||    //010000 BLEZ rs, offset      // 小于等于零分支
            (reg_out[0][87:82] == 6'b010001)||    //010001 BGTZ rs, offset      // 大于零分支
            (reg_out[0][87:82] == 6'b010010)||    //010010 J    rs              // 直接跳转
            (reg_out[0][87:82] == 6'b010011)||    //010011 JAL  rs ,rd          // 跳转并链接
            (reg_out[0][87:82] == 6'b010100)||    //010100 JR   rs              // 寄存器跳转
            (reg_out[0][87:82] == 6'b010101)      //010101 JALR rd, rs          // 寄存器跳转并链接
        ) begin                                                                 //确保无依赖问题否则暂停流水线
            if ((reg_out[0][2] == 1'b0) && (reg_start[0][2] == 1'b1)) begin     //确保是因为依赖原因才暂停流水线
                stop = 1'b1;
            end
            else begin
                stop = 1'b0;     //如果不是就不暂停
            end
        end
        else begin
            stop = 1'b0;         //如果不是这些指令就不暂停
        end
    end

    always @(*) begin              //处理命令的执行阶段

        if (reset) begin                        //处理复位
            for (i = 7; i > -1; i = i - 1) begin
                stamp[i] <= 3'b0;
                take[i] <= 5'b0;
            end
            reg_search_out5 <= 5'b0;
            reg_search_in5 <= 5'b0;
            reg_in5 <= 32'b0;
            reg_in5_start <= 1'b0;
            reg_search_out6 <= 5'b0;
            take_in <= 8'b0;
            stamp_in <= 8'b0;
            reg_search_out7 <= 5'b0;
            next_pc <= 5'b0;
        end

        take_in = 8'b00000000;     //take势能信号全部归零
        stamp_in = 8'b00000000;    //stamp势能信号全部归零
        jump_start = 1'b0;
        reg_in5_start = 1'b0;         //寄存器写入势能清零

        begin : jump_ex
        for (i = 7; i > -1; i = i - 1) begin    //从后往前，老人优先原则
            if (reg_start[i] == 3'b100) begin   //判断是不是在执行阶段且要确保分支和跳转指令刚进入就必须秒掉如果有依赖就触发流水线停顿**************************************************
                case (reg_out[i][87:82])        //根据命令判断

                   6'b001110 : begin                   //001110 BEQ  rs, rt, offset  //相等分支
                        reg_search_out5 = reg_out[i][81:77];                         //给rs赋值
                        next_data_rs[next_pc] = reg_out5;

                        reg_search_out6 = reg_out[i][76:72];                         //给rt赋值
                        next_data_rt[next_pc] = reg_out6;
                        
                        reg_search_out7 = reg_out[i][71:67];                         //给rd赋值（跳转地址）
                        next_data_rd[next_pc] = reg_out7;   

                        if (next_data_rs[next_pc] == next_data_rt[next_pc]) begin    //对比跳转逻辑
                            pc_jump = next_data_rd[next_pc];                         //给pc跳转赋值
                            jump_start = 1'b1;                                       //点一下势能
                        end

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable jump_ex;                                 //退出循环下一个周期再处理
                   end

                   6'b001111 : begin                   //001111 BNE  rs, rt, offset  //不等分支
                        reg_search_out5 = reg_out[i][81:77];                         //给rs赋值
                        next_data_rs[next_pc] = reg_out5;

                        reg_search_out6 = reg_out[i][76:72];                         //给rt赋值
                        next_data_rt[next_pc] = reg_out6;
                        
                        reg_search_out7 = reg_out[i][71:67];                         //给rd赋值（跳转地址）
                        next_data_rd[next_pc] = reg_out7;   

                        if (next_data_rs[next_pc] != next_data_rt[next_pc]) begin    //对比跳转逻辑
                            pc_jump = next_data_rd[next_pc];                         //给pc跳转赋值
                            jump_start = 1'b1;                                       //点一下势能
                        end

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable jump_ex;                                 //退出循环下一个周期再处理
                   end

                   6'b010000 : begin                   //010000 BLEZ rs, offset      //小于等于零分支
                        reg_search_out5 = reg_out[i][81:77];                         //给rs赋值
                        next_data_rs[next_pc] = reg_out5;

                        reg_search_out6 = reg_out[i][76:72];                         //给rt赋值
                        next_data_rt[next_pc] = reg_out6;
                        
                        reg_search_out7 = reg_out[i][71:67];                         //给rd赋值（跳转地址）
                        next_data_rd[next_pc] = reg_out7;   

                        if (next_data_rs[next_pc] <= 1'b0) begin                     //对比跳转逻辑
                            pc_jump = next_data_rd[next_pc];                         //给pc跳转赋值
                            jump_start = 1'b1;                                       //点一下势能
                        end

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable jump_ex;                                 //退出循环下一个周期再处理
                   end

                   6'b010001 : begin                   //010001 BGTZ rs, offset      //大于零分支
                        reg_search_out5 = reg_out[i][81:77];                         //给rs赋值
                        next_data_rs[next_pc] = reg_out5;

                        reg_search_out6 = reg_out[i][76:72];                         //给rt赋值
                        next_data_rt[next_pc] = reg_out6;
                        
                        reg_search_out7 = reg_out[i][71:67];                         //给rd赋值（跳转地址）
                        next_data_rd[next_pc] = reg_out7;   

                        if (next_data_rs[next_pc] >= 1'b0) begin                     //对比跳转逻辑
                            pc_jump = next_data_rd[next_pc];                         //给pc跳转赋值
                            jump_start = 1'b1;                                       //点一下势能
                        end

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable jump_ex;                                 //退出循环下一个周期再处理
                   end

                   6'b010010 : begin                   //010010 J    rs              //直接跳转
                        reg_search_out5 = reg_out[i][81:77];                         //给rs赋值
                        next_data_rs[next_pc] = reg_out5;


                        pc_jump = next_data_rs[next_pc];                             //给pc跳转赋值
                        jump_start = 1'b1;                                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable jump_ex;                                 //退出循环下一个周期再处理
                   end

                   6'b010011: begin                          //010011 JAL  rs ,rd        //跳转并链接
                        reg_search_out5 = reg_out[i][81:77];                             //给rs赋值
                        next_data_rs[next_pc] = reg_out5;

                        //给寄存器赋值链接后的地址//给rd赋值
                        next_data_rd[next_pc] = pc_out + next_data_rs[next_pc];                                           

                        pc_jump = next_data_rs[next_pc];                                 //给pc跳转赋值
                        jump_start = 1'b1;                                               //点一下势能

                        take[i] = next_pc;                        //处理写回的存储地址
                        take_in[i] = 1'b1;                           //点一下势能

                        stamp[i][1:0] = reg_out[i][1:0];          //后两位章不变
                        stamp[i][2] = 1'b1;                      //表示已经执行了
                        stamp_in [i] = 1'b1;                    //点一下势能

                        disable jump_ex;                                 //退出循环下一个周期再处理
                    end
                endcase
            end
        end
        end

        begin : jump_wb
        for (i = 7; i > -1; i = i - 1) begin     //老人优先
        if ((reg_start[i] == 3'b001) && (reg_out[i][87:82] == 6'b010011)) begin
            reg_search_in5 = reg_out[i][71:67];           //输入寻址
            reg_in5 = next_data_rd[reg_out[i][34:30]];    //给寄存器写回数值
            reg_in5_start = 1'b1;                         //点一下寄存器写入势能

            stamp[i][2:1] = reg_out[i][2:1];           //前两位章不变
            stamp[i][0] = 1'b1;                        //表示已经执行了
            stamp_in [i] = 1'b1;                       //点一下势能
            disable jump_wb;                                     //退出循环下一个周期再处理
            end
        end
        end
    end
endmodule

//需要处理的命令种类
//4. 分支指令
//001110 BEQ  rs, rt, offset  // 相等分支*
//001111 BNE  rs, rt, offset  // 不等分支*
//010000 BLEZ rs, offset      // 小于等于零分支*
//010001 BGTZ rs, offset      // 大于零分支*

//5. 跳转指令
//010010 J    rs              // 直接跳转*
//010011 JAL  rs ,rd          // 跳转并链接*
//010100 JR   rs              // 寄存器跳转//销毁
//010101 JALR rd, rs          // 寄存器跳转并链接//销毁