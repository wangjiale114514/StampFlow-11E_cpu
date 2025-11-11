// 内存
module inst_mem (
    input wire clk,                             //时钟信号

    input wire [31:0] addr_a,                 //addr_a位的地址线
    input wire [3:0] addr_a_start,           //addr_a写入势能
    input wire [31:0] addr_a_write,         //addr_a写入内容
    output reg [31:0] addr_a_read,         //addr_a读取内容    //直接与if_id阶段的解码指令入口相连

    input wire [31:0] addr_b,            //addr_b地址线    //imm访存
    input wire [3:0] addr_b_start,      //addr_b写入势能
    input wire [31:0] addr_b_write,    //addr_b写入内容
    output reg [31:0] addr_b_read     //addr_b读取内容
);
    reg [7:0] mem [0:1023];

initial begin        //初始化
    {mem[3], mem[2], mem[1], mem[0]} = 32'h00000013;  // nop
    {mem[7], mem[6], mem[5], mem[4]} = 32'h00400093;  // addi x1, x0, 4
end

    always @(*) begin
        addr_a_read = {mem[addr_a+3], mem[addr_a+2], mem[addr_a+1], mem[addr_a]};
    end
    
    always @(posedge clk) begin
        if (|addr_a_start) begin
            if (addr_a_start[0]) mem[addr_a]   = addr_a_write[7:0];
            if (addr_a_start[1]) mem[addr_a+1] = addr_a_write[15:8];
            if (addr_a_start[2]) mem[addr_a+2] = addr_a_write[23:16];
            if (addr_a_start[3]) mem[addr_a+3] = addr_a_write[31:24];
        end
    end
    
    always @(*) begin
        addr_b_read = {mem[addr_b+3], mem[addr_b+2], mem[addr_b+1], mem[addr_b]};
    end

    always @(posedge clk) begin
        if (|addr_b_start) begin  
            if (addr_b_start[0]) mem[addr_b]   = addr_b_write[7:0];
            if (addr_b_start[1]) mem[addr_b+1] = addr_b_write[15:8];
            if (addr_b_start[2]) mem[addr_b+2] = addr_b_write[23:16];
            if (addr_b_start[3]) mem[addr_b+3] = addr_b_write[31:24];
        end
    end


endmodule
