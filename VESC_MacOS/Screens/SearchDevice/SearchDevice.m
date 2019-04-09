//
//  SearchDevice.m
//  VESC_MacOS
//
//  Created by Bosko Petreski on 4/5/19.
//  Copyright © 2019 Bosko Petreski. All rights reserved.
//

#import "SearchDevice.h"

@interface SearchDevice ()

@end

@implementation SearchDevice

#pragma mark - IBActions
-(IBAction)onBtnConnect:(NSButton *)sender{
    if([tblDevices selectedRow] > -1){
        CBPeripheral *periperal = self.arrDevices[[tblDevices selectedRow]];
        [self.delegate connectedWithDevice:periperal];
        [self onBtnClose:nil];
    }
}
-(IBAction)onBtnClose:(NSButton *)sender{
    [self dismissViewController:self];
}

#pragma mark - UITableViewDelegates
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.arrDevices.count;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CBPeripheral *periperal = self.arrDevices[row];
    return [NSString stringWithFormat:@"[%@] %@",periperal.name,periperal.identifier];
}

#pragma mark - UIViewDelegates
-(void)viewDidLoad {
    [super viewDidLoad];
}

@end
