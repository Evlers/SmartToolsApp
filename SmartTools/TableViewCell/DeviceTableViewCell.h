//
//  DeviceTableViewCell.h
//  SmartTools
//
//  Created by Evler on 2023/2/20.
//

#ifndef DeviceTableViewCell_h
#define DeviceTableViewCell_h

#import <UIKit/UIKit.h>

@interface DeviceTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *deviceName;
@property (nonatomic, strong) UILabel *statusDescribe;
@property (nonatomic, strong) UILabel *tempValue;
@property (nonatomic, strong) UILabel *percentValue;
@property (nonatomic, strong) UIImageView *statusIcon;
@property (nonatomic, strong) UIImageView *deviceImage;
@property (nonatomic, strong) UIImageView *bleImage;
@property (nonatomic, strong) UIImageView *tempIcon;
@property (nonatomic, strong) UIButton *connectBtn;
@property (nonatomic, strong) UIImageView *percentIcon;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)setDeviceName:(NSString *)name state:(SmartDeviceState)state info:(SmartBattery *)battery;

@end

#endif /* DeviceTableViewCell_h */
