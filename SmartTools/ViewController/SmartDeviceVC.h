//
//  SmartDeviceVC.h
//  SmartTools
//
//  Created by Evler on 2022/12/27.
//

#ifndef SmartDeviceVC_h
#define SmartDeviceVC_h

#import <UIKit/UIKit.h>
#import "CoreBluetooth/CoreBluetooth.h"


@interface DataPoint : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *value;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;

- (DataPoint *)initWithName:(NSString *)name value:(NSString *)value;

@end

@interface SmartDeviceVC : UIViewController

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) Device *device;

@end

#endif /* SmartDeviceVC_h */
