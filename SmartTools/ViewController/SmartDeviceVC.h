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

@interface FileInfo : NSObject

@property (nonatomic, strong) NSString  *name;
@property (nonatomic, strong) NSDate    *date;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, strong) NSString  *owner;
@property (nonatomic, strong) NSString  *path;

@end

@interface SmartDeviceVC : UIViewController

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) Device *device;

@end

#endif /* SmartDeviceVC_h */
