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

void initTimers(void);
unsigned char initSquare(void);
unsigned char initSawtooth(void);
unsigned char initTriangle(void);
unsigned char initSine(void);

void period_determiner(int);
void octave_reader(int);

/*****************************************************************************
 Macros and Global Variables
*****************************************************************************/
int wave;
int period = 0;
int octave = 4; // default on middle C
int note1;
int note2;
int note3;
int period1;
int period2;
int period3;
unsigned char square[512];
unsigned char sawtooth[512];
unsigned char triangle[512];
unsigned char sine[512];

/*****************************************************************************
 Main
*****************************************************************************/
void main(void) { 

	TRISB = 0xFFFF// input from keys

	int received;
	
	initspi(); 				// initialize the SPI port
	initTimers();
	initSquare();			// initialize the waves
	initSawtooth();
	initTriangle();
	initSine();

	while(1){

		//TODO: FINISH WHILE LOOP

		spi_send_receive(wave);
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

/******************************************************************************
 Wave Generation
******************************************************************************/
void initTimers(void){
	// Assumes peripheral clock at 10MHz
	//        Use Timer1 for note duration
	// T1CON
	// bit 15:	ON=1: enable timer
	// bit 14:	FRZ=0: keep running in exception mode
	// bit 13:	SIDL = 0: keep running in idle mode
	// bit 12:	TWDIS=1: ignore writes until current write completes
	// bit 11: 	TWIP=0: don't care in synchronous mode
	// bit 10-8: unused
	// bit 7: 	TGATE=0: disable gated accumulation
	// bit 6:   unused
	// bit 5-4: TCKPS=11: 1:256 prescaler, 0.1us*256=25.6us
	// bit 3:	unused
	// bit 2:	don't care in internal clock mode
	// bit 1:	TCS=0: use internal peripheral clock
	// bit 0:	unused
	T1CON = 0b1001000000110000;
}

unsigned char initSquare(void){
	for(int i = 0; i < 256; i++){
		square[i]=255;
		square[512-i] = 0;
	}
}

unsigned char initSawtooth(void){
	for(int i = 0;i < 512; i++){
		sawtooth[i] = i/2;
	}
}

unsigned char initTriangle(void){
	for(int i = 0; i < 256; i++){
		square[i]=i;
		square[512-i] = i;
	}

}

unsigned char initSine(void){

}

/******************************************************************************
 Period and Octave
******************************************************************************/

void period_determiner(int note){
	// determine the period of the note played

	// TODO: CREATE CASE STATEMENT FOR THE DIFFERENT NOTES
	switch (note)
		case 0x0000 
		case 0x0009; period = 1/440 //440Hz
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
	octave = new_octave;
}
