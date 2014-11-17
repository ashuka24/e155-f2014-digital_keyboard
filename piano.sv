/*	piano.sv
	
	Sebastian Krupa and Ashuka Xue
	Fall 2014
  	skrupa@hmc.edu and axue@hmc.edu
*/

module digital_keyboard(input  logic       sck, sdi, clk,
                        output logic [7:0] wave);

	logic [31:0] q;
	logic sdi,
	logic [7:0] notes, note1, note2, note3;
    
	spi_slave_receive_only spi(sck, sdi, q);
	process_spi proc(sck, clk, q, note1, note2, note3);
	add_notes add(note1, note2, note3, notes);
	attenuation sound(clk, notes, wave);
    

endmodule

// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 
module spi_slave_receive_only(input  logic       sck, //from master
                              input  logic       sdi, //from master 
                              output logic [31:0] q); // data received
	always_ff @(posedge sck)
		q <={q[30:0], sdi}; //shift register
endmodule

module process_spi( input logic         sck, clk,
                    input logic  [31:0]  q,
                    output logic [7:0] note1, note2, note3);
    logic [6:0] cnt = 6'b00_0000;
    logic moved = 1'b0; //makes sure iterator doesn't start until initial signal
	 
	 always_ff @(negedge sck)
		if(cnt == 6'd31)
		begin
			note1 <= q[7:0];
			note2 <= q[15:8];
			note3 <= q[23:16];
			cnt <= '0;
		end
		else
			cnt <= cnt + 1'b1;
			
endmodule

module add_notes(input logic [7:0] note1, note2, note3,
		output logic [7:0] notes);
	logic [9:0] intermed;
	assign intermed = (note1 + note2 + note3);
	assign notes = intermed>>2 + intermed>>4 + intermed>>6; //divide by 3.047 = ~3

endmodule

module attenuation(input  logic       clk,
				   input  logic [7:0] wave,
				   output logic [7:0] attenuated);

	logic [31:0] up = 0';
	logic [3:0] i = 4'd8;
	logic [23:0] count = 0;

	always_ff@(posedge clk)
		begin
		up <= up + 1'b1;

		if (up <= 25'h1312D00) // take 0.5 s on the rise
			begin
				if (count == 22'h2625A0)
					begin
					i <= i - 1'b1;
					count <= 0;
					end
				else 
					begin
					count <= count + 1'b1;
					end
			attenuated <= wave >> i;
			end			
		else if (up >= 25'h1312D00 & up <= 25'h2625A00) // one it reaches the top (0.5 s)
			attenuated <= wave;
		else
			begin
			attenuated <= wave << i; // slow down
			if (count == 24'h969680)
					begin
					i <= i + 1'b1;
					count <= 0;
					end
				else 
					begin
					count <= count + 1'b1;
					end
			attenuated <= wave >> i;
			end		
		end
endmodule

