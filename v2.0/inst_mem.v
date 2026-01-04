//mem会根据
//L2_cache快要溢出得内容先存入主存中
//读优先，写缓冲
//id阶段分微操作，

// 内存
module inst_mem (
    input wire clk,                      //时钟信号

    input wire [63:0] addr,              //addr地址线
    input wire [7:0] addr_start,         //addr写入势能
    input wire [63:0] addr_write,        //addr写入内容
    output reg [63:0] addr_read,         //addr读取内容
);
    reg [7:0] mem [0:1023];

initial begin        //初始化
    {mem[3], mem[2], mem[1], mem[0]} = 32'b00011011010000001101010110010101;
     
    {mem[7], mem[6], mem[5], mem[4]} = 32'b00011011010000001101010110010101;
    //001001_00001_01101_01011_10101010101
    {mem[11], mem[10], mem[9], mem[8]} = 32'b00100111011011010101110101010101;
    //101010_00001_00000_11010_00000000000
    {mem[15], mem[14], mem[13], mem[12]} = 32'b10101011011000001101000000000000;
end

    always @(*) begin     //out
        addr_read = {mem[addr+7], mem[addr+6], mem[addr+5], mem[addr+4], mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
    end
    
    always @(posedge clk) begin    //write
        if (|addr_start) begin
            if (addr_start[0]) mem[addr]   = addr_write[7:0];
            if (addr_start[1]) mem[addr+1] = addr_write[15:8];
            if (addr_start[2]) mem[addr+2] = addr_write[23:16];
            if (addr_start[3]) mem[addr+3] = addr_write[31:24];
            if (addr_start[4]) mem[addr+4] = addr_write[39:32];
            if (addr_start[5]) mem[addr+5] = addr_write[47:40];
            if (addr_start[6]) mem[addr+6] = addr_write[55:48];
            if (addr_start[7]) mem[addr+7] = addr_write[63:56];
        end
    end
endmodule
