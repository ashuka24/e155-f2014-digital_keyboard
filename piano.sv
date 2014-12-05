/*  piano.sv
    
    Sebastian Krupa and Ashuka Xue
    Fall 2014
    skrupa@hmc.edu and axue@hmc.edu
*/

module piano(input  logic       sck, sdi, clk,
             output logic [7:0] led,
             output logic dclk, data, load, ldac);

    logic [31:0] q;
    logic [7:0] note1, note2, note3;
    logic [7:0] wave;
    logic [7:0] atten1, atten2, atten3;
    logic [1:0] notescount;
    logic done1, done2, done3;

    spi_slave_receive_only spi(sck, sdi, q);
    process_spi proc(sck, q, note1, note2, note3, notescount);
    //assign atten1 = note1;
    //assign atten2 = note2;
    //assign atten3 = note3;
    attenuation first(clk, note1, atten1, done1);
    attenuation second(clk, note2, atten2, done2);
    attenuation third(clk, note3, atten3, done3);
     add_notes add(atten1, atten2, atten3, done1, done2, done3, notescount, wave);
    //assign wave = note1;
     assign led = atten1;
    dacProcess dac(clk, wave, data, dclk, load, ldac);
     
    

endmodule

// Changing from parallel to serial for the input to the serial DAC
module dacProcess(input  logic clk,
                  input  logic [7:0] wave,
                  output logic data, dclk, load, ldac);
    logic [15:0] cnt = '0;
    logic [6:0] cnt2;
    logic [7:0] wavekeep;
    
    always_ff @(posedge clk)
        begin
        /*if(cnt == 16'b0)
            begin
            wavekeep<=wave;
            end*/
        if(cnt < 16'd160)
            begin
                wavekeep<=wave;
            data <= 1'b0;
            load <= 1'b1;
            ldac <= 1'b1;
                if(cnt2 == 7'd0)
                    dclk <= 1'b1;
                if(cnt2 == 7'd20)
                    begin
                    dclk <= 1'b0;
                    end
            end
        else if(cnt < 16'd480)
            begin  
            load <= 1'b1;
            ldac <= 1'b1;
            if(cnt2 == 7'd0)
                    begin
                    dclk <= 1'b1;
                    end
                if (cnt2 == 7'd7)
                    begin
                    data <= wavekeep[7];
                    wavekeep <= {wavekeep[6:0], 1'b0};
                    end
                if(cnt2 == 7'd20)
                    begin
                    dclk <= 1'b0;
                    end
            end
        else if(cnt < 16'd520)
            begin
            data <= 1'b0;
            load <= 1'b0;
            ldac <= 1'b1;
            dclk <= 1'b0;;
                end
        else if(cnt < 16'd560)
            begin
            data <= 1'b0;
            load <= 1'b1;
            ldac <= 1'b0;
            dclk <= 1'b0;
            end
        else if(cnt == 16'd560)
            begin
            data <= 1'b0;
            load <= 1'b1;
            ldac <= 1'b1;
            dclk <= 1'd0;
            end
        if(cnt < 16'd561)
            cnt <= cnt + 1'b1;
          else
                cnt <= 16'b0;
          if(cnt2 < 7'd40)
                cnt2 <= cnt2 + 1'b1;
          else
                cnt2 <= 7'd0;
         end
endmodule

// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 
module spi_slave_receive_only(input  logic        sck, //from master
                              input  logic        sdi, //from master 
                              output logic [31:0] q); // data received
    always_ff @(posedge sck)
        q <={q[30:0], sdi}; //shift register
endmodule

// Take the output from the SPI receiver and separate it into its separate components
module process_spi( input logic         sck,
                    input logic  [31:0] q,
                    output logic [7:0]  note1, note2, note3,
                    output logic [1:0]  notescount);
    logic [6:0] cnt = 6'b00_0000; 
     logic moved = 1'b0; // makes sure iterator doesn't start until initial signal
     
     always_ff @(negedge sck)
        if(moved)
        begin
            if(cnt == 6'd31) // read the note after the entire 32 bit number has come in 
            begin
                note1 <= q[7:0];
                note2 <= q[15:8];
                note3 <= q[23:16];
                notescount <= q[25:24];
                cnt <= '0;
            end
            else
                cnt <= cnt + 1'b1;
        end
        else if(~moved && q == 32'hFFFF)
            moved = 1'b1;
            
endmodule

// adds the three notes together (if there are three) and makes sure the amplitude doesn't change
module add_notes(input logic [7:0] note1, note2, note3,
                 input logic done1, done2, done3;
                 input logic [1:0] notescount,
                 output logic [7:0] notes);
    
    logic [9:0] intermed, sft2, sft4, sft6, sft8;
    logic [1:0] notescountmod;
    assign notescountmod = notescount - done1 - done2 - done3; // if the notes being played is dependent on if a previous note has stopped playing
    assign intermed = (note1 + note2 + note3);
    assign sft2 = intermed>>2;
    assign sft4 = intermed>>4;
    assign sft6 = intermed>>6;
    assign sft8 = intermed>>8;

    always_comb 
        if (notescountmod == 2'b01) // if only one note being played
            notes = intermed;
        else if (notescountmod == 2'b10) // if 2 notes being played
            notes = intermed>>1;
        else if (notescountmod == 2'b11)
            notes = sft2+sft4+sft6+sft8; //if 3 notes being played, divide by 3.011 = ~3
        else // no note being played
            notes = '0;

endmodule

// Creates an envelope that attenuates the sound of the key hit
// make it sound like an actual key that, when hit is loud then fades out over time
module attenuation(input  logic       clk,
                   input  logic [7:0] wave,
                   output logic [7:0] attenuated, 
                   output logic doneattenuating);

    // gets to max volume after 0.5 s
    // stays at max for 0.5 s
    // fades out over 3 s

    logic [31:0] cnt = 32'b0;
    logic [7:0] whole01, frac002, frac004, frac008, frac016, frac032, frac064, frac128;
        // generates what percentage of the amplitude is played (the whole amplitude, half, or a quarter, etc)
    
    always_ff @(posedge clk)
         begin
         if(wave == 8'b0) // if no wave, counter hasn't started
                cnt <= 32'b0;
                doneattenuating <= 1'b0;
            else if (cnt < 32'd120000000) // hasn't reached 3 sec? increment
                cnt <= cnt + 1'b1;
                doneattenuating <= 1'b0;
            else
                cnt <= 32'd120000000; // reached 3 sec, so stop counting and set counter
                doneattenuating <= 1'b1;
            

            if(cnt < 32'd750000) // note initial rise
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd1500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd2250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd3000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd3750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd4500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd5250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd6000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd6750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd7500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd8250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd9000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd9750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd10500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd11250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd12000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd12750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd13500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd14250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd15000000) // hit the top peak
             begin 
                whole01 <= wave;     
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd15416667)  // start of slight decrease
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd15833333) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd16250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd16666667) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd17083333) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd17500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd17916667) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd18333333) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd18750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd19166667) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd19583333) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd40000000)  //sustain
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd41250000) // continuation of note decay
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd42500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd43750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd45000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd46250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd47500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd48750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd50000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd51250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd52500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd53750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd55000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd56250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd57500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd58750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd60000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd61250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd62500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd63750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd65000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd66250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd67500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd68750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd70000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd71250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd72500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd73750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd75000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd76250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd77500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd78750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd80000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd81250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd82500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd83750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd85000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd86250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd87500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd88750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd90000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <= wave[7:1];
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd91250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd92500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd93750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd95000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd96250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd97500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd98750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd100000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd101250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd102500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd103750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd105000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd106250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd107500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd108750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd110000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd111250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd112500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <= wave[7:2];
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd113750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd115000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
             else if(cnt < 32'd116250000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <= wave[7:4];
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd117500000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <= wave[7:5];
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd118750000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <= wave[7:3];
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <= wave[7:6];
                frac128 <=  8'b0;
             end
             else if(cnt < 32'd120000000) 
             begin 
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <= wave[7:4];
                frac032 <= wave[7:5];
                frac064 <=  8'b0;
                frac128 <= wave[7];  
             end
            else // note completely died out at 3 seconds, there is no sound
            begin
                whole01 <=  8'b0;
                frac002 <=  8'b0;
                frac004 <=  8'b0;
                frac008 <=  8'b0;
                frac016 <=  8'b0;
                frac032 <=  8'b0;
                frac064 <=  8'b0;
                frac128 <=  8'b0;  
            end
         attenuated <= whole01 + frac002 + frac004 + frac008 + frac016 + frac032 + frac064 + frac128; // add the parts together
         
         end
endmodule
