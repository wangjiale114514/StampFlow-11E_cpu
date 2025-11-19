//传送带指令链
module conveyor (
    input wire [87:0] command_in,                   //指令进入端口                    
    input wire conveyor_stop,                      //流水线暂停势能,拉高暂停
    input wire clk,                               //时钟信号

    input wire [23:0] stamp_flat,               //8个寄存器章 [a-h]    扁平
    input wire [7:0] stamp_in,                 //8个寄存器章势能 [a-h]

    input wire [39:0] take_flat,               //写入执行器需要取值的位置  扁平
    input wire [7:0] take_in,                  //写入势能

    output wire [23:0] reg_start_flat,        //可运行指令列表 [a-h]按照顺序输出    扁平 
    output wire [703:0] reg_out_flat,        //各自输出 [a-h]                      扁平

    output reg conveyor_stop_out,          //流水线暂停输出信号

    input wire jump_start,                  //检测跳转势能

    input wire reset                        //复位
);

    integer i, j, k;                         //定义循环变量

    wire [2:0] stamp [7:0];                   //8个寄存器章 [a-h]    扁平
    wire [4:0] take [7:0];                    //写入alu需要取值的位置  扁平
    reg [2:0] reg_start [7:0];                //可运行指令列表 [a-h]按照顺序输出    扁平
    reg [87:0] reg_out [7:0];                 //各自输出 [a-h]                    扁平

    reg  jump_reg;                            //跳转标记位

    assign stamp[0] = stamp_flat[2:0];            //stamp
    assign stamp[1] = stamp_flat[5:3];
    assign stamp[2] = stamp_flat[8:6];
    assign stamp[3] = stamp_flat[11:9];
    assign stamp[4] = stamp_flat[14:12];
    assign stamp[5] = stamp_flat[17:15];
    assign stamp[6] = stamp_flat[20:18];
    assign stamp[7] = stamp_flat[23:21];

    assign take[0] = take_flat[4:0];              //take
    assign take[1] = take_flat[9:5];
    assign take[2] = take_flat[14:10];
    assign take[3] = take_flat[19:15];
    assign take[4] = take_flat[24:20];
    assign take[5] = take_flat[29:25];
    assign take[6] = take_flat[34:30];
    assign take[7] = take_flat[39:35];

    assign reg_start_flat[2:0] = reg_start[0];    //reg_start
    assign reg_start_flat[5:3] = reg_start[1];
    assign reg_start_flat[8:6] = reg_start[2];
    assign reg_start_flat[11:9] = reg_start[3];
    assign reg_start_flat[14:12] = reg_start[4];
    assign reg_start_flat[17:15] = reg_start[5];
    assign reg_start_flat[20:18] = reg_start[6];
    assign reg_start_flat[23:21] = reg_start[7];

    assign reg_out_flat[87:0] = reg_out[0];       //reg_out
    assign reg_out_flat[175:88] = reg_out[1];
    assign reg_out_flat[263:176] = reg_out[2];
    assign reg_out_flat[351:264] = reg_out[3];
    assign reg_out_flat[439:352] = reg_out[4];
    assign reg_out_flat[527:440] = reg_out[5];
    assign reg_out_flat[615:528] = reg_out[6];
    assign reg_out_flat[703:616] = reg_out[7];

    always @(posedge clk or posedge reset) begin    //添加复位按钮
        if (reset) begin                            //检测复位
            for (i = 0; i < 8; i = i + 1) begin   
                reg_out[i] <= {85'b0, 3'b111};
            end
            jump_reg <= 1'b0;
        end
        else begin
        if (!conveyor_stop) begin
            for (i = 0; i < 8; i = i + 1) begin
                reg_out[i + 1] <= reg_out[i];        //传送带滚动
            end

            if (jump_start) begin                         //处理跳转
                reg_out[0] <= {command_in[87:3],3'b111};  // 新指令进入第一级,如果跳转亮了就抛弃掉这一位
                jump_reg <= 1'b1;                         //标记位加1
            end
            else begin
                if (jump_reg) begin                       //如果标记位是亮的那就继续填1，恢复标记位
                    reg_out[0] <= {command_in[87:3],3'b111};
                    jump_reg <= 1'b0;
                end
                else begin
                    reg_out[0] <= command_in;             //一切正常再去填正常的
                end
                
            end

        end

        for (i = 0; i < 8; i = i + 1) begin
            if (stamp_in[i]) begin            //控制章写入的逻辑
                reg_out[i + 1][2:0] <= stamp[i];   //写入stamp某个寄存器的值
            end

            if (take_in[i]) begin
                reg_out[i + 1][34:30] <= take[i];  //写入take某个寄存器的值
            end
        end
        end

    end

always @(*) begin
    for (k = 0; k < 8; k = k + 1) begin
        // 默认所有阶段都不能执行
        reg_start[k][2:0] = 3'b000;
        
        if (reg_out[k][2] == 1'b0) begin // 执行阶段未完成
            reg_start[k][2] = 1'b1; // 默认执行阶段可以执行
            
            // 检查执行阶段的依赖
            begin : conveyor_a
                for (j = k + 1; j < 8; j = j + 1) begin
                    if ((reg_out[j][0] == 1'b0) && 
                        ((reg_out[k][81:77] == reg_out[j][71:67]) || 
                         (reg_out[k][76:72] == reg_out[j][71:67]))) begin
                        reg_start[k][2] = 1'b0; // 有依赖，不能执行
                        disable conveyor_a;
                    end
                end
            end
            
            // 执行阶段未完成时，访存和写回都不能执行
            reg_start[k][1:0] = 2'b00;
            
        end else if (reg_out[k][1] == 1'b0) begin // 执行完成，访存阶段未完成
            reg_start[k][2] = 1'b0; // 执行阶段已完成，不需要再执行
            reg_start[k][1] = 1'b1; // 默认访存阶段可以执行
            
            // 检查访存阶段的依赖
            begin : conveyor_b
                for (j = k + 1; j < 8; j = j + 1) begin
                    if (((reg_out[j][2] == 1'b0) || (reg_out[j][0] == 1'b0) || (reg_out[j][1] == 1'b0)) &&
                        ((reg_out[k][81:77] == reg_out[j][71:67]) || 
                         (reg_out[k][76:72] == reg_out[j][71:67]) ||
                         (reg_out[j][81:77] == reg_out[k][71:67]) || 
                         (reg_out[j][76:72] == reg_out[k][71:67]))) begin
                        reg_start[k][1] = 1'b0; // 有依赖，不能访存
                        disable conveyor_b;
                    end
                end
            end
            
            // 访存阶段未完成时，写回不能执行
            reg_start[k][0] = 1'b0;
            
        end else if (reg_out[k][0] == 1'b0) begin // 执行和访存完成，写回阶段未完成
            reg_start[k][2:1] = 2'b00; // 前两个阶段已完成
            reg_start[k][0] = 1'b1; // 默认写回阶段可以执行
            
            // 检查写回阶段的依赖
            begin : conveyor_c
                for (j = k + 1; j < 8; j = j + 1) begin
                    if (((reg_out[j][0] == 1'b0) || (reg_out[j][1] == 1'b0) || (reg_out[j][2] == 1'b0)) &&
                        ((reg_out[k][71:67] == reg_out[j][71:67]) || 
                         (reg_out[j][81:77] == reg_out[k][71:67]) || 
                         (reg_out[j][76:72] == reg_out[k][71:67]))) begin
                        reg_start[k][0] = 1'b0; // 有依赖，不能写回
                        disable conveyor_c;
                    end
                end
            end
            
        end else begin
            // 所有阶段都已完成
            reg_start[k][2:0] = 3'b000;
        end
    end

    // 流水线暂停控制
    conveyor_stop_out = !(reg_out[7][2:0] == 3'b111);
end

endmodule