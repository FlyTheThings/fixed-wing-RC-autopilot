/*! \file global.h \brief AVRlib project global include. */
//*****************************************************************************
//
// File Name	: 'global.h'
// Title		: AVRlib project global include 
// Author		: Pascal Stang - Copyright (C) 2001-2002
// Created		: 7/12/2001
// Revised		: 9/30/2002
// Version		: 1.1
// Target MCU	: Atmel AVR series
// Editor Tabs	: 4
//
//	Description : This include file is designed to contain items useful to all
//					code files and projects.
//
// This code is distributed under the GNU Public License
//		which can be found at http://www.gnu.org/licenses/gpl.txt
//
//*****************************************************************************

#ifndef GLOBAL_H
#define GLOBAL_H

//Booleans
#include <stdbool.h>

// global AVRLIB defines
#include "avrlibdefs.h"
// global AVRLIB types definitions
#include "avrlibtypes.h"

#include "bmp.h"
#include "gyro.h"
#include "accelMag.h"
#include "battery.h"

// project/system dependent defines

// CPU clock speed
//#define F_CPU        16000000               		// 16MHz processor
//#define F_CPU        14745000               		// 14.745MHz processor
//#define F_CPU        8000000               		// 8MHz processor
//#define F_CPU        7372800               		// 7.37MHz processor
//#define F_CPU        4000000               		// 4MHz processor
//#define F_CPU        3686400               		// 3.69MHz processor
#define CYCLES_PER_US ((F_CPU+500000)/1000000) 	// cpu cycles per microsecond

//EEPROM layout
#define EEPROM_SLP_ADDRESS 0x00 //Size 4 bytes, next address 0x04

typedef struct {
    u32 timestamp;
    
    u08 yaw;
    u08 pitch;
    u08 thrust;
} commandSet_struct;
commandSet_struct inputCommandSet;
commandSet_struct outputCommandSet;

typedef struct {
    bool altitudeInUse;
    s32 altitude; //Centimeters
    s08 pitchAngle; //Degrees
    
    bool headingInUse;
    u16 heading; //Degrees
    s08 rateOfTurn; //Relative value
} autonomousUpdate;

typedef enum {
    m_degraded = 0,
    m_passThrough = 1,
    m_flybywire = 2,
    m_autonomous = 3
} flightMode;
flightMode currentFlightMode;

typedef struct {
    u32 timestamp;
    
    float courseMagnetic;
    float pitch;
    float roll;
} attitude_struct;
attitude_struct currentAttitude;

typedef struct {
    u32 timestamp;
    
    float latitude;
    float longitude;
    float altitude; //Meters ASL
} waypoint;
waypoint homeBase;

pressureEvent curPressure;
magEvent curMag;
accelEvent curAccel;
gyroEvent curGyro;
batteryEvent curBattery;

float seaLevelPressure; //Initialize to standard pressure for now

#endif
