//
//  DeviceTableViewCell.m
//  SmartTools
//
//  Created by Evler on 2023/2/20.
//

#import "SmartDevice.h"
#import "DeviceTableViewCell.h"
#import "Masonry.h"

#define DEVICE_IMG_SIZE         100.0

@implementation DeviceTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.deviceImage = [[UIImageView alloc]init];
        self.deviceImage.contentMode = UIViewContentModeScaleAspectFit;
        self.deviceImage.image = [UIImage imageNamed:@"电池包1"];
        [self.contentView addSubview:self.deviceImage];
        
        self.deviceName = [[UILabel alloc]init];
        self.deviceName.font = [UIFont boldSystemFontOfSize:17];
        [self.contentView addSubview:self.deviceName];
        
        self.bleImage = [[UIImageView alloc]init];
        self.bleImage.image = [UIImage imageNamed:@"蓝牙已断开"];
        [self.contentView addSubview:self.bleImage];
        
        self.statusIcon = [[UIImageView alloc]init];
        self.statusIcon.image = [UIImage imageNamed:@"待机中"];
        [self.contentView addSubview:self.statusIcon];
        
        self.statusDescribe = [[UILabel alloc]init];
        self.statusDescribe.font = [UIFont systemFontOfSize:16];
        self.statusDescribe.text = @"Standby";
        [self.contentView addSubview:self.statusDescribe];
        
        self.tempIcon = [[UIImageView alloc]init];
        self.tempIcon.image = [UIImage imageNamed:@"温度"];
        [self.contentView addSubview:self.tempIcon];
        
        self.tempValue = [[UILabel alloc]init];
        self.tempValue.font = [UIFont systemFontOfSize:16];
        self.tempValue.text = @"25°C";
        [self.contentView addSubview:self.tempValue];
        
        self.percentIcon = [[UIImageView alloc]init];
        self.percentIcon.image = [UIImage imageNamed:@"电量"];
        [self.contentView addSubview:self.percentIcon];
        
        self.percentValue = [[UILabel alloc]init];
        self.percentValue.font = [UIFont systemFontOfSize:16];
        self.percentValue.text = @"80%";
        [self.contentView addSubview:self.percentValue];
        
        self.connectBtn = [[UIButton alloc]init];
        [self.connectBtn setTitle:@"Connect device" forState:UIControlStateNormal];
        [self.connectBtn setTitleColor:[UIColor colorWithHexString:@"FF9040"] forState:UIControlStateNormal];
        [self.contentView addSubview:self.connectBtn];
        self.connectBtn.hidden = true;
        
        // 约束所有子控件
        CGFloat devImageSize = DEVICE_IMG_SIZE; // 设置设备图片高度以及宽度
        CGFloat crosswiseCornerInterval = self.contentView.frame.size.width * 0.03; // 横向边角间隔
        CGFloat lengthwaysCornerInterval = devImageSize * 0.05; // 纵向边角间隔(Cell高度跟着图片高度决定)
        CGFloat imageAndInfoInterval = self.contentView.frame.size.width * 0.05; // 设备图片与信息的间隔
        
        // 设置设备图片约束
        [self.deviceImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top);
            make.left.equalTo(self.contentView.mas_left).offset(crosswiseCornerInterval);
            make.bottom.equalTo(self.contentView.mas_bottom);
            make.size.mas_equalTo(CGSizeMake(devImageSize, devImageSize));
        }];

        // 设置设备名约束
        [self.deviceName mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.deviceImage.mas_top).offset(lengthwaysCornerInterval);
            make.left.equalTo(self.deviceImage.mas_right).offset(imageAndInfoInterval);
        }];
        
        // 设置蓝牙图标约束
        [self.bleImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.deviceName.mas_top);
            make.right.equalTo(self.contentView.mas_right).offset(-crosswiseCornerInterval);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        
        // 设置设备状态图标约束
        [self.statusIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_centerY).offset(-10);
            make.left.equalTo(self.deviceName.mas_left);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        
        // 设置设备状态描述约束
        [self.statusDescribe mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.statusIcon.mas_top);
            make.left.equalTo(self.statusIcon.mas_right);
        }];
        
        // 设置温度图标约束
        [self.tempIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.deviceImage.mas_bottom).offset(-lengthwaysCornerInterval);
            make.left.equalTo(self.statusIcon.mas_left);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        
        // 设置温度值约束
        [self.tempValue mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.tempIcon.mas_bottom);
            make.left.equalTo(self.tempIcon.mas_right);
        }];
        
        // 设置电量图标约束
        [self.percentIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.tempValue.mas_bottom);
            make.left.equalTo(self.tempIcon.mas_right).offset(self.contentView.frame.size.width / 3.0);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        }];
        
        // 设置电量值约束
        [self.percentValue mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.percentIcon.mas_bottom);
            make.left.equalTo(self.percentIcon.mas_right).offset(5);
        }];
        
        // 设置按钮约束
        [self.connectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-lengthwaysCornerInterval);
            make.right.equalTo(self.contentView.mas_right).offset(-crosswiseCornerInterval);
            make.size.mas_equalTo(CGSizeMake(self.contentView.frame.size.width / 2.0, devImageSize / 2.9));
        }];
    }
    return self;
}

