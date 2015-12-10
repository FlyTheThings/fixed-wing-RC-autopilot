//
//  utils.c
//  avr - flyByWire
//
//  Created by Ludger Heide on 23.09.15.
//  Copyright © 2015 LH Technologies. All rights reserved.
//

#include "utils.h"
#include "uart4.h"
#include <assert.h>
#include <avr/eeprom.h>

#include "pinSetup.h"

static FILE mystdout = FDEV_SETUP_STREAM(raspiPutChar, NULL, _FDEV_SETUP_WRITE);

void printfAttachToUart(void) {
    //Initialize UART 3 and make it stderr and stdout
    uartInit(RASPI_UART);
    uartSetBaudRate(RASPI_UART, 115200);
    stderr = &mystdout;
    stdout = &mystdout;
}

//Standards-compliant putchar function that sends stuff to the raspberry pi
int raspiPutChar(char c, __attribute__ ((unused)) FILE* stream) {
    uartSendByte(RASPI_UART, c);
    return 0;
}

//Utility function that puts a string into a UART byte-wise
void uartPutStr(u08 nUart, char* string) {
    assert(nUart < 4);
    
    while(*string != '\0') {
        uartSendByte(nUart, *string);
        string++;
    }
}

//Reads in the sea level pressure from eeprom and checks its validity
void readSlpFromEEPROM(void) {
    float slpFromRom = eeprom_read_float(EEPROM_SLP_ADDRESS);
    
    if(slpFromRom <= 1100 && slpFromRom >= 850) {
        //Our value is within the allowed bounds
        seaLevelPressure = slpFromRom;
    } else {
        seaLevelPressure = 1013; //Stanard pressure otherwise
    }
}