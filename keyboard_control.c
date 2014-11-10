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
void period_determiner(int);
void octave_reader(int);


/*****************************************************************************
 Macros and Global Variables
*****************************************************************************/
int waveform;
int period = 0;
int octave = 4; // default on middle C
int note1;
int note2;
int note3;
int period1;
int period2;
int period3;

/*****************************************************************************
 Main
*****************************************************************************/
void main(void) { 
	int received;
	
	initspi(); 				// initialize the SPI port

	while(1){

		//TODO: FINISH WHILE LOOP

		period_waveform = (period << 2) | waveform;
		// send the data over piece by piece
		spi_send_receive(period1);
		spi_send_receive(period2);
		spi_send_receive(period3);
		spi_send_receive(period_waveform);
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


void period_determiner(int note){
	// determine the period of the note played

	// TODO: CREATE CASE STATEMENT FOR THE DIFFERENT NOTES
	
}

void octave_reader(int octave) {
	// read the octave and adjusts the frequencies so that they are in the correct octave
	// frequency gets larger as octave increases. 
	// A0 = 27.5Hz, A4 = 440Hz, A8 = 7040Hz

	if (new_octave > 4){ // shift period up to the higher octave
		period = period*(2*(new_octave - 4)); 
	}
	else if (new_octave < 4){ // shift period down to the lower octave
		period = period/(2*(octave - 4)); 
	}
}