- (void)setSmartDeviceInfo:(SmartDevice *)smartDevice {
    
    self.deviceName.text = smartDevice.baseInfo.name;
//    cell.deviceImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"BatPack%d.0", capacity]];
    
    if (smartDevice.baseInfo.state == SmartDeviceConnectSuccess)
    {
//        uint32_t term = SmartBatReadyOfTemp|SmartBatReadyOfState|SmartBatReadyOfPercent;
//        if ((battery.paramIsReady & term) != term) { // 如果其中一个数据未准备好
//            [self.connectBtn setTitle:@"Get data.." forState:UIControlStateNormal];
//            return ;
//        }
        
        [self.connectBtn setTitle:@"" forState:UIControlStateNormal];
        self.connectBtn.hidden = true;
        self.tempIcon.hidden = self.percentIcon.hidden = self.statusIcon.hidden = false;
        self.bleImage.image = [UIImage imageNamed:@"蓝牙已连接"];
        self.tempValue.text = [NSString stringWithFormat:@"%d°C", smartDevice.battery.temperature];
        self.percentValue.text = [NSString stringWithFormat:@"%d%%", smartDevice.battery.percent];
        
        switch (smartDevice.battery.state)
        {
            case SmartBatteryStateStandby:
                self.statusDescribe.text = @"Standby";
                self.statusDescribe.textColor = [UIColor colorWithHexString:@"FF9040"];
                self.statusIcon.image = [UIImage imageNamed:@"待机中"];
                break;
                
            case SmartBatteryStateCharging:
                if (smartDevice.battery.functioon_switch & SmartBatFunSwSuspendCharging) {
                    self.statusDescribe.text = @"SuspendCharging";
                    self.statusDescribe.textColor = [UIColor colorWithHexString:@"FF9040"];
                    self.statusIcon.image = [UIImage imageNamed:@"暂停充电"];
                } else {
                    self.statusDescribe.text = @"Charging";
                    self.statusDescribe.textColor = [UIColor colorWithHexString:@"6BD7B0"];
                    self.statusIcon.image = [UIImage imageNamed:@"充电中"];
                }
                break;
                
            case SmartBatteryStateDischarging:
                self.statusDescribe.text = @"Discharging";
                self.statusDescribe.textColor = [UIColor colorWithHexString:@"3E95D5"];
                self.statusIcon.image = [UIImage imageNamed:@"放电中"];
                break;
                
            case SmartBatteryStateChargeComplete:
                self.statusDescribe.text = @"Charge complete";
                self.statusDescribe.textColor = [UIColor colorWithHexString:@"6BD7B0"];
                self.statusIcon.image = [UIImage imageNamed:@"充电完成"];
                break;
        }
    }
    else
    {
        self.connectBtn.hidden = false;
        self.tempValue.text = self.percentValue.text = self.statusDescribe.text = @"";
        self.tempIcon.hidden = self.percentIcon.hidden = self.statusIcon.hidden = true;
        self.bleImage.image = [UIImage imageNamed:@"蓝牙已断开"];
        if (smartDevice.baseInfo.state == SmartDeviceBLEConnecting)
            [self.connectBtn setTitle:@"Connecting.." forState:UIControlStateNormal];
        else if (smartDevice.baseInfo.state == SmartDeviceBLEConnected)
            [self.connectBtn setTitle:@"Find services.." forState:UIControlStateNormal];
        else if (smartDevice.baseInfo.state == SmartDeviceBLEDiscoverServer)
            [self.connectBtn setTitle:@"Find char.." forState:UIControlStateNormal];
        else if (smartDevice.baseInfo.state == SmartDeviceBLEDiscoverCharacteristic)
            [self.connectBtn setTitle:@"Enable notify.." forState:UIControlStateNormal];
        else if (smartDevice.baseInfo.state == SmartDeviceBLENotifyEnable)
            [self.connectBtn setTitle:@"Handshake.." forState:UIControlStateNormal];
        else {
            if (smartDevice.baseInfo.peripheral == nil) // 未搜索到设备广播
                [self.connectBtn setTitle:@"Offline" forState:UIControlStateNormal];
            else
                [self.connectBtn setTitle:@"Connect device" forState:UIControlStateNormal];
        }
        self.connectBtn.layer.cornerRadius = 10.0; // 设置圆角的弧度
        self.connectBtn.layer.borderWidth = 1.0f; // 边宽
        self.connectBtn.layer.borderColor = [UIColor colorWithHexString:@"FF9040"].CGColor;
        self.connectBtn.backgroundColor = [UIColor colorWithHexString:@"FF9040" alpha:0.1];
    }
}

// 设置Cell的左右间隔
- (void)setFrame:(CGRect)frame {
    
    NSInteger cornerInterval = self.frame.size.width * 0.05;
    frame.size.width -= cornerInterval * 2;
    frame.origin.x += cornerInterval;
    frame.size.height = DEVICE_IMG_SIZE;
//    self.layer.masksToBounds = YES;
//    self.layer.cornerRadius = 10;
    [super setFrame:frame];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    // 不执行高亮动作
//    [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
}

@end


@implementation DevParamUITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

// 设置Cell的左右间隔
- (void)setFrame:(CGRect)frame {
    
    NSInteger cornerInterval = self.frame.size.width * 0.05;
    frame.size.width -= cornerInterval * 2;
    frame.origin.x += cornerInterval;
    frame.size.height = 54;
    [super setFrame:frame];
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    // 不执行高亮动作
//    [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];
}

@end
