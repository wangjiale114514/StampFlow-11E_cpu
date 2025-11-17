//译码
//统一规定rs和rt为输入，rd统一为输出
//rs,rt,rd按前后顺序排
//立即数第一个为输入，第二个为输出（也就是输出rd应该配给译码给rd）
module if_id (
    input wire [31:0] command,                   //命令入口
    input wire [31:0] id_reg_search,            //接收存寄存器数据位
    output reg [4:0]  id_reg,                  //发给寄存器的寻址线          
    input wire clk,                           //时钟信号
    output reg [87:0] command_next,          //处理后的命令：6位操作码 + 5位rs + 5位rt + 5位rd + 32位立即数 + 32位访存地址 + 3位章
    input wire reset                        //复位
);

    always @(posedge reset) begin
        command_next <= {85'b0, 3'b111};
    end

    always @(posedge clk) begin    
        case (command[31:26])
            //算数运算指令
            6'b000000: begin    //000000: ADD rs, rt, rd       // 加法*
                command_next[87:82] <= 6'b000000;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end
            
            6'b000001: begin    //000001: SUB rd, rs, rt    // 减法*
                command_next[87:82] <= 6'b000001; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= command[20:16];
                command_next[71:67] <= command[15:11];
                command_next[66:35] <= 32'b0;
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end
            
            6'b000010: begin    //000010: AND rd, rs, rt    // 与运算*
                command_next[87:82] <= 6'b000010; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= command[20:16];
                command_next[71:67] <= command[15:11];
                command_next[66:35] <= 32'b0;
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end
            
            6'b000011: begin    //000011: OR  rd, rs, rt    // 或运算*
                command_next[87:82] <= 6'b000011; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= command[20:16];
                command_next[71:67] <= command[15:11];
                command_next[66:35] <= 32'b0;
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end
            
            6'b000100: begin    //000100: XOR rd, rs, rt    // 异或运算*
                command_next[87:82] <= 6'b000100; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= command[20:16];
                command_next[71:67] <= command[15:11];
                command_next[66:35] <= 32'b0;
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end
            
            6'b000101: begin    //000101: SLT rs, rt, rd    // 小于置位*
                command_next[87:82] <= 6'b000101; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= command[20:16];
                command_next[71:67] <= command[15:11];
                command_next[66:35] <= 32'b0;
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end
            
            //立即数指令
            6'b000110: begin    //000110: ADDI rs, rd, imm    // 立即数加法
                command_next[87:82] <= 6'b000110; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= 5'b0;
                command_next[71:67] <= command[20:16];
                command_next[66:35] <= {16'b0,command[15:0]};
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end

            6'b000111: begin    //000111: ANDI rt, rs, imm    // 立即数与
                command_next[87:82] <= 6'b000111; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= 5'b0;
                command_next[71:67] <= command[20:16];
                command_next[66:35] <= {16'b0,command[15:0]};
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end

            6'b001000: begin    //001000: ORI  rt, rs, imm    // 立即数或
                command_next[87:82] <= 6'b001000; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= 5'b0;
                command_next[71:67] <= command[20:16];
                command_next[66:35] <= {16'b0,command[15:0]};
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b010;
            end

            6'b001001: begin    //001001: LUI  rt(高6位后面的高5位), imm        // 加载高位立即数
                command_next[87:82] <= 6'b001001; 
                command_next[81:77] <= 5'b0;
                command_next[76:72] <= 5'b0;
                command_next[71:67] <= command[25:21];
                command_next[66:35] <= {11'b0,command[20:0]};
                command_next[34:3]  <= 32'b0;
                command_next[2:0]   <= 3'b110;
            end

            //访存指令           --------------------明天要改这个
//            6'b001010: begin    //001010 W   rs, offset(rt)  // 加载字
//                command_next[87:82] <= 6'b001010; 
//                command_next[81:77] <= 5'b0;
//                command_next[76:72] <= command[25:21];
//                command_next[71:67] <= command[20:16];
//                command_next[66:35] <= 32'b0;
//
//                id_reg = command[20:16];
//                command_next[34:3]  <= id_reg_search;   //访存寄存器
//
//
//                command_next[2:0]   <= 3'b001;
//            end

//            6'b001011: begin    //001011 W   rt, offset(rs)  // 存储字
//                command_next[87:82] <= 6'b001011; 
//                command_next[81:77] <= 5'b0;
//                command_next[76:72] <= command[25:21];
//                command_next[71:67] <= command[20:16];
//                command_next[66:35] <= 32'b0;
//
//                id_reg = command[20:16];
//                command_next[34:3]  <= id_reg_search;   //访存寄存器
//                command_next[2:0]   <= 3'b001;
//            end

            6'b001100: begin    //001100 LB   rt, offset(rs)  // 加载字节
                command_next[87:82] <= 6'b001100; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= 5'b0;
                command_next[71:67] <= command[15:11];
                command_next[66:35] <= 32'b0;

                id_reg = command[20:16];
                command_next[34:3]  <= id_reg_search;   //访存寄存器
                command_next[2:0]   <= 3'b001;
            end

            6'b001101: begin    //001101 SB   rt, offset(rs)  // 存储字节
                command_next[87:82] <= 6'b001101; 
                command_next[81:77] <= command[25:21];
                command_next[76:72] <= 5'b0;
                command_next[71:67] <= command[15:11];
                command_next[66:35] <= 32'b0;

                id_reg = command[20:16];
                command_next[34:3]  <= id_reg_search;   //访存寄存器
                command_next[2:0]   <= 3'b001;
            end

            //分支指令
            6'b001110: begin    //001110 BEQ  rs, rt, offset   // 相等分支*
                command_next[87:82] <= 6'b001110;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b011;          // 章
            end

            6'b001111: begin    //001111 BNE  rs, rt, offset   // 不等分支*
                command_next[87:82] <= 6'b001111;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b011;          // 章
            end

            6'b010000: begin    //010000 BLEZ rs, offset       // 小于等于零分支*
                command_next[87:82] <= 6'b010000;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= 5'b0;                // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b011;          // 章
            end

            6'b010001: begin    //010001 BGTZ rs, offset       // 大于零分支*
                command_next[87:82] <= 6'b010001;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= 5'b0;                // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b011;          // 章
            end

            //跳转指令
            6'b010010: begin    //010010 J    rs               // 直接跳转*
                command_next[87:82] <= 6'b010010;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= 5'b0;                // rt  
                command_next[71:67] <= 5'b0;               // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b011;          // 章
            end

            6'b010011: begin    //010011 JAL  rs rd            // 跳转并链接*
                command_next[87:82] <= 6'b010011;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= 5'b0;                // rt  
                command_next[71:67] <= command[71:67];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            //移位指令
            6'b010110: begin    //010110 SLL  rd, rt, sa       // 逻辑左移*
                command_next[87:82] <= 6'b010110;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b010111: begin    //010111 SRL  rd, rt, sa       // 逻辑右移*
                command_next[87:82] <= 6'b010111;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b011000: begin    //011000 SRA  rd, rt, sa       // 算术右移*
                command_next[87:82] <= 6'b011000;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b011001: begin     //011001 CNM  rd, rt, sa      // 算数左移*
                command_next[87:82] <= 6'b011001;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            //特殊指令
//            6'b011010: begin     //011010 SYSCALL              // 系统调用*
//                command_next[87:82] <= 6'b011010;             // 操作码
//                command_next[81:77] <= 5'b0;                  // rs
//                command_next[76:72] <= 5'b0;                 // rt  
//                command_next[71:67] <= 5'b0;                // rd
//                command_next[66:35] <= 32'b0;             // 立即数
//                command_next[34:3]  <= 32'b0;            // 访存地址
//                command_next[2:0]   <= 3'b011;          // 章
//            end

//            6'b011011: begin     //011011 BREAK                // 断点*
//                command_next[87:82] <= 6'b011011;             // 操作码
//                command_next[81:77] <= 5'b0;                  // rs
//                command_next[76:72] <= 5'b0;                 // rt  
//                command_next[71:67] <= 5'b0;                // rd
//                command_next[66:35] <= 32'b0;             // 立即数
//                command_next[34:3]  <= 32'b0;            // 访存地址
//                command_next[2:0]   <= 3'b010;          // 章
//            end

//            6'b011100: begin     //011100 MFHI rd              // 从HI移动*
//                command_next[87:82] <= 6'b011100;             // 操作码
//                command_next[81:77] <= 5'b0;                  // rs
//                command_next[76:72] <= 5'b0;                 // rt  
//                command_next[71:67] <= command[15:11];     // rd
//                command_next[66:35] <= 32'b0;             // 立即数
//                command_next[34:3]  <= 32'b0;            // 访存地址
//                command_next[2:0]   <= 3'b010;          // 章
//            end

//            6'b011101: begin     //011101 MFLO rd              // 从LO移动*
//                command_next[87:82] <= 6'b011101;             // 操作码
//                command_next[81:77] <= 5'b0;                  // rs
//                command_next[76:72] <= 5'b0;                 // rt  
//                command_next[71:67] <= command[15:11];     // rd
//                command_next[66:35] <= 32'b0;             // 立即数
//                command_next[34:3]  <= 32'b0;            // 访存地址
//                command_next[2:0]   <= 3'b010;          // 章
//            end
            
            //乘除法
            6'b011110: begin    //011110 MULT rs, rt, rd       // 乘法
                command_next[87:82] <= 6'b011110;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b011111: begin    //011111 DIV  rs, rt, rd       // 除法
                command_next[87:82] <= 6'b011111;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end
            
            //浮点数运算
            6'b100000: begin    //100000 FADD rs, rt, rd       //浮点数加法
                command_next[87:82] <= 6'b100000;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b100001: begin    //100001 FSUB rs, rt, rd       //浮点数减法
                command_next[87:82] <= 6'b100001;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b100010: begin    //100010 FMULT rs,rt, rd       //浮点数乘法
                command_next[87:82] <= 6'b100010;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b100011: begin    //100011 FDIV rs, rt, rd       //除法
                command_next[87:82] <= 6'b100011;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b100100: begin    //100100 FUCK rs，rt, rd       //比较>
                command_next[87:82] <= 6'b100100;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b100101: begin    //100101 FKCU rs, rt,rd        //比较<（比较结果会存到rd寄存器）
                command_next[87:82] <= 6'b100101;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b100110: begin    //100110 FKCK rs, rt, rd       //比较=
                command_next[87:82] <= 6'b100110;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b100111: begin    //100111 FKNK rs, rt, rd       //比较不等于
                command_next[87:82] <= 6'b100111;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= command[20:16];      // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b101000: begin    //101000 FAND rs, rd           //平方运算
                command_next[87:82] <= 6'b101000;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= 5'b00000;            // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

//            6'b101001: begin    //101001 FSAD rs, rd           //开根号
//                command_next[87:82] <= 6'b101001;             // 操作码
//                command_next[81:77] <= command[25:21];       // rs
//                command_next[76:72] <= 5'b00000;            // rt  
//                command_next[71:67] <= command[15:11];     // rd
//                command_next[66:35] <= 32'b0;             // 立即数
//                command_next[34:3]  <= 32'b0;            // 访存地址
//                command_next[2:0]   <= 3'b010;          // 章
//            end

            //补充缺失命令
            6'b101010: begin    //101010 MOV rs rd             //移动
                command_next[87:82] <= 6'b101010;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= 5'b00000;            // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            6'b101100: begin    //101100 NOT rs rd             //取反
                command_next[87:82] <= 6'b101100;             // 操作码
                command_next[81:77] <= command[25:21];       // rs
                command_next[76:72] <= 5'b00000;            // rt  
                command_next[71:67] <= command[15:11];     // rd
                command_next[66:35] <= 32'b0;             // 立即数
                command_next[34:3]  <= 32'b0;            // 访存地址
                command_next[2:0]   <= 3'b010;          // 章
            end

            default: begin
                command_next = {85'b0, 3'b111};
            end
        endcase
    end

endmodule 