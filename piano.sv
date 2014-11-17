/*	piano.sv
	
	Sebastian Krupa and Ashuka Xue
	Fall 2014
  	skrupa@hmc.edu and axue@hmc.edu
*/

module piano(input  logic       sck, sdi, clk,
             output logic [7:0] wave);

	logic [31:0] q;
	logic [7:0] notes, note1, note2, note3;
    
	spi_slave_receive_only spi(sck, sdi, q);
	process_spi proc(sck, q, note1, note2, note3, notescount);
	add_notes add(note1, note2, note3, notescount, notes);
	attenuation sound(clk, notes, wave);
    

endmodule

// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 
module spi_slave_receive_only(input  logic        sck, //from master
                              input  logic     v  sdi, //from master 
                              output logic [31:0] q); // data received
	always_ff @(posedge sck)
		q <={q[30:0], sdi}; //shift register
endmodule

module process_spi( input logic         sck,
                    input logic  [31:0] q,
                    output logic [7:0]  note1, note2, note3,
                    output logic [1:0]  notescount);
    logic [6:0] cnt = 6'b00_0000; 
    //logic moved = 1'b0; //makes sure iterator doesn't start until initial signal
	 
	 always_ff @(negedge sck)
		if(cnt == 6'd31) // read the note after the entire 32 bit number has come in 
		begin
			note1 <= q[7:0];
			note2 <= q[15:8];
			note3 <= q[23:16];
			notescount <= q[24:25]
			cnt <= '0;
		end
		else
			cnt <= cnt + 1'b1;
			
endmodule

module add_notes(input logic [7:0] note1, note2, note3,
				 input logic [1:0] notescount,
				 output logic [7:0] notes);
	// adds the three notes together (if there are three) and makes sure the amplitude doesn't change

	logic [9:0] intermed;
	assign intermed = (note1 + note2 + note3);

	always_comb 
		if (notescount == 2'b01)
			notes = intermed;
		else if (notescount == 2'b10)
			notes = intermed>>1;
		else if (notescount == 2'b11)
			notes = intermed>>2 + intermed>>4 + intermed>>6 + intermed>>8; //divide by 3.011 = ~3
		else // no note being played
			notes = '0;

endmodule

module attenuation(input  logic       clk,
				   input  logic [7:0] wave,
				   output logic [7:0] attenuated);

	// make it sound like an actual key that, when hit is loud then fades out over time
	// gets to max volume after 0.5 s
	// stays at max for 0.5 s
	// fades out over 3 s

	logic [31:0] up = '0;
	logic [3:0] i = 4'd8;
	logic [23:0] count = '0;

	always_ff@(posedge clk)
		begin
		up <= up + 1'b1; // is the sound increasing

		if (up <= 25'h1312D00) // take 0.5 s on the rise
			begin
			if (count == 22'h2625A0) // tells you when to increase the volume slightly
				begin
				i <= i - 1'b1; // how much you increase the volume by from 0
				count <= 0; // reset
				end
			else 
				begin
				count <= count + 1'b1;
				end
			attenuated <= wave >> i; // increase the volume slightly
			end			
		else if (up >= 25'h1312D00 & up <= 25'h2625A00) // one it reaches the top (0.5 s)
			attenuated <= wave;
		else
			begin
			if (count == 24'h969680) // tells you when to decrease the volume slightly
				begin
				i <= i + 1'b1; // how much you decrease the volume by
				count <= 0; //
				end
			else 
				begin
				count <= count + 1'b1;
				end
			attenuated <= wave >> i; // decrease the volume slightly
			end		
		end
endmodule

