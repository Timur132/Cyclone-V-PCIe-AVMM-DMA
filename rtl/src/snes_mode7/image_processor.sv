module image_processor #(
    parameter DATA_IN_WIDTH = 128,
    parameter COLOR_DEPTH = 16,
    parameter COLS_WIDTH = 8,
    parameter LINES = 224,

    parameter PIXELS_PER_PACKET = DATA_IN_WIDTH / COLOR_DEPTH + (DATA_IN_WIDTH % COLOR_DEPTH != 0),
    parameter COLS = 2 ** COLS_WIDTH,
    parameter LINES_WIDTH = $clog2(LINES),
    parameter PIXEL_WIDTH = COLS_WIDTH + LINES_WIDTH,
    parameter COLOR_WIDTH = $clog2(COLOR_DEPTH)
) (
    input  logic clk,
    input  logic rst_n,

    input  logic [DATA_IN_WIDTH-1:0] data_i ,
    input  logic                     valid_i,
    output logic                     ready_o,

    output logic [DATA_IN_WIDTH-1:0] data_o ,
    output logic                     valid_o,
    input  logic                     ready_i,

    input  logic [15:0]              a_i,
    input  logic [15:0]              b_i,
    input  logic [15:0]              c_i,
    input  logic [15:0]              d_i,
    input  logic [15:0]              x0_i,
    input  logic [15:0]              y0_i,

    output logic [LINES_WIDTH - 1:0] curr_line_o,
    output logic                     irq_o,

    output logic                     assert_o,
    input  logic                     status_i
);
    typedef enum logic [1:0] {
        IDLE,
        WORK,
        WAIT
    } state_t;

    state_t state, state_next;
    logic [PIXEL_WIDTH - 1:0] curr_pix, curr_pix_next;
    logic [COLS_WIDTH - 1:0] curr_col;
    logic [LINES_WIDTH - 1:0] curr_line;

    logic [PIXEL_WIDTH - 1:0] waddr;
    logic [PIXEL_WIDTH - 1:0] raddr;
    logic [COLOR_DEPTH - 1:0] wdata;
    logic [COLOR_DEPTH - 1:0] rdata;

    assign curr_col = curr_pix[COLS_WIDTH - 1:0];
    assign curr_line = curr_pix[COLS_WIDTH+:LINES_WIDTH];
    assign curr_line_o = curr_line;

    ram #(
        .DATA_WIDTH(COLOR_DEPTH),
        .ADDR_WIDTH(PIXEL_WIDTH)
    ) framebuffer (
        .clk_i(clk),
        .waddr(waddr),
        .raddr(raddr),
        .wdata(wdata),
        .we(1),
        .rdata(rdata)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            curr_pix <= '0;
        end else begin
            state <= state_next;
            curr_pix <= curr_pix_next;
        end

    end

    always_comb begin
        state_next = state;
        case (state)
            default: begin
                if (valid_i)
                    state_next = WORK;
            end
            WORK: begin
                if (curr_pix >= COLS - 1)
                    state_next = WAIT;
            end
            WAIT: begin
                if (~status_i)
                    state_next = IDLE;
            end
        endcase

        case (state)
            default: begin
            end
            WORK: begin
                wdata = data_i[curr_pix[2:0] << COLOR_WIDTH +:COLOR_DEPTH];
                curr_pix_next = curr_pix + 1;
            end
            WAIT: begin
            end
        endcase
    end

endmodule

module trans_image #(
    parameter COLOR_DEPTH = 16,
    parameter COLS_WIDTH = 8,
    parameter LINES = 224,

    parameter COLS = 2 ** COLS_WIDTH,
    parameter LINES_WIDTH = $clog2(LINES)
) (
    input                            clk,
    input                            rst_n,

    input  logic [15:0]              a_i,
    input  logic [15:0]              b_i,
    input  logic [15:0]              c_i,
    input  logic [15:0]              d_i,
    input  logic [15:0]              x0_i,
    input  logic [15:0]              y0_i,
    input  logic [COLS_WIDTH - 1:0]  x_i,
    input  logic [LINES_WIDTH - 1:0] y_i,

    output logic [COLS_WIDTH - 1:0]  x_o,
    output logic [LINES_WIDTH - 1:0] y_o,

    input  logic                     valid_i,
    output logic                     valid_o
);
    logic [COLS_WIDTH  + 8 - 1:0]   xd;
    logic [LINES_WIDTH + 8 - 1:0]   yd;
    logic [COLS_WIDTH  + 8 + 16 - 1:0] a;
    logic [LINES_WIDTH + 8 + 16 - 1:0] b;
    logic [COLS_WIDTH  + 8 + 16 - 1:0] c;
    logic [LINES_WIDTH + 8 + 16 - 1:0] d;
    logic [2:0]                valid;

    assign valid_o = valid[2];

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid[0:2] <= '0;
            xd         <= '0;
            yd         <= '0;
            a          <= '0;
            b          <= '0;
            c          <= '0;
            d          <= '0;
            x_o        <= '0;
            y_o        <= '0;
        end else begin
            xd <= {x_i, 8'h0} - x0_i;
            yd <= {y_i, 8'h0} - y0_i;
            valid[0] <= valid_i;

            a <= (a_i * xd);
            b <= (b_i * yd);
            c <= (c_i * xd);
            d <= (d_i * yd);
            valid[1] <= valid[0];

            x_o <= (a + b + (x0_i << 8)) >> 16;
            y_o <= (c + d + (y0_i << 8)) >> 16;
            valid[2] <= valid[1];
        end
    end
endmodule
