//pc加法器
module pc_adder (                           //pc加法器
    input wire clk,                        //时钟
    input wire reset,                     //复位  拉高复位
    input wire [31:0] pc_jump,           //跳转偏移量
    input wire jump_start,              //跳转势能
    input wire pc_stop,                //流水线暂停
    output reg [31:0] pc_out          //当前的pc的值
);
    reg [31:0] next_pc;

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            pc_out <= 32'h0000_0000;
        end

        else begin
            if (pc_stop) begin
                pc_out <= pc_out;
            end

            else begin
                if (jump_start) begin
                    next_pc = pc_out - 32'b0000000000000000000000000001000 + pc_jump;    //计算跳转，-8还原两个周期前的跳转指令的真实位置
                    pc_out <= next_pc;
                end

                else begin
                    next_pc = pc_out + 32'd4;
                    pc_out <= next_pc;
                end
            end
        end
    end

endmodule

