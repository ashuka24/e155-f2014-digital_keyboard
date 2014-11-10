/*	keyboard_control.c
	
	Sebastian Krupa and Ashuka Xue
	Fall 2014
  	skrupa@hmc.edu and axue@hmc.edu
*/

#include <p32xxxx.h> 
#include <stdio.h>
/*****************************************************************************
 Internal Function Prototypes
*****************************************************************************/
void initspi(void);
int spi_send_receive(int);
void frequency_determiner(int);
void octave_reader(int);


/*****************************************************************************
 Macros and Global Variables
*****************************************************************************/
int waveform;
int frequency = 0;
int octave = 4; // default on middle C

/*****************************************************************************
 Main
*****************************************************************************/
void main(void) { 
	int received;
	
	initspi(); 				// initialize the SPI port

	while(1){

		//TODO: FINISH WHILE LOOP
		
		data = note1 | note2 | note3 | (frequency << 2) | waveform; // send all the info over
		spi_send_receive(data);
	}
	 
}


/******************************************************************************
 SPI Interfacing
******************************************************************************/
void initspi(void) {
	char junk;

	SPI2CONbits.ON = 0; // disable SPI to reset any previous state
	junk = SPI2BUF; // read SPI buffer to clear the receive buffer
	SPI2BRG = 7; //set BAUD rate to 1.25MHz, with Pclk at 20MHz 
	SPI2CONbits.MSTEN = 1; // enable master mode
	SPI2CONbits.CKE = 1; // set clock-to-data timing (data centered on rising SCK edge) 
	SPI2CONbits.ON = 1; // turn SPI on
	SPI2CONbits.MODE32 = 1; // put SPI in 32 bit mode
}

int spi_send_receive(int send) {
	SPI2BUF = send; // send data to slave
	while (!SPI2STATbits.SPIBUSY); // wait until received buffer fills, indicating data received 
	return SPI2BUF; // return received data and clear the read buffer full
}

void frequency_determiner(int note){
	// determine the frequency of the note played

	// TODO: CREATE CASE STATEMENT FOR THE DIFFERENT NOTES
}

void octave_reader(int new_octave) {
	// read the octave and adjusts the frequencies so that they are in the correct octave
	if (new_octave > octave){ // shift frequency up to the higher octave
		frequency = frequency*(2*(octave-octave)); 
	}
	else if (new_octave < octave){ // shift frequency down to the lower octave
		frequency = frequency/(2*(octave - octave)); 
	}
	octave = new_octave;
}
