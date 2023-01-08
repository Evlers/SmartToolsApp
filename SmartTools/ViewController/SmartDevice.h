//
//  SmartDevice.h
//  SmartTools
//
//  Created by Evler on 2022/12/27.
//

#ifndef SmartDevice_h
#define SmartDevice_h

#import <UIKit/UIKit.h>
#import "CoreBluetooth/CoreBluetooth.h"


@interface DataPoint : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *value;
@property (nonatomic) UITableViewCellAccessoryType accessoryType;

- (DataPoint *)initWithName:(NSString *)name value:(NSString *)value;

@end

@interface SmartDevice : UIViewController

@property (nonatomic, strong) Device *device;
@property (nonatomic, strong) SmartProtocol *smart_protocol;// 智能包协议

- (void)connected;
- (void)disconnect;

@end

#endif /* Device_h */
