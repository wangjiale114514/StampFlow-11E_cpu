module top (
    input wire clk,           // 时钟信号
    input wire reset         // 复位信号
);
    
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

    // PC加法器
    pc_adder pc_adder_inst (
        .clk(clk),
        .reset(reset),
        .pc_jump(pc_jump),
        .jump_start(jump_start),
        .pc_stop(pc_stop),
        .pc_out(pc_out)
    );

    // 指令存储器
    inst_mem inst_mem_inst (
        .clk(clk),
        .addr_a(pc_out),           // PC输出连接到addr_a
        .addr_a_start(4'b0),       // 取指阶段只读不写
        .addr_a_write(32'b0),
        .addr_a_read(addr_a_read),
        .addr_b(addr_b),
        .addr_b_start(addr_b_start),
        .addr_b_write(addr_b_write),
        .addr_b_read(addr_b_read)
    );

    // 译码阶段
    if_id if_id_inst (
        .command(addr_a_read),     // 从指令存储器读取指令
        .id_reg_search(reg_out1),  // 从寄存器堆读取数据
        .id_reg(id_reg),
        .clk(clk),
        .command_next(command_next)
    );

    // 传送带指令链
    conveyor conveyor_inst (
        .command_in(command_next),
        .conveyor_stop(conveyor_stop),
        .clk(clk),
        .stamp_flat(conveyor_stamp_flat),
        .stamp_in(conveyor_stamp_in),
        .take_flat(conveyor_take_flat),
        .take_in(conveyor_take_in),
        .reg_start_flat(reg_start_flat),
        .reg_out_flat(reg_out_flat),
        .conveyor_stop_out(conveyor_stop_out),
        .jump_start(jump_start)
    );

    // 汇集信号器
    pool pool_inst (
        // ALU输入
        .alu_stamp_flat(alu_stamp_flat),
        .alu_stamp_in(alu_stamp_in),
        .alu_take_flat(alu_take_flat),
        .alu_take_in(alu_take_in),
        // FPU输入
        .fpu_stamp_flat(fpu_stamp_flat),
        .fpu_stamp_in(fpu_stamp_in),
        .fpu_take_flat(fpu_take_flat),
        .fpu_take_in(fpu_take_in),
        // IMM输入
        .imm_stamp_flat(imm_stamp_flat),
        .imm_stamp_in(imm_stamp_in),
        .imm_take_flat(imm_take_flat),
        .imm_take_in(imm_take_in),
        // JUMP输入
        .jump_stamp_flat(jump_stamp_flat),
        .jump_stamp_in(jump_stamp_in),
        .jump_take_flat(jump_take_flat),
        .jump_take_in(jump_take_in),
        // MOV输入
        .mov_stamp_flat(mov_stamp_flat),
        .mov_stamp_in(mov_stamp_in),
        .mov_take_flat(mov_take_flat),
        .mov_take_in(mov_take_in),
        // 输出到传送带
        .conveyor_stamp_flat(conveyor_stamp_flat),
        .conveyor_stamp_in(conveyor_stamp_in),
        .conveyor_take_flat(conveyor_take_flat),
        .conveyor_take_in(conveyor_take_in)
    );

    // 寄存器堆
    reg_file reg_file_inst (
        .clk(clk),
        // 写入数据
        .reg_in1(reg_in1),
        .reg_in2(reg_in2),
        .reg_in3(reg_in3),
        .reg_in5(reg_in5),
        .reg_in8(reg_in8),
        .reg_in10(reg_in10),
        // 写入寻址
        .reg_search_in1(reg_search_in1),
        .reg_search_in2(reg_search_in2),
        .reg_search_in3(reg_search_in3),
        .reg_search_in5(reg_search_in5),
        .reg_search_in8(reg_search_in8),
        .reg_search_in10(reg_search_in10),
        // 写入势能
        .reg_in1_start(reg_in1_start),
        .reg_in2_start(reg_in2_start),
        .reg_in3_start(reg_in3_start),
        .reg_in5_start(reg_in5_start),
        .reg_in8_start(reg_in8_start),
        .reg_in10_start(reg_in10_start),
        // 读取寻址
        .reg_search_out1(reg_search_out1),
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
        // 读取数据
        .reg_out1(reg_out1),
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

    // ALU执行单元
    alu alu_inst (
        .clk(clk),
        .reg_start_flat(reg_start_flat),
        .reg_out_flat(reg_out_flat),
        .stamp_flat(alu_stamp_flat),
        .stamp_in(alu_stamp_in),
        .take_flat(alu_take_flat),
        .take_in(alu_take_in),
        .reg_search_out3(reg_search_out3),
        .reg_out3(reg_out3),
        .reg_search_in3(reg_search_in3),
        .reg_in3(reg_in3),
        .reg_in3_start(reg_in3_start),
        .reg_search_out4(reg_search_out4),
        .reg_out4(reg_out4)
    );

    // 浮点单元
    fpu fpu_inst (
        .clk(clk),
        .reg_start_flat(reg_start_flat),
        .reg_out_flat(reg_out_flat),
        .stamp_flat(fpu_stamp_flat),
        .stamp_in(fpu_stamp_in),
        .take_flat(fpu_take_flat),
        .take_in(fpu_take_in),
        .reg_search_out8(reg_search_out8),
        .reg_out8(reg_out8),
        .reg_search_in8(reg_search_in8),
        .reg_in8(reg_in8),
        .reg_in8_start(reg_in8_start),
        .reg_search_out9(reg_search_out9),
        .reg_out9(reg_out9)
    );

    //imm
    imm imm_inst (
        .clk(clk),
        .reg_start_flat(reg_start_flat),
        .reg_out_flat(reg_out_flat),
        .stamp_flat(imm_stamp_flat),
        .stamp_in(imm_stamp_in),
        .take_flat(imm_take_flat),
        .take_in(imm_take_in),
        .reg_search_out10(reg_search_out10),
        .reg_out10(reg_out10),
        .reg_search_in10(reg_search_in10),
        .reg_in10(reg_in10),
        .reg_in10_start(reg_in10_start),
        .reg_search_out11(reg_search_out11),
        .reg_out11(reg_out11),
        .addr_b(addr_b),
        .addr_b_start(addr_b_start),
        .addr_b_write(addr_b_write),
        .addr_b_read(addr_b_read)
    );

    //jump
    jump jump_inst (
        .clk(clk),
        .reg_start_flat(reg_start_flat),
        .reg_out_flat(reg_out_flat),
        .stamp_flat(jump_stamp_flat),
        .stamp_in(jump_stamp_in),
        .take_flat(jump_take_flat),
        .take_in(jump_take_in),
        .reg_search_out5(reg_search_out5),
        .reg_out5(reg_out5),
        .reg_search_in5(reg_search_in5),
        .reg_in5(reg_in5),
        .reg_in5_start(reg_in5_start),
        .reg_search_out6(reg_search_out6),
        .reg_out6(reg_out6),
        .reg_search_out7(reg_search_out7),
        .reg_out7(reg_out7),
        .stop(pc_stop),
        .jump_start(jump_start),
        .pc_jump(pc_jump)
    );

    //mov
    mov mov_inst (
        .clk(clk),
        .reg_start_flat(reg_start_flat),
        .reg_out_flat(reg_out_flat),
        .stamp_flat(mov_stamp_flat),
        .stamp_in(mov_stamp_in),
        .take_flat(mov_take_flat),
        .take_in(mov_take_in),
        .reg_search_out2(reg_search_out2),
        .reg_out2(reg_out2),
        .reg_search_in2(reg_search_in2),
        .reg_in2(reg_in2),
        .reg_in2_start(reg_in2_start)
    );

    // 传送带暂停信号连接到跳转单元的暂停输出
    assign conveyor_stop = pc_stop;
    
    // 译码阶段的寄存器寻址连接到寄存器堆
    assign reg_search_out1 = id_reg;
    assign id_reg_search = reg_out1;

endmodule