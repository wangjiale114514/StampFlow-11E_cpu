//L2 Cache
//2 MB / 核
//这边因为没有实际参考支撑
module L2_cache (
    input wire clk_a,    //时钟信号a(来自cpu)
    input wire clk_b,    //时钟信号b(来自L2_cache)
    input wire reset,    //复位

    //面向D_cache输出
    input wire [63:0] d_out_address,  //寻址
    output reg [63:0] d_out,          //缓存输出
    output reg d_cache_hit,           //命中标识,输出1代表命中，否则未命中

    //面向D_cache(要添加写缓存行)
    input wire [63:0] in_address,   //面向上层写入寻址
    input wire [63:0] in,           //面向上层写入内容
    input wire in_start,            //面向上层写入势能

    //处理I_cache输出
    input wire [63:0] i_out_address,  //寻址
    output reg [63:0] i_out,          //缓存输出
    output reg i_cache_hit,           //命中标识,输出1代表命中，否则未命中

    //面向L3缓存
    input wire cache_read_start,    //cpu未命中向后拉取请求势能
    input wire [63:0] cache_read,   //需要存入得tag
    input wire [63:0] cache_in,     //未命中接收下层命中信息
    input wire cache_in_start,      //下层命中上传势能

    //系统输出
    output wire [31:0] cache_pc      //cache分配pc
);
    
    integer i;                            //声明循环变量
    reg [128:0] cache_reg_top [0:31];     //上层写入信号缓冲，低位1为可写入
    reg [4:0] cache_reg_top_pc;           //上层向下缓冲pc

    reg [128:0] cache_reg_down;           //面向L3_cache的缓冲,低位为1可写入

    reg [129:0] mem [0:262144];           //数据存储    高64位tag，低64位DATA，数据按偏移算,最后一位是脏数据标记,最高位129位为无效位，拉高1为有效

    //处理D_cache输出
    always @(*) begin
        d_cache_hit = 1'b0;                                                    //初始化为未命中
        for (i = 0; i < 262145; i = i + 1) begin
            if (mem[i][128:65] == d_out_address) begin                         //判断缓存
                if ((mem[i][0] == 1'b0) && (mem[i][129] == 1'b1)) begin        //判断数据是否有效
                    d_out <= mem[i][64:1];                                     //out赋值
                    d_cache_hit <= 1'b1;                                       //表示命中
                end
            end
        end

    end

    //处理I_cache输出
    always @(*) begin
        i_cache_hit = 1'b0;                                                    //初始化为未命中
        for (i = 0; i < 262145; i = i + 1) begin
            if (mem[i][128:65] == i_out_address) begin                         //判断缓存
                if ((mem[i][0] == 1'b0) && (mem[i][129] == 1'b1)) begin        //判断数据是否有效
                    i_out <= mem[i][64:1];                                     //out赋值
                    i_cache_hit <= 1'b1;                                       //表示命中
                end
            end
        end

    end


    //处理D_cache的写入
    always @(posedge clk_a) begin    //来自上层写入缓存行
        if (in_start) begin
            for (i = 0; i < 262145; i = i + 1) begin        //标记脏数据指令块
                if (mem[i][128:65] == in_address) begin     //检测tag是否对上
                    mem[i][0] <= 1'b1;                      //标记脏数据
                end
            end

            cache_reg_top_pc <= cache_reg_top_pc + 1'b1;            //pc加1
            cache_reg_top[cache_reg_top_pc][128:65] <= in_address;  //缓冲内容为要写入的地址 
            cache_reg_top[cache_reg_top_pc][64:1] <= in;            //缓存写入数据
            cache_reg_top[cache_reg_top_pc][0] <= 1'b1;             //缓存标记为可写入
        end
    end

    always @(posedge clk_b) begin                                      //来自载入mem的内容
        for (i = 0; i < 32; i = i + 1) begin                           //31个寄存器
            if (cache_reg_top[i][0] == 1'b1) begin                     //判断是否为需要写入的内容
                mem[cache_pc][128:64] = cache_reg_top[i][128:65];      //写入新的tag
                mem[cache_pc][64:1] = cache_reg_top[i][64:1];          //写入新数据
                mem[cache_pc][129] = 1'b1;                             //写入新数据有效
                mem[cache_pc][0] = 1'b0;                               //写入数据非脏数据
                cache_pc = cache_pc + 1'b1;                            //cache_pc + 1
            end
            
            cache_reg_top[i] = 128'b0;                                 //全部归零
        end

        cache_reg_top_pc = 5'b0;                                       //pc归零
    end

    //面向L3_cache的写入
    always @(posedge cache_in_start) begin          //面向上传势能
        if (cache_read_start) begin
            cache_reg_down[128:65] <= cache_read;   //需要存入得tag
            cache_reg_down[64:1] <= cache_in;       //未命中接收下层命中信息
            cache_reg_down[0] <= 1'b1;              //可写入
        end
    end

    always @(posedge clk_b) begin                   //面向自身的clk频率
        if (cache_reg_down[0] == 1'b1) begin        //面向缓冲区的内容合规性检测
            mem[cache_pc][128:64] = cache_reg_down[128:65];      //写入新的tag
            mem[cache_pc][64:1] = cache_reg_down[64:1];          //写入新数据
            mem[cache_pc][129] = 1'b1;                             //写入新数据有效
            mem[cache_pc][0] = 1'b0;                               //写入数据非脏数据
            cache_pc = cache_pc + 1'b1;                            //cache_pc + 1
        end
    end

    always @(*) begin                         //限制缓存pc行数
        if (cache_pc >= 32'd8192) begin
            cache_pc = 32'b0;                 //超过这个数归零
        end
    end

endmodule