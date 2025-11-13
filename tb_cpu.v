`timescale 1ns/1ns   

module testbench;
    reg clk;
    reg reset;
    
    // 实例化顶层CPU
    top cpu_top_inst(
        .clk(clk),
        .reset(reset)
    );
    

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  //5个时间翻一次
    end
    
    // 测试过程 - 调整延时时间
    initial begin
        reset = 1'b1;
        #200 reset = 1'b0;  // 200ns后释放复位
        
        // 运行足够长时间观察执行
        #5000;  // 5us仿真时间
        
        $display("仿真完成于时间: %t", $time);
        $finish;
    end
    
    // 监视关键信号
    initial begin
        $monitor("Time: %t ns, PC: %h, Reset: %b", 
                 $time, testbench.cpu_top_inst.pc_out, reset);
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