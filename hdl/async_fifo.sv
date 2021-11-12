/****************************************************************
 * fifo.sv - first in first out + fifo definitions
 *
 * Author        : Viraj Khatri (vk5@pdx.edu)
 * Last Modified : 12th November, 2021
 *
 * Description   :
 * -----------
 * FIFO not dependant on clk
 ****************************************************************/

module async_fifo
#(
	parameter SIZE=16,
	parameter WIDTH=8,
	
	// do not edit
	parameter SIZE_LOG_2 = $clog2(SIZE)
)
(
	input  logic                rst_n,
	input  logic                read, write,     // active high indicating if command is to be executed
	input  logic [WIDTH-1:0]    write_data,      // incoming data for a write command
	output logic [WIDTH-1:0]    read_data,       // outgoing data for a read command
	output logic [WIDTH-1:0]    stor[SIZE],      // outgoing fifo storage to expose to tb for debugging
	output logic [SIZE_LOG_2:0] write_p, read_p  // SIZE_LOG_2 + 1 because we need to keep track of cycles too
);

// check size calc if user has over-written
localparam CALC_SIZE_LOG_2 = SIZE == 0 ? 1 : $clog2(SIZE);
generate if(CALC_SIZE_LOG_2 != SIZE_LOG_2)
	$fatal("wrong SIZE_LOG_2 passed, please don't pass as this is internally calculated");
endgenerate

// fifo storage
logic [WIDTH-1:0] storage [SIZE];
assign stor = storage;

// stuff to keep track of what is showing in r/w data lines
logic [WIDTH-1:0] read_reg, write_reg;
assign read_data = read_reg;
assign write_reg = write_data;

// keeping track of current write and read positions
logic [SIZE_LOG_2:0] wr_p, rd_p;
assign read_p = rd_p;
assign write_p = wr_p;

always_ff@(negedge rst_n or posedge write or posedge read) begin
	if(!rst_n) begin
		wr_p <= 0;
		rd_p <= 0;
	end else begin
		if (write) begin
			if (rd_p[SIZE_LOG_2-1:0] == wr_p[SIZE_LOG_2-1:0]
				&& rd_p[SIZE_LOG_2] != wr_p[SIZE_LOG_2]) begin // this ensures that read and write are 1 cycle apart
				$display("empty");                             // thus making the fifo full
			end else begin
				storage[wr_p[SIZE_LOG_2-1:0]] = write_reg;

				rw_p++;
				if (wr_p[SIZE_LOG_2-1:0] == SIZE) begin
					wr_p = { ~wr_p[SIZE_LOG_2], '0};
				end
			end
		end
		if (read) begin
			if (rd_p == wr_p) begin // this ensures that read and write are in the same cycles
				$display("empty");   // thus making the fifo empty
			end else begin
				read_reg = storage[rd_p[SIZE_LOG_2-1:0]];

				rd_p++;
				if (rd_p[SIZE_LOG_2-1:0] == SIZE) begin
					rd_p = { ~rd_p[SIZE_LOG_2], '0};
				end
			end
		end
	end
end

endmodule : async_fifo
