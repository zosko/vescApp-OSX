//
//  ViewController.h
//  VESC_MacOS
//
//  Created by Bosko Petreski on 4/4/19.
//  Copyright © 2019 Bosko Petreski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VESC.h"
#import "SearchDevice.h"

@import CoreBluetooth;

@interface ViewController : NSViewController <CBCentralManagerDelegate, CBPeripheralDelegate,SearchDeviceDelegate>{
    VESC *vescController;
    
    CBCentralManager *centralManager;
    CBPeripheral *connectedPeripheral;
    NSMutableArray *peripherals;
    CBCharacteristic *txCharacteristic;
    CBCharacteristicWriteType writeType;
    
    IBOutlet NSTextView *txtDebug;
    
    IBOutlet NSTextField *lblVoltageInput;
    IBOutlet NSTextField *lblTempMosfet;
    IBOutlet NSTextField *lblTempMotor;
    IBOutlet NSTextField *lblRPM;
    IBOutlet NSTextField *lblCurrentMotor;
    IBOutlet NSTextField *lblCurrentInput;
    IBOutlet NSTextField *lblWattsHoursDrawn;
    IBOutlet NSTextField *lblWattsChargerRegen;
    IBOutlet NSTextField *lblAmpHoursDrawn;
    IBOutlet NSTextField *lblAmpHoursChargedRegen;
    
    IBOutlet NSProgressIndicator *progressLoader;
}


@end

