//包含id_fifo和id向后的输出
//分解微操作和映射物理寄存器，id能处理的事情要小于取指数量
//id_fifo配置32个,当最后8个得时候不再录入东西
module id (
    input wire clk,    //时钟
    input wire reset,  //复位
    input wire stop,   //暂停势能 

    //输入分支预测失败内容清空流水线
    input wire bp_reset,

    //面向if阶段接收的指令
    input wire [511:0] if_data_flat;    //接收得命令
    input wire [511:0] if_adderss_flat; //指令得存储地址，作为后端唯一标识
    input wire [7:0] bp_in;             //bp预测结果
    input wire [7:0] if_in_en;          //接收势能
    output reg if_out_full;             //打入1暂停取指，意思是id fifo满了

    //输出给ROB
    
    //输出给保留站

    //重命名信息
    input wire [255:0] rat_file,    //RAT out
    //输入更改RAT
    input wire [31:0] rat_now_null, //RAT现空表
    output wire [19:0] rat_wire,     //RAT更新内容
    output reg [3:0] rat_wire_en,   //RAT写入势能
    
);

    //定义循环变量
    integer i;
    integer d;
    integer g;

    //ID_FIFO
    reg [4:0] id_fifo_pc;    //id fifo得指针
    reg [31:0] id_fifo_data [0:31];    //输入的数据
    reg [63:0] id_fifo_adderss[0:31];  //输入的地址
    reg id_fifo_bp[0:31];              //输入的分支预测结果
    reg id_fifo_en[0:31];              //可用势能

    //IF信号拆分
    //inst内容拆分
    reg [63:0] if_data [7:0];
    assign if_data[0] = if_data_flat[63:0];
    assign if_data[1] = if_data_flat[127:64];
    assign if_data[2] = if_data_flat[191:128];
    assign if_data[3] = if_data_flat[255:192];
    assign if_data[4] = if_data_flat[319:256];
    assign if_data[5] = if_data_flat[383:320];
    assign if_data[6] = if_data_flat[447:384];
    assign if_data[7] = if_data_flat[511:448];

    //adderss内容拆分
    reg [63:0] if_adderss [7:0]; 
    assign if_adderss[0] = if_adderss_flat[63:0];
    assign if_adderss[1] = if_adderss_flat[127:64];
    assign if_adderss[2] = if_adderss_flat[191:128];
    assign if_adderss[3] = if_adderss_flat[255:192];
    assign if_adderss[4] = if_adderss_flat[319:256];
    assign if_adderss[5] = if_adderss_flat[383:320];
    assign if_adderss[6] = if_adderss_flat[447:384];
    assign if_adderss[7] = if_adderss_flat[511:448];

    //RAT输入目标寄存器
    reg [4:0] rat_wire_in [0:3];  //重命名out表
    assign rat_wire[4:0] = rat_wire_in[0];
    assign rat_wire[9:5] = rat_wire_in[1];
    assign rat_wire[14:10] = rat_wire_in[2];
    assign rat_wire[19:15] = rat_wire_in[3];

    //RAT现空表
    wire [7:0] rat_now [0:3];
    assign rat_now[0] <= rat_now_null[7:0];
    assign rat_now[1] <= rat_now_null[15:8];
    assign rat_now[2] <= rat_now_null[23:16];
    assign rat_now[3] <= rat_now_null[31:24];
    
    //重命名表输出
    wire [7:0] rat_out [0:31];    //32个寄存器(R0坐标00000000，恒等为0)
    assign rat_out[0] = rat_file[7:0];
    assign rat_out[1] = rat_file[15:8];
    assign rat_out[2] = rat_file[23:16];
    assign rat_out[3] = rat_file[31:24];
    assign rat_out[4] = rat_file[39:32];
    assign rat_out[5] = rat_file[47:40];
    assign rat_out[6] = rat_file[55:48];
    assign rat_out[7] = rat_file[63:56];
    assign rat_out[8] = rat_file[71:64];
    assign rat_out[9] = rat_file[79:72];
    assign rat_out[10] = rat_file[87:80];
    assign rat_out[11] = rat_file[95:88];
    assign rat_out[12] = rat_file[103:96];
    assign rat_out[13] = rat_file[111:104];
    assign rat_out[14] = rat_file[119:112];
    assign rat_out[15] = rat_file[127:120];
    assign rat_out[16] = rat_file[135:128];
    assign rat_out[17] = rat_file[143:136];
    assign rat_out[18] = rat_file[151:144];
    assign rat_out[19] = rat_file[159:152];
    assign rat_out[20] = rat_file[167:160];
    assign rat_out[21] = rat_file[175:168];
    assign rat_out[22] = rat_file[183:176];
    assign rat_out[23] = rat_file[191:184];
    assign rat_out[24] = rat_file[199:192];
    assign rat_out[25] = rat_file[207:200];
    assign rat_out[26] = rat_file[215:208];
    assign rat_out[27] = rat_file[223:216];
    assign rat_out[28] = rat_file[231:224];
    assign rat_out[29] = rat_file[239:232];
    assign rat_out[30] = rat_file[247:240];
    assign rat_out[31] = rat_file[255:248];

    //复位
    always @(posedge reset) begin
        if_out_full <= 1'b0;    //复位饱满信号
        id_fifo_pc <= 5'b0;     //复位fifo指针
        for (i = 0; i < 32; i = i + 1) begin     //复位fifo
            id_fifo_data[i] <= 32'b0;
            id_fifo_adderss[i] <= 64'b0;
            id_fifo_bp[i] <= 1'b0;
            id_fifo_en[i] <= 1'b0;
        end
    end    

    //分支预测失败回溯
    always @(posedge clk) begin
        if (bp_reset) begin
            if_out_full <= 1'b0;
            id_fifo_pc <= 5'b0;
            for (i = 0; i < 32; i = i + 1) begin  //清空id_fifo
                id_fifo_pc <= '0; 
                id_fifo_data <= '0; 
                id_fifo_adderss <= '0; 
                id_fifo_bp <= '0;        
                id_fifo_en <= '0;      
            end
            not_inst <= 4'b0;
            for (i = 0; i < 4; i = i + 1) begin     //拆指令复位
                data_upos <= 32'b0;
                adderss_upos <= 32'b0;
                bp_upos <= 1'b0;
            end
            for (i = 0; i < 4; i = i + 1) begin    //分操作码
                id_reg_adderss <= '0; //命令PC
                id_reg_op <= '0;     //操作码与功能码17位[16:0]{funct7(7),funct3(3),op(7)}
                id_reg_rs <= '0;      //读取寄存器1
                id_reg_rt <= '0;      //读取寄存器2
                id_reg_rd <= '0;      //目标寄存器3
                id_reg_im <= '0;     //指令立即数
                id_reg_bp <= '0;            //分支结果
                id_reg_en <= '0;            //有效标识
            end
            for (i = 0; i < 4; i = i + 1) begin    //寄存器重命名A
                //寄存器重命名A    
                ra_reg_adderss <= '0; //命令PC
                ra_reg_op <= '0;     //操作码与功能码17位[16:0]{funct7(7),funct3(3),op(7)}
                ra_reg_rs <= '0;      //读取寄存器1
                ra_reg_rt <= '0;      //读取寄存器2
                ra_reg_rd <= '0;      //目标寄存器3
                ra_reg_im <= '0;     //指令立即数
                ra_reg_bp <= '0;            //分支结果
                ra_reg_en <= '0;            //有效标识  
                reg_adders <= '0;    //旧表被覆盖逻辑寄存器
                reg_data <= '0;       //旧表被覆盖对应值
                reg_en <= '0;                //表格有效项
                reg_now <= '0;        //旧空表
            end
            for (i = 0; i < 4; i = i + 1) begin    //重命名后输出（寄存器重命名B）
                ne_reg_adderss <= '0; //命令PC
                ne_reg_op <= '0;     //操作码与功能码17位[16:0]{funct7(7),funct3(3),op(7)}
                ne_reg_rs <= '0;      //读取寄存器1
                ne_reg_rt <= '0;      //读取寄存器2
                ne_reg_rd <= '0;      //目标寄存器3
                ne_reg_im <= '0;     //指令立即数
                ne_reg_bp <= '0;            //分支结果
                ne_reg_en <= '0;            //有效标识
            end

        end
    end

    //暂停取指势能
    reg stop_id;
    //命令输入逻辑 
    always @(posedge clk) begin
        if (!if_out_full) begin    //如果暂停就不执行
            for (g = 0; g < 8; g = g + 1) begin
                if (if_in_en[g]) begin    //可用存入FIFO
                    id_fifo_data[id_fifo_pc] = if_data[g];       //存内容
                    id_fifo_adderss[id_fifo_pc] = if_adderss[g]; //存地址
                    id_fifo_bp[id_fifo_pc] = bp_in[g];           //存预测结果
                    id_fifo_en[id_fifo_pc] = 1'b1;               //可用
                    id_fifo_pc = id_fifo_pc + 5'b00001;          //指针+1
                end
            end
        end

        if (id_fifo_pc >= 5'd17) begin    //超过就暂停
            stop_id = 1'b1;    //准备下个周期的取值
            if_out_full = 1'b1;//暂停
        end
    end     

    always @(posedge clk) begin
        if (stop_id) begin
            for (g = 0; g < 8; d = g + 1) begin
                if (if_in_en[g]) begin    //可用存入FIFO
                    id_fifo_data[id_fifo_pc] = if_data[g];       //存内容
                    id_fifo_adderss[id_fifo_pc] = if_adderss[g]; //存地址
                    id_fifo_bp[id_fifo_pc] = bp_in[g];           //存预测结果
                    id_fifo_en[id_fifo_pc] = 1'b1;               //可用
                    id_fifo_pc = id_fifo_pc + 5'b00001;          //指针+1
                end
            end
            stop_id = 1'b0;    //暂停取指
            id_fifo_pc = 5'b0; //指针归零
        end
    end

    //译码
    //FIFO取指令
    reg [3:0]not_inst;              //未取到指令(inst可不可用)
    reg [31:0] data_upos [0:3];     //面向微操作的inst
    reg [31:0] adderss_upos [0:3];  //面向微操作的adderss
    reg bp_upos[0:3];               //面向微操作的bp输出

    always @(posedge clk) begin
        if (!stop) begin    //没有暂停
            not_inst = 4'b0000;
            for (d = 0; d < 4; d = d + 1) begin    //收四条命令
                for (i = 0; i < 32; i = i + 1) begin
                    if (id_fifo_en[i]) begin                  //该命令可用
                        id_fifo_en[i] = 1'b0;                 //该指令已被取出
                        not_inst[d] = 1'b1;                   //找到可译码指令
                        data_upos[d] = id_fifo_data[i];       //输出命令
                        adderss_upos[d] = id_fifo_adderss[i]; //输出的adderss
                        bp_upos[d] = id_fifo_bp[i];           //输出的bp内容
                    end
                end
            end
            if (not_inst != 4'b1111) begin      //如果inst内容没有对上
                //id_fifo_pc = 5'b0;            //复位fifo指针
                if_out_full = 1'b0;             //拉低满员势能
            end
        end
    end

    //分操作码
    reg [63:0] id_reg_adderss[0:3]; //命令PC
    reg [16:0] id_reg_op [0:3];     //操作码与功能码17位[16:0]{funct7(7),funct3(3),op(7)}
    reg [4:0] id_reg_rs [0:3];      //读取寄存器1
    reg [4:0] id_reg_rt [0:3];      //读取寄存器2
    reg [4:0] id_reg_rd [0:3];      //目标寄存器3
    reg [63:0] id_reg_im [0:3];     //指令立即数
    reg id_reg_bp [0:3];            //分支结果
    reg id_reg_en [0:3];            //有效标识

    always @(posedge clk) begin
        if (!stop) begin
            for (d = 0; d < 4; d = d + 1) begin
                if (not_inst[d]) begin    //检索内容
                    case (data_upos[6:0]) //检索操作码

                        7'b0110011: begin //R型指令
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {data_upos[d][31:25],data_upos[d][14:12],data_upos[d][6:0]}; //写操作码
                            id_reg_rs[d] <= data_upos[d][19:15];    //写入rs1
                            id_reg_rt[d] <= data_upos[d][24:20];    //写入rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= 64'b0;                  //没用立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b0010011: begin //I型命令
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,data_upos[d][14:12],data_upos[d][6:0]}; //写操作码(无funct7)
                            id_reg_rs[d] <= data_upos[d][19:15];    //写入rs1
                            id_reg_rt[d] <= 5'b00000;               //无rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= {{52{data_upos[d][31]}}, data_upos[d][31:20]};      //写入立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b0000011: begin //I型命令(2)
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,data_upos[d][14:12],data_upos[d][6:0]}; //写操作码(无funct7)
                            id_reg_rs[d] <= data_upos[d][19:15];    //写入rs1
                            id_reg_rt[d] <= 5'b00000;               //无rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= {{52{data_upos[d][31]}}, data_upos[d][31:20]};      //写入立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b1100111: begin //I型命令(3)
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,data_upos[d][14:12],data_upos[d][6:0]}; //写操作码(无funct7)
                            id_reg_rs[d] <= data_upos[d][19:15];    //写入rs1
                            id_reg_rt[d] <= 5'b00000;               //无rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= {{52{data_upos[d][31]}}, data_upos[d][31:20]};      //写入立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b1110011: begin //I型命令(4)
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,data_upos[d][14:12],data_upos[d][6:0]}; //写操作码(无funct7)
                            id_reg_rs[d] <= data_upos[d][19:15];    //写入rs1
                            id_reg_rt[d] <= 5'b00000;               //无rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= {{52{data_upos[d][31]}}, data_upos[d][31:20]};      //写入立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b0100011: begin //S型命令
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,data_upos[d][14:12],data_upos[d][6:0]}; //写操作码(无funct7)
                            id_reg_rs[d] <= data_upos[d][19:15];    //写入rs1
                            id_reg_rt[d] <= data_upos[d][24:20];    //写入rs2
                            id_reg_rd[d] <= 5'b00000;               //无rd
                            id_reg_im[d] <= {{52{data_upos[d][31]}},data_upos[d][31:25] ,data_upos[d][11:7]};//写入立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b1100011: begin //B型命令
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,data_upos[d][14:12],data_upos[d][6:0]}; //写操作码(无funct7)
                            id_reg_rs[d] <= data_upos[d][19:15];    //写入rs1
                            id_reg_rt[d] <= data_upos[d][24:20];    //写入rs2
                            id_reg_rd[d] <= 5'b00000;               //无rd
                            id_reg_im[d] <= {{51{data_upos[d][31]}}, data_upos[d][31], data_upos[d][7], data_upos[d][30:25], data_upos[d][11:8], 1'b0};//写入立即数(解码后偏移)
                            id_reg_bp[d] <= bp_upos[d];             //分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b0110111: begin //U型命令(1)
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,3'b000,data_upos[d][6:0]};               //写操作码(无funct)
                            id_reg_rs[d] <= 5'b00000;               //无rs1
                            id_reg_rt[d] <= 5'b00000;               //无rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= {{32{data_upos[d][31]}}, data_upos[d][31:12], 12'b0};//写入立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b0010111: begin //U型命令(2)
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,3'b000,data_upos[d][6:0]};               //写操作码(无funct)
                            id_reg_rs[d] <= 5'b00000;               //无rs1
                            id_reg_rt[d] <= 5'b00000;               //无rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= {{32{data_upos[d][31]}}, data_upos[d][31:12], 12'b0};//写入立即数
                            id_reg_bp[d] <= 1'b0;                   //没有分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        7'b1101111: begin //J型命令
                            id_reg_adderss[d] <= adderss_upos[d];   //写adderss
                            id_reg_op[d] <= {7'b0000000,3'b000,data_upos[d][6:0]};               //写操作码(无funct)
                            id_reg_rs[d] <= 5'b00000;               //无rs1
                            id_reg_rt[d] <= 5'b00000;               //无rs2
                            id_reg_rd[d] <= data_upos[d][24:20];    //写入rd
                            id_reg_im[d] <= {{43{data_upos[d][31]}}, data_upos[d][31], data_upos[d][19:12], data_upos[d][20], data_upos[d][30:21], 1'b0}; //写入立即数
                            id_reg_bp[d] <= bp_upos[d];             //分支预测
                            id_reg_en[d] <= 1'b1;                   //有效
                        end

                        default: begin
                            id_reg_en[d] <= 1'b0;                   //无效
                        end
                    endcase
                end
                else begin
                    id_reg_en[d] <= 1'b0;                           //无效
                end
            end
        end
    end

    //寄存器重命名A    
    reg [63:0] ra_reg_adderss[0:3]; //命令PC
    reg [16:0] ra_reg_op [0:3];     //操作码与功能码17位[16:0]{funct7(7),funct3(3),op(7)}
    reg [4:0] ra_reg_rs [0:3];      //读取寄存器1
    reg [4:0] ra_reg_rt [0:3];      //读取寄存器2
    reg [4:0] ra_reg_rd [0:3];      //目标寄存器3
    reg [63:0] ra_reg_im [0:3];     //指令立即数
    reg ra_reg_bp [0:3];            //分支结果
    reg ra_reg_en [0:3];            //有效标识

    //旧表输出  
    reg [4:0] reg_adderss [0:3];    //旧表被覆盖逻辑寄存器
    reg [7:0] reg_data [0:3];       //旧表被覆盖对应值
    reg reg_en[0:3];                //表格有效项
    reg [7:0] reg_now [0:3];        //旧空表

    always @(posedge clk) begin    //R0 寄存器永远为0值
    if (!stop) begin
        for (i = 0; i < 4; i = i + 1) begin    //检查四个指令，写入目标寄存器到RAT
            if (id_reg_en[i]) begin
                if (id_reg_rd != 5'b00000) begin  //目标是否为0值或者无目标寄存器
                    rat_wire_in[i] <= id_reg_rd[i]; 
                    rat_wire_en[i] <= 1'b1;  //有输出

                    reg_adderss[i] <= id_reg_rd[i];     //旧表输出
                    reg_data[i] <= rat_out[(id_reg_rd[i])];
                    reg_en[i] <= 1'b1;    //旧表有效项
                    reg_now[i] <= rat_now[i];  //填写旧空表
                end
                else begin 
                    rat_wire_en[i] <= 1'b0;  //无输出
                    reg_en[i] <= 1'b0;       //旧表无效
                end
            end
            else begin
                rat_wire_en[i] <= 1'b0;  //无输出
                reg_en[i] <= 1'b0;       //旧表无效
            end

            //流水线寄存器前移
            ra_reg_adderss[i] <= id_reg_adderss[i];
            ra_reg_op[i] <= id_reg_op[i];
            ra_reg_rs[i] <= id_reg_rs[i];
            ra_reg_rt[i] <= id_reg_rt[i];
            ra_reg_rd[i] <= id_reg_rd[i];
            ra_reg_im[i] <= id_reg_im[i];
            ra_reg_bp[i] <= id_reg_bp[i];
            ra_reg_en[i] <= id_reg_en[i];
        end
    end
    end

    //重命名后输出（寄存器重命名B）
    reg [63:0] ne_reg_adderss[0:3]; //命令PC
    reg [16:0] ne_reg_op [0:3];     //操作码与功能码17位[16:0]{funct7(7),funct3(3),op(7)}
    reg [7:0] ne_reg_rs [0:3];      //读取寄存器1
    reg [7:0] ne_reg_rt [0:3];      //读取寄存器2
    reg [7:0] ne_reg_rd [0:3];      //目标寄存器3
    reg [63:0] ne_reg_im [0:3];     //指令立即数
    reg ne_reg_bp [0:3];            //分支结果
    reg ne_reg_en [0:3];            //有效标识

    always @(posedge clk) begin     //分批检查4条命令
    if (!stop) begin
        //写入指令其他值
        for (i = 0; i < 4; i = i + 1) begin
            ne_reg_adderss[i] <= ra_reg_adderss[i];
            ne_reg_op[i] <= ra_reg_op[i];
            ne_reg_rd[i] <= reg_data[i];
            ne_reg_im[i] <= ra_reg_im[i];
            ne_reg_bp[i] <= ra_reg_bp[i];
            ne_reg_en[i] <= ra_reg_en[i];
        end

        //命令1检查
        if (ra_reg_en[0]) begin        //如果命令有效
            if (                       //检查是否在旧表值中(rs1)
                (ra_reg_rs[0] == reg_adderss[0])||
                (ra_reg_rs[0] == reg_adderss[1])||
                (ra_reg_rs[0] == reg_adderss[2])||
                (ra_reg_rs[0] == reg_adderss[3])
            ) begin      
                for (d = 0; d < 4; d = d + 1) begin
                    if (ra_reg_rs[0] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rs[0] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rs[0] <= rat_out[(ra_reg_rs[0])];    //直接输出现表
            end

            if (                       //检查是否在旧表值中(rs2)
                (ra_reg_rt[0] == reg_adderss[0])||
                (ra_reg_rt[0] == reg_adderss[1])||
                (ra_reg_rt[0] == reg_adderss[2])||
                (ra_reg_rt[0] == reg_adderss[3])
            ) begin      
                for (d = 0; d < 4; d = d + 1) begin
                    if (ra_reg_rt[0] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rt[0] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rt[0] <= rat_out[(ra_reg_rs[0])];    //直接输出现表
            end
        end

        //命令2检测
        if (ra_reg_en[1]) begin        //如果命令有效（rs1）
            if (ra_reg_rs[1] == reg_adderss[0]) begin  //如果指令1和指令0有依赖
                ne_reg_rs[1] <= reg_now[0];            //第一条的写入
            end
            if (                       //检查是否在旧表值中(rs1)
                (ra_reg_rs[1] == reg_adderss[1])||
                (ra_reg_rs[1] == reg_adderss[2])||
                (ra_reg_rs[1] == reg_adderss[3])
            ) begin      
                for (d = 1; d < 4; d = d + 1) begin
                    if (ra_reg_rs[1] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rs[1] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rs[1] <= rat_out[(ra_reg_rs[1])];    //直接输出现表
            end

            //如果命令有效（rs2）
                if (ra_reg_rt[1] == reg_adderss[0]) begin  //如果指令1和指令0有依赖
                    ne_reg_rt[1] <= reg_now[0];            //第一条的写入
                end
            if (                       //检查是否在旧表值中(rs2)
                (ra_reg_rt[1] == reg_adderss[1])||
                (ra_reg_rt[1] == reg_adderss[2])||
                (ra_reg_rt[1] == reg_adderss[3])
            ) begin      
                for (d = 1; d < 4; d = d + 1) begin
                    if (ra_reg_rt[1] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rt[1] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rt[1] <= rat_out[(ra_reg_rt[1])];    //直接输出现表
            end
        end

        //命令3检测
        if (ra_reg_en[2]) begin        //如果命令有效（rs1）
            if (ra_reg_rs[2] == reg_adderss[0]) begin  //如果指令1和指令0有依赖
                ne_reg_rs[2] <= reg_now[0];            //第一条的写入
            end
            if (ra_reg_rs[2] == reg_adderss[1]) begin
                ne_reg_rs[2] <= reg_now[1];            //第一条的写入
            end
            if (                       //检查是否在旧表值中(rs1)
                (ra_reg_rs[2] == reg_adderss[2])||
                (ra_reg_rs[2] == reg_adderss[3])
            ) begin      
                for (d = 2; d < 4; d = d + 1) begin
                    if (ra_reg_rs[2] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rs[2] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rs[2] <= rat_out[(ra_reg_rs[2])];    //直接输出现表
            end

            //如果命令有效（rs2）
            if (ra_reg_rt[2] == reg_adderss[0]) begin  //如果指令1和指令0有依赖
                ne_reg_rt[2] <= reg_now[0];            //第一条的写入
            end

            if (ra_reg_rt[2] == reg_adderss[1]) begin  //如果指令1和指令0有依赖
                ne_reg_rt[2] <= reg_now[1];            //第一条的写入
            end

            if (                       //检查是否在旧表值中(rs2)
                (ra_reg_rt[2] == reg_adderss[2])||
                (ra_reg_rt[2] == reg_adderss[3])
            ) begin      
                for (d = 2; d < 4; d = d + 1) begin
                    if (ra_reg_rt[2] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rt[2] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rt[2] <= rat_out[(ra_reg_rt[2])];    //直接输出现表
            end
        end

        //命令4检测
        if (ra_reg_en[3]) begin        //如果命令有效（rs1）
            if (ra_reg_rs[3] == reg_adderss[0]) begin  //如果指令1和指令0有依赖
                ne_reg_rs[3] <= reg_now[0];            //第一条的写入
            end
            if (ra_reg_rs[3] == reg_adderss[1]) begin
                ne_reg_rs[3] <= reg_now[1];            //第一条的写入
            end
            if (ra_reg_rs[3] == reg_adderss[2]) begin
                ne_reg_rs[3] <= reg_now[2];            //第一条的写入
            end
            if (                       //检查是否在旧表值中(rs1)
                (ra_reg_rs[3] == reg_adderss[3])
            ) begin      
                for (d = 3; d < 4; d = d + 1) begin
                    if (ra_reg_rs[3] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rs[3] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rs[3] <= rat_out[(ra_reg_rs[3])];    //直接输出现表
            end

            //如果命令有效（rs2）
            if (ra_reg_rt[3] == reg_adderss[0]) begin  //如果指令1和指令0有依赖
                ne_reg_rt[3] <= reg_now[0];            //第一条的写入
            end

            if (ra_reg_rt[3] == reg_adderss[1]) begin  //如果指令1和指令0有依赖
                ne_reg_rt[3] <= reg_now[1];            //第一条的写入
            end

            if (ra_reg_rt[3] == reg_adderss[2]) begin  //如果指令1和指令0有依赖
                ne_reg_rt[3] <= reg_now[2];            //第一条的写入
            end

            if (                       //检查是否在旧表值中(rs2)
                (ra_reg_rt[3] == reg_adderss[3])
            ) begin      
                for (d = 3; d < 4; d = d + 1) begin
                    if (ra_reg_rt[3] == reg_adderss[d]) begin    //寻找匹配的旧表值
                        ne_reg_rt[3] == reg_data[d];             //直接写入
                    end
                end
            end
            else begin    //如果没有在旧表值中
                ne_reg_rt[3] <= rat_out[(ra_reg_rt[3])];    //直接输出现表
            end
        end
    end
    end

    //微操作分发(执行器保留站和ROB)
    
endmodule