module ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter BYTE_WIDTH = 8,

    parameter BATCH_SIZE = DATA_WIDTH / BYTE_WIDTH
) (
    input clk_i,

    // Port a 
    input  logic [ADDR_WIDTH-1:0] waddr, raddr,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic                  we,
    output logic [DATA_WIDTH-1:0] rdata
);

    logic [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH];

    always @( posedge clk_i ) begin : ram_a
        if(we) begin
            ram[waddr] <= wdata;
        end
        rdata <= ram[raddr];
    end

endmodule: ram
