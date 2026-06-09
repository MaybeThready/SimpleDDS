module main
(
    input   clk_50M, rstn,
    input   uart_rx,
    output  clk_100M,
    output  [13:0] signal,
    output  [5:0]   sel,
    output  [7:0]   seg,
    output  [7:0]  ctw,
    output  reg [7:0]  last_data,
    output  bin_signal
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
    reg method1_mode = 1'b0;

    reg [23:0] method2_freq_carry = 24'd1000_000;
    reg [15:0] method2_bitrate = 16'd10_000;
    reg [7:0] method2_digital_signal = 8'b00000000;
    reg method2_mode = 1'b0;

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
                        method1_mode <= ctw[4];
                    end
                    2'b10: begin
                        method2_freq_carry <= freq1;
                        method2_bitrate <= freq2[15:0];
                        method2_digital_signal <= param[7:0];
                        method2_mode <= ctw[4];
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

    assign signal = ~((out_channel == 2'b00) ? method0_signal :
                    (out_channel == 2'b01) ? method1_signal :
                    (out_channel == 2'b10) ? method2_signal :
                    14'b00000000000000);  // 默认输出0

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

    Method0Output method0_output_inst
    (
        .clk100M(clk_100M),
        .rstn(rstn),
        .freq(method0_freq),
        .waveform(method0_waveform),
        .signal(method0_signal)
    );

    Method1Output method1_output_inst
    (
        .clk100M(clk_100M),
        .rstn(rstn),
        .mode(method1_mode),
        .freq_carry(method1_freq_carry),
        .freq_mod(method1_freq_mod),
        .am_rate(method1_am_rate),
        .fm_offset(method1_fm_offset),
        .signal(method1_signal)
    );

    Method2Output method2_output_inst
    (
        .clk100M(clk_100M),
        .rstn(rstn),
        .mode(method2_mode),
        .freq_carry(method2_freq_carry),
        .bitrate(method2_bitrate),
        .digital_signal(method2_digital_signal),
        .signal(method2_signal),
        .bin_signal(bin_signal)
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

module SinWaveGenerator
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

module Method0Output
(
    input clk100M, rstn,
    input [23:0] freq,  // 基础频率
    input [7:0] waveform,  // 波形类型
    output [13:0] signal
);
    wire [13:0] sin_signal;
    SinWaveGenerator sin_gen_inst
    (
        .clk100M(clk100M),
        .rstn(rstn),
        .freq(freq),
        .signal(sin_signal)
    );

    assign signal = (waveform == 8'd0) ? sin_signal : 14'b00000000000000;  // 根据波形类型选择输出
endmodule

module Method1Output
(
    input clk100M, rstn,
    input mode,  // 0: AM, 1: FM
    input [23:0] freq_carry,  // 载波频率
    input [23:0] freq_mod,    // 调制频率
    input [7:0] am_rate,      // AM调制度
    input [23:0] fm_offset,   // FM频率偏移
    output [13:0] signal
);
    localparam integer FREQ_Q = 14;
    localparam integer RATE_Q = 8;
    localparam integer WIDTH = FREQ_Q + RATE_Q + 22 + 2;

    ////// FM调制频率计算
    reg signed [39:0] sgn_fm_freq;
    wire [23:0] fm_freq;
    wire [23:0] carry_freq_sel;
    wire [13:0] carry_signal;
    wire [13:0] mod_signal;
    wire signed [39:0] sgn_mod_signal_fm;

    assign sgn_mod_signal_fm = $signed({{(40 - 14){1'b0}}, mod_signal}) - $signed(40'd8192);
    always @(posedge clk100M or negedge rstn) begin
        if (!rstn)
            sgn_fm_freq <= $signed({16'b0, freq_carry});
        else
            sgn_fm_freq <= $signed({16'b0, freq_carry}) + ((sgn_mod_signal_fm * $signed({16'b0, fm_offset})) >>> 13);
    end
    assign fm_freq = sgn_fm_freq[23:0];

    // FM模式复用载波DDS，减少一个ROM实例
    assign carry_freq_sel = (mode == 1'b1) ? fm_freq : freq_carry;
    SinWaveGenerator carry_gen_inst
    (
        .clk100M(clk100M),
        .rstn(rstn),
        .freq(carry_freq_sel),
        .signal(carry_signal)
    );

    SinWaveGenerator mod_gen_inst
    (
        .clk100M(clk100M),
        .rstn(rstn),
        .freq(freq_mod),
        .signal(mod_signal)
    );

    wire signed [WIDTH-1:0] sgn_mod_signal;
    wire signed [WIDTH-1:0] sgn_carry_signal;
    wire signed [WIDTH-1:0] sgn_am_rate;

    assign sgn_mod_signal = {{(WIDTH - 14){1'b0}}, mod_signal};
    assign sgn_carry_signal = {{(WIDTH - 14){1'b0}}, carry_signal};
    assign sgn_am_rate = {{(WIDTH - 8){1'b0}}, am_rate};

    // ============================================================
    // Pipeline Stage 1: 并行计算 ma, A, carry_centered（组合逻辑 → 寄存器）
    // ============================================================
    wire signed [WIDTH-1:0] ma_comb;
    wire signed [WIDTH-1:0] A_comb;
    wire signed [WIDTH-1:0] carry_centered_comb;

    assign ma_comb = (sgn_am_rate <<< RATE_Q) / 100;
    assign A_comb = 2 * (sgn_mod_signal <<< FREQ_Q) / 16383 - $signed(64'b1 << FREQ_Q);
    assign carry_centered_comb = $signed(sgn_carry_signal) - $signed({{(WIDTH-14){1'b0}}, 14'd8192});

    reg signed [WIDTH-1:0] ma_r, A_r, carry_centered_r;
    always @(posedge clk100M or negedge rstn) begin
        if (!rstn) begin
            ma_r <= 0;
            A_r <= 0;
            carry_centered_r <= 0;
        end else begin
            ma_r <= ma_comb;
            A_r <= A_comb;
            carry_centered_r <= carry_centered_comb;
        end
    end

    // ============================================================
    // Pipeline Stage 2: coeff = 1 + ma*A（组合逻辑 → 寄存器），延迟 carry_centered
    // ============================================================
    wire signed [WIDTH-1:0] coeff_comb;
    assign coeff_comb = $signed(64'b1 << (FREQ_Q + RATE_Q)) + (ma_r * A_r);

    reg signed [WIDTH-1:0] coeff_r, carry_centered_r2;
    always @(posedge clk100M or negedge rstn) begin
        if (!rstn) begin
            coeff_r <= $signed(64'b1 << (FREQ_Q + RATE_Q));  // 1.0 in Q38（无调制）
            carry_centered_r2 <= 0;
        end else begin
            coeff_r <= coeff_comb;
            carry_centered_r2 <= carry_centered_r;
        end
    end

    // ============================================================
    // Pipeline Stage 3: 调制运算 + 限幅（组合逻辑 → 寄存器输出）
    // ============================================================
    wire signed [WIDTH-1:0] am_modulated_comb;
    wire signed [WIDTH-1:0] am_with_dc_comb;

    assign am_modulated_comb = (carry_centered_r2 * coeff_r) >>> (FREQ_Q + RATE_Q + 1);
    assign am_with_dc_comb = am_modulated_comb + $signed({{(WIDTH-14){1'b0}}, 14'd8192});

    wire [13:0] am_saturated_comb;
    assign am_saturated_comb = am_with_dc_comb[WIDTH-1] ? 14'd0 :
                               (|am_with_dc_comb[WIDTH-2:14]) ? 14'd16383 :
                               am_with_dc_comb[13:0];

    reg [13:0] am_output_r;
    always @(posedge clk100M or negedge rstn) begin
        if (!rstn)
            am_output_r <= 14'd8192;
        else
            am_output_r <= am_saturated_comb;
    end

    wire [13:0] fm_output_r;
    assign fm_output_r = carry_signal;

    assign signal = (mode == 1'b0) ? am_output_r :
                    (mode == 1'b1) ? fm_output_r :
                    14'b00000000000000;  // 根据调制模式选择输出
endmodule

module Method2Output
(
    input clk100M, rstn,
    input mode,  // 0: ASK, 1: PSK
    input [23:0] freq_carry,  // 载波频率
    input [15:0] bitrate,    // 比特率
    input [7:0] digital_signal,  // 数字信号（每位代表一个数字调制的输入）
    output [13:0] signal,
    output bin_signal
);
    parameter CLK_FREQ = 100_000_000;
    wire [13:0] carry_signal;
    SinWaveGenerator carry_gen_inst
    (
        .clk100M(clk100M),
        .rstn(rstn),
        .freq(freq_carry),
        .signal(carry_signal)
    );

    wire [13:0] ask_signal, psk_signal;
    wire [31:0] period = CLK_FREQ / bitrate;
    reg [31:0] bit_timer = 0;
    reg [2:0] bit_index = 0;
    reg current_bit = 0;
    always @(posedge clk100M or negedge rstn) begin
        if (!rstn) begin
            bit_timer <= 0;
            bit_index <= 0;
            current_bit <= 0;
        end
        else begin
            if (bit_timer >= period) begin
                bit_timer <= 0;
                current_bit <= digital_signal[bit_index];
                bit_index <= (bit_index + 1) % 8;
            end
            else begin
                bit_timer <= bit_timer + 1;
            end
        end
    end

    assign ask_signal = current_bit ? carry_signal : 14'b00000000000000;
    assign psk_signal = current_bit ? carry_signal : (carry_signal ^ 14'b11111111111111);

    assign signal = (mode == 1'b0) ? ask_signal :
                    (mode == 1'b1) ? psk_signal :
                    14'b00000000000000;  // 根据调制模式选择输出

    assign bin_signal = current_bit;  // 输出当前比特的二进制值
endmodule
