//
//  ViewController.m
//  VESC_MacOS
//
//  Created by Bosko Petreski on 4/4/19.
//  Copyright © 2019 Bosko Petreski. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

#pragma mark - CentralManager
-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *message = @"Bluetooth";
    switch (central.state) {
        case CBManagerStateUnknown: message = @"Bluetooth Unknown."; break;
        case CBManagerStateResetting: message = @"The update is being started. Please wait until Bluetooth is ready."; break;
        case CBManagerStateUnsupported: message = @"This device does not support Bluetooth low energy."; break;
        case CBManagerStateUnauthorized: message = @"This app is not authorized to use Bluetooth low energy."; break;
        case CBManagerStatePoweredOff: message = @"You must turn on Bluetooth in Settings in order to use the reader."; break;
        default: break;
    }
    [self logMessage:message];
}
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (![peripherals containsObject:peripheral]) {
        [peripherals addObject:peripheral];
    }
}
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self logMessage:[NSString stringWithFormat:@"Connected to %@",peripheral.name]];
    
    connectedPeripheral = peripheral;
    txCharacteristic = nil;
    
    [connectedPeripheral setDelegate:self];
    [connectedPeripheral discoverServices:nil];
}
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error != nil) {
        [self logMessage:[NSString stringWithFormat:@"Error connect: %@",error.description]];
    }
}
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error != nil) {
        [self logMessage:[NSString stringWithFormat:@"Error disconnect: %@",error.description]];
    } else {
        [vescController resetPacket];
        [self logMessage:[NSString stringWithFormat:@"The reader is disconnected successfully"]];
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if (error) {
        [self logMessage:[NSString stringWithFormat:@"Error receiving didWriteValueForCharacteristic %@: %@", characteristic, error]];
        return;
    }
}
-(void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral{
    //NSLog(@"peripheralIsReadyToSendWriteWithoutResponse");
}
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [self logMessage:[NSString stringWithFormat:@"Error receiving notification for characteristic %@: %@", characteristic, error]];
        return;
    }
    if ([vescController process_incoming_bytes:characteristic.value] > 0) {
        [self logData: [vescController readPacket]];
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        [self logMessage:[NSString stringWithFormat:@"Discovered service: %@", service.UUID]];
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"FFE1"]] forService:service];
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if (error) {
        [self logMessage:[NSString stringWithFormat:@"Error receiving didUpdateNotificationStateForCharacteristic %@: %@", characteristic, error]];
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    [self logMessage:@"Discovered UART service characteristics"];
    
    // http://www.hangar42.nl/hm10
    // BAUD HM-10    115200   //Flashed here http://www.hangar42.nl/ccloader
    // The HM10 has one service, 0xFFE0, which has one characteristic, 0xFFE1 (these UUIDs can be changed with AT commands by the way)
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self logMessage:[NSString stringWithFormat:@"Char %@", characteristic]];
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
            [self logMessage:[NSString stringWithFormat:@"Found TX service: %@",characteristic]];
            
            txCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            writeType = characteristic.properties == CBCharacteristicPropertyWrite ? CBCharacteristicWriteWithResponse : CBCharacteristicWriteWithoutResponse;
            
            [self performSelector:@selector(doGetValues) withObject:nil afterDelay:0.3];
        }
    }
}

#pragma mark - IBActions
-(IBAction)onBtnSearchDevice:(NSButton *)sender{
    if (connectedPeripheral != nil) {
        [centralManager cancelPeripheralConnection:connectedPeripheral];
        connectedPeripheral = nil;
    }
    [peripherals removeAllObjects];
    [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FFE0"]] options:nil];
    
    [self performSelector:@selector(stopSearchReader) withObject:nil afterDelay:3];
    
    [progressLoader startAnimation:nil];
}

#pragma mark - CustomFunctions
-(void)scrollToBottom{
    NSScrollView *scrollView = [txtDebug enclosingScrollView];
    NSPoint newScrollOrigin;
    
    if ([[scrollView documentView] isFlipped])
        newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
    else
        newScrollOrigin = NSMakePoint(0.0F, 0.0F);
    
    [[scrollView documentView] scrollPoint:newScrollOrigin];
}
-(void)logMessage:(NSString *)msg{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n",msg];
    txtDebug.string = [txtDebug.string stringByAppendingString:paragraph];
    [self scrollToBottom];
}
-(void)logData:(mc_values)data {
    
    lblVoltageInput.stringValue = [NSString stringWithFormat:@"%.2f V",data.v_in];
    
    lblRPM.stringValue = [NSString stringWithFormat:@"%.1f RPM",data.rpm];
    
    lblTempMosfet.stringValue = [NSString stringWithFormat:@"%.2f degC",data.temp_mos];
    lblTempMotor.stringValue = [NSString stringWithFormat:@"%.2f degC",data.temp_motor];
    
    lblCurrentMotor.stringValue = [NSString stringWithFormat:@"%.2f A",data.current_motor];
    lblCurrentInput.stringValue = [NSString stringWithFormat:@"%.2f A",data.current_in];
    
    lblWattsHoursDrawn.stringValue = [NSString stringWithFormat:@"%.4f Wh",data.watt_hours];
    lblWattsChargerRegen.stringValue = [NSString stringWithFormat:@"%.4f Wh",data.watt_hours_charged];
    
    lblAmpHoursDrawn.stringValue = [NSString stringWithFormat:@"%.4f Ah",data.amp_hours];
    lblAmpHoursChargedRegen.stringValue = [NSString stringWithFormat:@"%.4f Ah",data.amp_hours_charged];
}

-(void)stopSearchReader{
    [centralManager stopScan];
    [progressLoader stopAnimation:nil];
    
    SearchDevice *controller = [self.storyboard instantiateControllerWithIdentifier:@"SearchDevice"];
    controller.delegate = self;
    controller.arrDevices = peripherals;
    [self presentViewControllerAsSheet:controller];
    
    for(CBPeripheral *periperal in peripherals){
        if([periperal.name containsString:@"Soft"]){
//            [centralManager connectPeripheral:periperal options:nil];
            [self logMessage:[NSString stringWithFormat:@"Periperal name: %@",periperal.name]];
            break;
        }
        
    }
}
-(void)doGetValues {
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSData *dataToSend = [self->vescController dataForGetValues];
        [self->connectedPeripheral writeValue:dataToSend forCharacteristic:self->txCharacteristic type:self->writeType];
    }];
}

#pragma mark - SearchDeviceDelegate
-(void)connectedWithDevice:(CBPeripheral *)periperal{
    [centralManager connectPeripheral:periperal options:nil];
}

#pragma mark - UIViewDelegates
-(void)viewDidLoad {
    [super viewDidLoad];
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    peripherals = NSMutableArray.new;
    
    vescController = VESC.new;
}
-(void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}


@end
