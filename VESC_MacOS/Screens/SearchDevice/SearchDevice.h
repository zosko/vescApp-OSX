//
//  SearchDevice.h
//  VESC_MacOS
//
//  Created by Bosko Petreski on 4/5/19.
//  Copyright © 2019 Bosko Petreski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@import CoreBluetooth;

@protocol SearchDeviceDelegate <NSObject>
-(void)connectedWithDevice:(CBPeripheral *)periperal;
@end

@interface SearchDevice : NSViewController <NSTableViewDataSource,NSTableViewDelegate>{
    IBOutlet NSTableView *tblDevices;
    
    IBOutlet NSButton *btnCancel;
    IBOutlet NSButton *btnConnect;
}
@property (nonatomic,strong) id <SearchDeviceDelegate> delegate;
@property (nonatomic,strong) NSArray *arrDevices;

@end

NS_ASSUME_NONNULL_END
