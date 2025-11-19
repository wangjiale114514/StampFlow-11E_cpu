module testbench;
    reg clk;
    reg reset;
    
    // 声明输出线网
    wire [87:0] reg_out_0, reg_out_1, reg_out_2, reg_out_3;
    wire [87:0] reg_out_4, reg_out_5, reg_out_6, reg_out_7;
    wire [31:0] pc_out;

    wire [31:0] addr_a_read;    //if id
    wire [87:0] command_next;

    //alu可运行指令列表    --新加
    wire [23:0] reg_start_flat;

    //alu的rs位输出
    wire [4:0] reg_search_out3;
    wire [31:0] reg_out3;
    //alu的rt位输出
    wire [4:0] reg_search_out4;        //A位_读取寄存器内容寻址
    wire [31:0] reg_out4;             //A位_读取寄存器堆的输出内容
    //alu的rd位输出
    wire [4:0] reg_search_in3;      //A位_写入寻址
    wire [31:0] reg_in3;           //A位_写入内容
    wire reg_in3_start;            //A位_写入势能 

    //汇总信号
    wire [23:0] conveyor_stamp_flat;
    wire [7:0] conveyor_stamp_in;
    wire [39:0] conveyor_take_flat;
    wire [7:0] conveyor_take_in;

    //测试寄存器输出
    wire [31:0] ceshi_out;

    //alu输出
    wire [23:0] alu_stamp_flat;
    wire [7:0] alu_stamp_in;
    
    // 实例化顶层CPU - 补全所有端口
    top cpu_top_inst(
        .clk(clk),
        .reset(reset),
        .reg_out_0(reg_out_0),
        .reg_out_1(reg_out_1),
        .reg_out_2(reg_out_2),
        .reg_out_3(reg_out_3),
        .reg_out_4(reg_out_4),
        .reg_out_5(reg_out_5),
        .reg_out_6(reg_out_6),
        .reg_out_7(reg_out_7),
        .pc_out(pc_out),
        .addr_a_read(addr_a_read),
        .command_next(command_next),

        //alu可运行指令列表    --新加
        .reg_start_flat(reg_start_flat),

        //alu的rs位输出
        .reg_search_out3(reg_search_out3),
        .reg_out3(reg_out3),
        //alu的rt位输出
        .reg_search_out4(reg_search_out4),        //A位_读取寄存器内容寻址
        .reg_out4(reg_out4),             //A位_读取寄存器堆的输出内容
        //alu的rd位输出
        .reg_search_in3(reg_search_in3),      //A位_写入寻址
        .reg_in3(reg_in3),           //A位_写入内容
        .reg_in3_start(reg_in3_start),            //A位_写入势能 

        //汇总信号
        .conveyor_stamp_flat(conveyor_stamp_flat),
        .conveyor_stamp_in(conveyor_stamp_in),
        .conveyor_take_flat(conveyor_take_flat),
        .conveyor_take_in(conveyor_take_in),

        .ceshi_out(ceshi_out),    //测试寄存器输出

        .alu_stamp_flat(alu_stamp_flat),
        .alu_stamp_in(alu_stamp_in)

    );
    

    initial begin
        clk = 0;
        forever #10 clk = ~clk;  //5个时间翻一次
    end
    
    // 测试过程 - 调整延时时间
    initial begin
        reset = 1'b1;
        #5 reset = 1'b0;  // 200ns后释放复位
        
        // 运行足够长时间观察执行
        #50000;  // 5us仿真时间
        
        $display("仿真完成于时间: %t", $time);
        $finish;
    end
    
    // 监视关键信号 - 修改为显示所有寄存器和PC
    initial begin
        $monitor("Time: %t ns | PC: %h | R0: %h | R1: %h | R2: %h | R3: %h | R4: %h | R5: %h | R6: %h | R7: %h", 
                 $time, 
                 pc_out,
                 reg_out_0,
                 reg_out_1,
                 reg_out_2,
                 reg_out_3,
                 reg_out_4,
                 reg_out_5,
                 reg_out_6,
                 reg_out_7);
    end
    
    // 生成VCD文件用于调试
    initial begin
        $dumpfile("cpu_sim.vcd");
        $dumpvars(0, testbench);
    end
    
    // 添加周期计数
    integer cycle_count = 0;
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count % 10 == 0) 
            $display("Cycle: %d, Time: %t ns", cycle_count, $time);
    end
endmodule