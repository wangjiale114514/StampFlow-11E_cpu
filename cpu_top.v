//顶层信号区
module top (
    input wire clk,
    input wire reset
);
    // 内部信号定义
    // PC相关信号
    wire [31:0] pc_out;
    wire pc_stop;
    wire jump_start;
    wire [31:0] pc_jump;
    
    // 指令存储器信号
    wire [31:0] addr_a_read;
    wire [31:0] addr_b_read;
    wire [31:0] addr_b_write;
    wire [3:0] addr_b_start;
    wire [31:0] addr_b;
    
    // 译码阶段信号
    wire [87:0] command_next;
    wire [4:0] id_reg;
    wire [31:0] id_reg_search;
    
    // 传送带信号
    wire [87:0] command_in;
    wire conveyor_stop;
    wire conveyor_stop_out;
    wire [23:0] reg_start_flat;
    wire [703:0] reg_out_flat;
    
    // 汇集信号器信号
    wire [23:0] conveyor_stamp_flat;
    wire [7:0] conveyor_stamp_in;
    wire [39:0] conveyor_take_flat;
    wire [7:0] conveyor_take_in;
    
    // 各执行单元章和take信号
    wire [23:0] alu_stamp_flat, fpu_stamp_flat, imm_stamp_flat, jump_stamp_flat, mov_stamp_flat;
    wire [7:0] alu_stamp_in, fpu_stamp_in, imm_stamp_in, jump_stamp_in, mov_stamp_in;
    wire [39:0] alu_take_flat, fpu_take_flat, imm_take_flat, jump_take_flat, mov_take_flat;
    wire [7:0] alu_take_in, fpu_take_in, imm_take_in, jump_take_in, mov_take_in;
    
    // 寄存器堆信号
    wire [31:0] reg_in1, reg_in2, reg_in3, reg_in5, reg_in8, reg_in10;
    wire [4:0] reg_search_in1, reg_search_in2, reg_search_in3, reg_search_in5, reg_search_in8, reg_search_in10;
    wire reg_in1_start, reg_in2_start, reg_in3_start, reg_in5_start, reg_in8_start, reg_in10_start;
    wire [4:0] reg_search_out1, reg_search_out2, reg_search_out3, reg_search_out4, reg_search_out5;
    wire [4:0] reg_search_out6, reg_search_out7, reg_search_out8, reg_search_out9, reg_search_out10, reg_search_out11;
    wire [31:0] reg_out1, reg_out2, reg_out3, reg_out4, reg_out5, reg_out6, reg_out7, reg_out8, reg_out9, reg_out10, reg_out11;
    wire [3:0] addr_a_start;
    wire [31:0] addr_a_write;

    //流水线前
    //pc加法器以及取指（pc加法器以及内存器）
     pc_adder pc_adder_init(
        .clk(clk),
        .reset(reset),
        .pc_jump(pc_jump),         //跳转偏移量
        .jump_start(jump_start),   //跳转势能
        .pc_stop(stop),            //流水线停顿
        .pc_out(pc_out)
    );

    inst_mem inst_mem_init(
        .clk(clk),                     //时钟

        .addr_a(pc_out),               //pc加法器管的内存
        .addr_a_start(addr_a_start),
        .addr_a_write(addr_a_write),
        .addr_a_read(addr_a_read),     //直接连接到译码器

        .addr_b(addr_b),               //addr_b地址线    //imm访存
        .addr_b_start(addr_b_start),   //addr_b写入势能
        .addr_b_write(addr_b_write),   //addr_b写入内容
        .addr_b_read(addr_b_read)      //addr_b读取内容
    );

    //初始化内存a写入部分
    assign addr_a_start = 4'b0;
    assign addr_a_write = 32'b0;

    //译码单元
    //if_id
    if_id if_id(
        .clk(clk),                      //时钟信号

        .command(addr_a_read),          //命令入口
        .id_reg_search(reg_out1),  //接收存寄存器数据位
        .id_reg(reg_search_out1),                //发给寄存器的寻址线
        .command_next(command_next)     //处理后的命令：6位操作码 + 5位rs + 5位rt + 5位rd + 32位立即数 + 32位访存地址 + 3位章
    );

    //流水线控制单元
    //conveyor
    conveyor conveyor(
        .clk(clk),                         //时钟信号

        .command_in(command_next),          //指令进入端口 
        .conveyor_stop(stop),              //流水线暂停势能,拉高暂停

        .stamp_flat(conveyor_stamp_flat),  //8个寄存器章 [a-h]    扁平
        .stamp_in(conveyor_stamp_in),      //8个寄存器章势能 [a-h]

        .take_flat(conveyor_take_flat),    //写入执行器需要取值的位置  扁平
        .take_in(conveyor_take_in),        //写入势能

        .reg_start_flat(reg_start_flat),   //可运行指令列表 [a-h]按照顺序输出    扁平 
        .reg_out_flat(reg_out_flat),       //各自输出 [a-h]                      扁平

        .conveyor_stop_out(stop),          //流水线暂停输出信号
        .jump_start(jump_start)            //检测跳转势能
    );

    //pool
    pool pool(
        //conveyor
        .conveyor_stamp_flat(conveyor_stamp_flat),    //需要盖的章  扁平
        .conveyor_stamp_in(conveyor_stamp_in),        //盖章势能

        .conveyor_take_flat(conveyor_take_flat),      //写入alu需要取值的位置  扁平
        .conveyor_take_in(conveyor_take_in),          //写入势能

        //alu
        .alu_stamp_flat(alu_stamp_flat),
        .alu_stamp_in(alu_stamp_in),

        .alu_take_flat(alu_take_flat),
        .alu_take_in(alu_take_in),

        //fpu
        .fpu_stamp_flat(fpu_stamp_flat),
        .fpu_stamp_in(fpu_stamp_in),

        .fpu_take_flat(fpu_take_flat),
        .fpu_take_in(fpu_take_in),

        //imm
        .imm_stamp_flat(imm_stamp_flat),
        .imm_stamp_in(imm_stamp_in),

        .imm_take_flat(imm_take_flat),
        .imm_take_in(imm_take_in),

        //jump
        .jump_stamp_flat(jump_stamp_flat),
        .jump_stamp_in(jump_stamp_in),

        .jump_take_flat(jump_take_flat),
        .jump_take_in(jump_take_in),

        //mov
        .mov_stamp_flat(mov_stamp_flat),
        .mov_stamp_in(mov_stamp_in),

        .mov_take_flat(mov_take_flat),
        .mov_take_in(mov_take_in)
    );

    //寄存器堆
    reg_file reg_file(
        .clk(clk),                           //时钟

//        .reg_in1(reg_in1),                   //寄存器写入内容
        .reg_in2(reg_in2),
        .reg_in3(reg_in3),
        .reg_in5(reg_in5),
        .reg_in8(reg_in8),
        .reg_in10(reg_in10),

//        .reg_search_in1(reg_search_in1),    //寄存器写入寻址
        .reg_search_in2(reg_search_in2),
        .reg_search_in3(reg_search_in3),
        .reg_search_in5(reg_search_in5),
        .reg_search_in8(reg_search_in8),
        .reg_search_in10(reg_search_in10),

//        .reg_in1_start(reg_in1_start),       //写入势能
        .reg_in2_start(reg_in2_start),
        .reg_in3_start(reg_in3_start),
        .reg_in5_start(reg_in5_start),
        .reg_in8_start(reg_in8_start),
        .reg_in10_start(reg_in10_start),

        .reg_search_out1(reg_search_out1),   //寄存器输出寻址
        .reg_search_out2(reg_search_out2),
        .reg_search_out3(reg_search_out3),
        .reg_search_out4(reg_search_out4),
        .reg_search_out5(reg_search_out5),
        .reg_search_out6(reg_search_out6),
        .reg_search_out7(reg_search_out7),
        .reg_search_out8(reg_search_out8),
        .reg_search_out9(reg_search_out9),
        .reg_search_out10(reg_search_out10),
        .reg_search_out11(reg_search_out11),

        .reg_out1(reg_out1),                  //寄存器输出
        .reg_out2(reg_out2),
        .reg_out3(reg_out3),
        .reg_out4(reg_out4),
        .reg_out5(reg_out5),
        .reg_out6(reg_out6),
        .reg_out7(reg_out7),
        .reg_out8(reg_out8),
        .reg_out9(reg_out9),
        .reg_out10(reg_out10),
        .reg_out11(reg_out11)
    );

    //执行单元
    //alu
    alu alu(
        .clk(clk),      //时钟

        .reg_start_flat(reg_start_flat),     //可运行指令列表  扁平
        .reg_out_flat(reg_out_flat),         //指令列表  扁平

        .stamp_flat(alu_stamp_flat),         //需要盖的章  扁平
        .stamp_in(alu_stamp_in),             //盖章势能
        
        .take_flat(alu_take_flat),           //写入alu需要取值的位置  扁平
        .take_in(alu_take_in),               //写入势能

        .reg_search_out3(reg_search_out3),   //A位_读取寄存器内容寻址
        .reg_out3(reg_out3),                 //A位_读取寄存器堆的输出内容

        .reg_search_in3(reg_search_in3),     //A位_写入寻址
        .reg_in3(reg_in3),                   //A位_写入内容
        .reg_in3_start(reg_in3_start),       //A位_写入势能 

        .reg_search_out4(reg_search_out4),   //A位_读取寄存器内容寻址
        .reg_out4(reg_out4)                  //A位_读取寄存器堆的输出内容
    );

    //fpu
    fpu fpu (
        .clk(clk),    //时钟

        .reg_start_flat(reg_start_flat),     //可运行指令列表  扁平
        .reg_out_flat(reg_out_flat),         //指令列表  扁平

        .stamp_flat(fpu_stamp_flat),         //需要盖的章  扁平
        .stamp_in(fpu_stamp_in),             //盖章势能

        .take_flat(fpu_take_flat),           //写入alu需要取值的位置  扁平
        .take_in(fpu_take_in),               //写入势能

        .reg_search_out8(reg_search_out8),   //A位_读取寄存器内容寻址
        .reg_out8(reg_out8),                 //A位_读取寄存器堆的输出内容

        .reg_search_in8(reg_search_in8),     //A位_写入寻址
        .reg_in8(reg_in8),                   //A位_写入内容
        .reg_in8_start(reg_in8_start),       //A位_写入势能 

        .reg_search_out9(reg_search_out9),   //A位_读取寄存器内容寻址
        .reg_out9(reg_out9)                  //A位_读取寄存器堆的输出内容
    );

    //imm
    imm imm (
        .clk(clk),                                       //时钟信号

        .reg_start_flat(reg_start_flat),                 //可运行指令列表  扁平
        .reg_out_flat(reg_out_flat),                     //指令列表  扁平
        
        .stamp_flat(imm_stamp_flat),                     //需要盖的章  扁平
        .stamp_in(imm_stamp_in),                         //盖章势能

        .take_flat(imm_take_flat),                       //写入alu需要取值的位置  扁平
        .take_in(imm_take_in),                           //写入势能

        .reg_search_out10(reg_search_out10),             //A位_读取寄存器内容寻址
        .reg_out10(reg_out10),                           //A位_读取寄存器堆的输出内容

        .reg_search_in10(reg_search_in10),               //A位_写入寻址
        .reg_in10(reg_in10),                             //A位_写入内容
        .reg_in10_start(reg_in10_start),                 //A位_写入势能

        .reg_search_out11(reg_search_out11),             //B位_读取寄存器内容寻址
        .reg_out11(reg_out11),                           //B位_读取寄存器堆的输出内容

        .addr_b(addr_b),                                 //寻址线
        .addr_b_start(addr_b_start),                     //写入势能
        .addr_b_write(addr_b_write),                     //addr_b写入内容
        .addr_b_read(addr_b_read)                        //addr_b读取内容
    );

    //jump
    jump jump (
        .clk(clk),                                    //时钟信号

        .reg_start_flat(reg_start_flat),              //可运行指令列表  扁平
        .reg_out_flat(reg_out_flat),                  //指令列表  扁平

        .stamp_flat(jump_stamp_flat),                 //需要盖的章  扁平
        .stamp_in(jump_stamp_in),                     //盖章势能

        .take_flat(jump_take_flat),                   //写入alu需要取值的位置  扁平
        .take_in(jump_take_in),                       //写入势能

        .reg_search_out5(reg_search_out5),            //A位_读取寄存器内容寻址
        .reg_out5(reg_out5),                          //A位_读取寄存器堆的输出内容

        .reg_search_in5(reg_search_in5),              //A位_写入寻址
        .reg_in5(reg_in5),                            //A位_写入内容
        .reg_in5_start(reg_in5_start),                //A位_写入势能 

        .reg_search_out6(reg_search_out6),            //A位_读取寄存器内容寻址
        .reg_out6(reg_out6),                          //A位_读取寄存器堆的输出内容

        .reg_search_out7(reg_search_out7),            //C位_读取寄存器内容寻址
        .reg_out7(reg_out7),                          //C位_读取寄存器堆的输出内容

        .stop(stop),                                  //流水线暂停势能
        .jump_start(jump_start),                      //跳转势能
        .pc_jump(pc_jump)                             //跳转偏移量
    );

    //mov
    mov mov (
        .clk(clk),                                    //时钟信号

        .reg_start_flat(reg_start_flat),              //可运行指令列表  扁平
        .reg_out_flat(reg_out_flat),                  //指令列表  扁平
        
        .stamp_flat(mov_stamp_flat),                  //需要盖的章  扁平
        .stamp_in(mov_stamp_in),                      //盖章势能

        .take_flat(mov_take_flat),                    //写入alu需要取值的位置  扁平
        .take_in(mov_take_in),                        //写入势能

        .reg_search_out2(reg_search_out2),            //读取寄存器内容寻址
        .reg_out2(reg_out2),                          //读取寄存器堆的输出内容

        .reg_search_in2(reg_search_in2),              //写入寻址
        .reg_in2(reg_in2),                            //写入内容
        .reg_in2_start(reg_in2_start)                 //写入势能 
    );

endmodule