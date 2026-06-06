module main
(
    input   clk_50M, rstn,
    input   uart_rx,
    output  clk_100M,
    output  [13:0] signal,
    output  [5:0]   sel,
    output  [7:0]   seg,
    output  [7:0]  ctw,
    output  reg [7:0]  last_data
);
    pll pll_inst
    (
        .inclk0(clk_50M),
        .c0(clk_100M)
    );

    wire [7:0] uart_data;
    wire uart_done;
    UARTReceiver uart_receiver_inst
    (
        .clk(clk_100M),
        .rstn(rstn),
        .rx(uart_rx),
        .data(uart_data),
        .done(uart_done)
    );

    reg [23:0] uart_history_data = 24'd0;
    always @(posedge clk_100M or negedge rstn) begin
        if (!rstn) begin
            uart_history_data <= 24'd0;
            last_data <= 8'd0;
        end
        else begin
            if (uart_done) begin
                uart_history_data <= {uart_history_data[15:0], uart_data};  // 将新数据添加到历史数据的末尾
                last_data <= uart_data[7:0];  // 更新输出的最新数据
            end
        end
    end

    wire [23:0] freq1, freq2, param;
    wire parse_done;
    UARTParser uart_parser_inst
    (
        .clk(clk_100M),
        .rstn(rstn),
        .uart_data(uart_data),
        .uart_done(uart_done),
        .parse_done(parse_done),
        .ctw(ctw),
        .freq1(freq1),
        .freq2(freq2),
        .param(param)
    );

    reg [23:0] method0_freq = 24'd1000;
    reg [7:0] method0_waveform = 8'd0;

    reg [23:0] method1_freq_carry = 24'd1000_000;
    reg [23:0] method1_freq_mod = 24'd1000;
    reg [7:0] method1_am_rate = 8'd100;
    reg [23:0] method1_fm_offset = 24'd5000;

    reg [23:0] method2_freq_carry = 24'd1000_000;
    reg [15:0] method2_bitrate = 16'd10_000;
    reg [7:0] method2_digital_signal = 8'b00000000;

    wire [13:0] method0_signal, method1_signal, method2_signal;
    reg [1:0] out_channel = 2'b11;
    always @(posedge clk_100M or negedge rstn) begin
        if (!rstn) begin
            out_channel <= 2'b11;
        end
        else begin
            if (parse_done) begin
                // 参数存储：无论 ctw[0] 状态，都应保存解析出的参数
                case (ctw[6:5])
                    2'b00: begin
                        method0_freq <= freq1;
                        method0_waveform <= param[7:0];
                    end
                    2'b01: begin
                        method1_freq_carry <= freq1;
                        method1_freq_mod <= freq2;
                        method1_am_rate <= param[7:0];
                        method1_fm_offset <= param;
                    end
                    2'b10: begin
                        method2_freq_carry <= freq1;
                        method2_bitrate <= freq2[15:0];
                        method2_digital_signal <= param[7:0];
                    end
                    default: ;
                endcase

                // 输出通道控制：仅 ctw[0]=1 时开启对应通道
                if (ctw[0]) begin
                    case (ctw[6:5])
                        2'b00: out_channel <= 2'b00;
                        2'b01: out_channel <= 2'b01;
                        2'b10: out_channel <= 2'b10;
                        default: out_channel <= 2'b11;
                    endcase
                end
                else begin
                    out_channel <= 2'b11;  // 停止输出
                end
            end
        end
    end

    assign signal = (out_channel == 2'b00) ? method0_signal :
                    (out_channel == 2'b01) ? method1_signal :
                    (out_channel == 2'b10) ? method2_signal :
                    14'b00000000000000;  // 默认输出0

    wire clk_1kHz;
    DIV #(50_000) div_1kHz_inst
    (
        .clk(clk_50M),
        .rstn(rstn),
        .clk_div(clk_1kHz)
    );

    HEXDGT hex_dgt_inst
    (
        .clk(clk_1kHz),
        .rstn(rstn),
        .hex(uart_history_data),
        .dots(6'b010101),
        .sel(sel),
        .seg(seg)
    );

    SignalGenerator signal_gen_inst
    (
        .clk100M(clk_100M),
        .rstn(rstn),
        .freq(method0_freq),
        .signal(method0_signal)
    );
endmodule


module SignalGenerator
(
    input clk100M, rstn,
    input [23:0] freq,  // 频率，单位Hz
    output [13:0] signal
);
    parameter FIXED_WIDTH = 38;  // 相位累加器定点数宽度
    parameter PHASE_WIDTH = FIXED_WIDTH + 12;  // 相位累加器总宽度
    parameter CLK_FREQ = 100_000_000;  // 时钟频率，单位Hz
    reg [PHASE_WIDTH-1:0] phase = 0;
    reg [11:0] addr = 0;

    localparam [31:0] PHASE_K = (64'd1 << PHASE_WIDTH) / CLK_FREQ;
    wire [PHASE_WIDTH-1:0] phase_increment = freq * PHASE_K;  // 计算相位增量

    always @(posedge clk100M or negedge rstn) begin
        if (!rstn) begin
            phase <= 0;
            addr <= 0;
        end
        else begin
            phase <= phase + phase_increment;
            addr <= phase[PHASE_WIDTH-1:PHASE_WIDTH-12];  // 解除定点数位移
        end
    end

    sin_rom rom(
        .address(addr),
        .clock(clk100M),
        .q(signal)
    );
endmodule

module UARTParser
(
    input clk, rstn,
    input [7:0] uart_data,
    input uart_done,
    output reg parse_done,
    output reg [7:0] ctw, 
    output reg [23:0] freq1,  // 复用为基础频率/载波频率
    output reg [23:0] freq2,  // 复用为调制频率/低两位表示码率
    output reg [23:0] param  // 复用为FM频率偏移/最低字节表示波形类型/AM调制度/数字调制信号
);
    wire uart_done_edge;

    PosedgeDetector uart_done_detector
    (
        .clk(clk),
        .rstn(rstn),
        .signal_sync(uart_done),
        .signal_posedge(uart_done_edge)
    );

    reg [3:0] byte_index = 4'd0;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ctw <= 8'd0;
            freq1 <= 24'd0;
            freq2 <= 24'd0;
            param <= 24'd0;
            byte_index <= 4'd0;
            parse_done <= 1'b0;
        end
        else begin
            parse_done <= 1'b0;
            if (uart_done_edge) begin
                case (byte_index)
                    4'd0: ctw <= uart_data;
                    4'd1, 4'd2, 4'd3: freq1 <= {uart_data, freq1[23:8]};
                    4'd4, 4'd5, 4'd6: freq2 <= {uart_data, freq2[23:8]};
                    4'd7, 4'd8, 4'd9: param <= {uart_data, param[23:8]};
                    default: byte_index <= 4'd0;
                endcase

                if (byte_index == 4'd9) begin
                    parse_done <= 1'b1;
                    byte_index <= 4'd0;
                end
                else begin
                    byte_index <= byte_index + 1'b1;
                end
            end
        end
    end
endmodule

