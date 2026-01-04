module bp(
    input wire clk,
    input wire reset,

    //面向if阶段的输入
    input wire [255:0] if_adderss,
    input wire [255:0] if_data,

    //面向if的输出
    output reg [7:0] if_inst_out,     //Instruction Segmentation out
    output reg [63:0] next_pc,        //out inst's next pc (偏移)
    output reg [7:0] bp_if,           //分支预测结果标志，1为跳转，0为不跳转,8位表示哪条指令跳转

    //面向后端获取分支结果
    input wire [63:0] jump_inst,      //分支指令所在pc
    input wire jump_inst_adderss,     //分支指令方位（1为跳转，0为不跳转）
    input wire jump_start,            //分支指令输入势能
);

    //定义循环变量
    integer i;
    integer d;
    integer g;

    //命令拼接位
    reg inst_duiqi;    
    //如果上一条命令发现没有对齐的话也就是下一个分支指令是高位就可以把他点亮，然后-4取，这样就可以避免命令重复运行

    //BHT表
    reg [63:0] bht_address [0:4095];        //存储分支指令地址
//    reg [63:0] bht_target [0:4095];         //分支目标地址
    reg [1:0] bht_state [0:4095];           //2位饱和计数器
    reg bht_valid [0:4095];                 //BHT表项有效位
    reg [11:0] bht_ptr;                     //用于更新BHT的指针

    //当前拍的分支信息
    reg [2:0] branch_type;                  //分支类型: 000=无, 001=条件, 010=直接跳转, 011=间接跳转
    reg [2:0] branch_pos;                   //分支指令在8条指令中的位置
    reg has_branch;                         //当前拍是否有分支指令

    //指令译码相关
    wire [31:0] inst [0:7];
    wire [63:0] inst_pc [0:7];
    
    //指令分割
    assign inst[0] = if_data[31:0];
    assign inst[1] = if_data[63:32];
    assign inst[2] = if_data[95:64];
    assign inst[3] = if_data[127:96];
    assign inst[4] = if_data[159:128];
    assign inst[5] = if_data[191:160];
    assign inst[6] = if_data[223:192];
    assign inst[7] = if_data[255:224];
    
    //对应的PC地址
    assign inst_pc[0] = if_adderss[63:0];
    assign inst_pc[1] = inst_pc[0] + 64'd4;
    assign inst_pc[2] = inst_pc[0] + 64'd8;
    assign inst_pc[3] = inst_pc[0] + 64'd12;
    assign inst_pc[4] = inst_pc[0] + 64'd16;
    assign inst_pc[5] = inst_pc[0] + 64'd20;
    assign inst_pc[6] = inst_pc[0] + 64'd24;
    assign inst_pc[7] = inst_pc[0] + 64'd28;

    //复位逻辑
    always @(posedge reset) begin
        if (reset) begin
            bht_ptr <= 12'b0;
            for (i = 0; i < 4096; i = i + 1) begin
                bht_address[i] <= 64'b0;
                bht_target[i] <= 64'b0;
                bht_state[i] <= 2'b01;     //初始状态: 弱不跳转
                bht_valid[i] <= 1'b0;
            end
            if_inst_out <= 8'b0;
            next_pc <= 64'b0;
            bp_if <= 8'b0;
        end
    end

    //分支预测查询逻辑
    reg b_over;        //分支预测完成势能（1为已完成预测）
    reg [1:0]bht_out;  //BHT查询结果
    reg bht_start;     //BHT查询成功势能
    always @(*) begin
        if_inst_out = 8'b11111111;    //默认全部收录
        next_pc = 64'd32;             //默认加32
        bp_if = 8'b00000000;          //默认没有分支指令
        b_over = 1'b0;                //0为未预测完
        bht_start = 1'b0;             //BHT默认为未输出
        bht_out = 2'b0;               //BHT的输出

        //如果是非对齐（此位只有后续有分支的时候才设置）
        if (inst_duiqi) begin
            if_inst_out = 8'b11111110;
        end

        //查找第一个分支指令
        //无条件分支
        for (d = 0; d < 8; d = d + 1) begin
            if (if_inst_out[d]) begin    //是否需要译码
                if (
                    (inst[d][6:0] == 7'b1101111)  //有无无条件分支    
                ) begin
                    bp_if[d] = 1'b1;    //标记跳转命令
                    if_inst_out[7:(d+1)] = (8-(d+1))'b0;    //高位全部归0
                    //查找内容
                    next_pc = ({{43{inst[d][31]}}, inst[d][31], inst[d][19:12], inst[d][20], inst[d][30:21], 1'b0}) + (d * 4);
                    d = 9;                //结束查询
                    b_over = 1'b1;        //完成预测
                    inst_duiqi = 1'b0;    //标记为对齐
                end
            end
        end

        //有条件分支预测
        if (!b_over) begin    //并没有完成预测
            for (d = 0; d < 8; d = d + 1) begin
                if (if_inst_out[d]) begin             //是否需要译码
                    if (
                        (inst[d][6:0] == 7'b1100011)  //有有条件分支    
                    ) begin
                        //查BHT
                        for (i = 0; i < 4096; i = i + 1) begin
                            if (
                                (inst_pc[d] == bht_address[i])    //查到指令
                                &&(bht_valid[d] == 1'b1)          //有效位有效
                            ) begin
                                bht_out = bht_state[i];           //输出内容
                                bht_start = 1'b1;                 //查询成功标识
                            end
                        end

                        //运行逻辑
                        if (     //检测有没有查到BHT
                            bht_start
                        ) begin  //如果预测BHT成功
                            if (bht_out[1]) begin    //预测跳转
                                if_inst_out[7:(d+1)] = (8-(d+1))'b0;    //高位全部归0
                                //查找内容
                                bp_if[d] = 1'b1;      //标记跳转命令
                                next_pc = ({{51{inst[d][31]}}, inst[d][31], inst[d][7], inst[d][30:25], inst[d][11:8], 1'b0}) + (d * 4);
                                d = 9;                //结束查询
                                b_over = 1'b1;        //完成预测
                                inst_duiqi = 1'b0;    //标记为对齐
                            end
                            else begin               //预测不跳转
                                for (g = d; g < 8; g = g + 1) begin    //寻找后面有分支命令
                                    if (
                                        (inst[g][6:0] == 7'b1101111)    //有无条件分支
                                        ||(inst[g][6:0] == 7'b1100011)  //有有条件分支
                                    ) begin
                                        if_inst_out[7:(g-1)] = (8-(g-1))'b0;    //高位全部归0

                                        if (g%2) begin                          //判断是否为非对齐
                                            next_pc = (g-1) * 4;                //非对齐
                                            inst_duiqi = 1'b1;                  //标记非对齐
                                        end
                                        else begin                              //如果对齐
                                            next_pc = g * 4;                    //对齐输出
                                            inst_duiqi = 1'b0;                  //标记对齐
                                        end
                                        b_over = 1'b1;                          //完成预测
                                        g = 9;                                  //终止循环
                                    end
                                end
                            end
                        end
                        else begin //如果BHT没有内容
                            for (g = d; g < 8; g = g + 1) begin    //寻找后面有分支命令
                                if (
                                    (inst[g][6:0] == 7'b1101111)    //有无条件分支
                                    ||(inst[g][6:0] == 7'b1100011)  //有有条件分支
                                ) begin
                                    if_inst_out[7:(g-1)] = (8-(g-1))'b0;    //高位全部归0

                                    if (g%2) begin                          //判断是否为非对齐
                                        next_pc = (g-1) * 4;                //非对齐
                                        inst_duiqi = 1'b1;                  //标记非对齐
                                    end
                                    else begin                              //如果对齐
                                        next_pc = g * 4;                    //对齐输出
                                        inst_duiqi = 1'b0;                  //标记对齐
                                    end
                                    b_over = 1'b1;                          //完成预测
                                    g = 9;                                  //终止循环
                                end
                                
                            end
                        end
                    end
                end
            end
        end   
    end

    //分支BHT写入逻辑
    always @() begin  
        ......
    end

endmodule

/*    //分支预测查找逻辑
    always @(*) begin
        //默认值
        has_branch = 1'b0;
        branch_type = 3'b000;
        branch_pos = 3'b0;
        misaligned = 1'b0;
        next_pc = 64'd32;  //默认取下一拍
        bp_if = 8'b11111111; //默认全部有效
        
        //查找第一个分支指令
        for (d = 0; d < 8; d = d + 1) begin
            if (!has_branch) begin
                case (inst[d][6:0])
                    7'b1100011: begin //条件分支
                        has_branch = 1'b1;
                        branch_type = 3'b001;
                        branch_pos = d[2:0];
                        //检查BHT
                        predict_conditional(inst_pc[d], d);
                    end
                    7'b1101111: begin //JAL
                        has_branch = 1'b1;
                        branch_type = 3'b010;
                        branch_pos = d[2:0];
                        predict_direct_jump(inst[d], inst_pc[d], d);
                    end
                    7'b1100111: begin //JALR
                        has_branch = 1'b1;
                        branch_type = 3'b011;
                        branch_pos = d[2:0];
                        //间接跳转难以预测，默认不跳转
                        bp_if = (1 << d) - 1; //只允许分支前的指令继续
                        next_pc = inst_pc[d] + 64'd4;
                    end
                endcase
            end
        end
    end

    //条件分支预测函数
    task predict_conditional;
        input [63:0] pc;
        input [2:0] pos;
        reg hit;
        integer j;
        begin
            hit = 1'b0;
            //查找BHT
            for (j = 0; j < 4096; j = j + 1) begin
                if (bht_valid[j] && (bht_address[j] == pc)) begin
                    hit = 1'b1;
                    //根据状态预测
                    if (bht_state[j][1]) begin //高位为1预测跳转
                        next_pc = bht_target[j];
                        bp_if = (1 << pos) - 1; //分支前的指令继续
                    end else begin
                        next_pc = pc + 64'd4;
                        bp_if = 8'b11111111;
                    end
                    break;
                end
            end
            
            if (!hit) begin
                //未命中，默认不跳转
                next_pc = pc + 64'd4;
                bp_if = 8'b11111111;
            end
        end
    endtask

    //直接跳转预测函数
    task predict_direct_jump;
        input [31:0] instruction;
        input [63:0] pc;
        input [2:0] pos;
        begin
            //计算跳转目标
            next_pc = pc + {{44{instruction[31]}}, instruction[31], 
                           instruction[19:12], instruction[20], 
                           instruction[30:21], 1'b0};
            bp_if = (1 << pos) - 1; //只允许分支前的指令继续
        end
    endtask

    //从后端更新BHT
    always @(posedge clk) begin
        if (jump_start) begin
            update_bht(jump_inst, jump_inst_adderss);
        end
    end

    //更新BHT任务
    task update_bht;
        input [63:0] pc;
        input taken;
        integer k;
        reg found;
        begin
            found = 1'b0;
            //查找现有表项
            for (k = 0; k < 4096; k = k + 1) begin
                if (bht_valid[k] && (bht_address[k] == pc)) begin
                    found = 1'b1;
                    //更新状态机
                    if (taken) begin
                        case (bht_state[k])
                            2'b00: bht_state[k] <= 2'b01;
                            2'b01: bht_state[k] <= 2'b11;
                            2'b10: bht_state[k] <= 2'b11;
                            2'b11: bht_state[k] <= 2'b11;
                        endcase
                    end else begin
                        case (bht_state[k])
                            2'b00: bht_state[k] <= 2'b00;
                            2'b01: bht_state[k] <= 2'b00;
                            2'b10: bht_state[k] <= 2'b01;
                            2'b11: bht_state[k] <= 2'b10;
                        endcase
                    end
                    break;
                end
            end
            
            if (!found) begin
                //分配新表项
                bht_address[bht_ptr] <= pc;
                bht_valid[bht_ptr] <= 1'b1;
                bht_state[bht_ptr] <= taken ? 2'b11 : 2'b00;
                bht_ptr <= bht_ptr + 1;
            end
        end
    endtask
*/