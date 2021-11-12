/****************************************************************
 * sync_fifo.sv - synchronous fifo
 *
 * Author        : Viraj Khatri (vk5@pdx.edu)
 * Last Modified : 21st October, 2021
 *
 * Description   :
 * -----------
 * implements a n-bit fifo controller + package with definitions
 * if required
 ****************************************************************/

package fifo_defs;
endpackage : fifo_defs

module sync_fifo
#(
	parameter SIZE=16,
	parameter WIDTH=8,
	
	// do not edit
	parameter SIZE_LOG_2 = $clog2(SIZE)
)
(
	input  logic clk,rst_n,
	input  logic read, write,            // active high indicating if command is to be executed
	                                     // on this clock cycle
	input  logic [WIDTH-1:0] write_data, // incoming data for a write command
	output logic [WIDTH-1:0] read_data,  // outgoing data for a read command
	output logic [WIDTH-1:0] stor[SIZE], // outgoing fifo storage to expose to tb for debugging
	output logic [SIZE_LOG_2-1:0] write_p, read_p
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

// signals to keep track of status of fifo
logic full, empty = 0;

// keeping track of current write and read positions
logic [SIZE_LOG_2-1:0] wr_p, rd_p;
assign read_p = rd_p;
assign write_p = wr_p;

// ff block with decision-making
always_ff@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		full <= 0;
		empty <= 0;
		wr_p <= 0;
		rd_p <= 0;
	end else begin
		// read and write are not if-else because high performance fifo
		// should be able to do both at the same time if commands arrive at
		// at the same time

		// what to do on a read command
		if (read) begin
			if (write) begin // read+write in same clock cycle, we don't need to check anything
					read_reg <= write_data;
					if (rd_p==SIZE-1) rd_p <= 0;
					else rd_p <= rd_p+1;
			end else begin
				if (full) begin // reading from a full fifo will open up 1 slot
					full <= 0;
					read_reg <= storage[rd_p];
					if (rd_p==SIZE-1) rd_p <= 0;
					else rd_p <= rd_p+1;
				end else if (wr_p == rd_p) begin // if fifo is not full and ptrs are equal, fifo is empty
					empty <= 1;
					$display("fifo empty, can't read");
				end else begin // if fifo not full and ptrs are unequal, no issues
					empty <= 0;
					read_reg <= storage[rd_p];
					if (rd_p==SIZE-1) rd_p <= 0;
					else rd_p <= rd_p+1;
				end
			end
		end else begin
			read_reg <= 0;
		end

		// what to do on a write command
		if (write) begin
			if (read) begin // read+write together means we don't need to check anything
				storage[wr_p] <= write_data; // write data and move ptr
				if (wr_p==SIZE-1) wr_p <= 0;
				else wr_p <= wr_p+1;
			end else begin
				if (empty) begin // writing to empty fifo will make it not-empty
					empty <= 0;
					storage[wr_p] <= write_data;
					if (wr_p==SIZE-1) wr_p <= 0;
					else wr_p <= wr_p+1;
				end else if (wr_p == rd_p) begin // if fifo non empty and ptrs equal, fifo now full
					$display("fifo full, wait for read before writing");
					full <= 1;
				end else begin // if fifo non empty and ptrs unequal, no issues
					full <= 0;
					storage[wr_p] <= write_data;
					if (wr_p==SIZE-1) wr_p <= 0;
					else wr_p <= wr_p+1;
				end
			end
		end

	end
end

endmodule : sync_fifo
