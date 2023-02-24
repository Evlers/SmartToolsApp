//
//  DeviceTableViewCell.m
//  SmartTools
//
//  Created by Evler on 2023/2/20.
//

#import "SmartDevice.h"
#import "DeviceTableViewCell.h"

//@interface DeviceTableViewCell()
//
//@end

@implementation DeviceTableViewCell

+ (instancetype)xibTableViewCell {
    //在类方法中加载xib文件,注意:loadNibNamed:owner:options:这个方法返回的是NSArray,所以在后面加上firstObject或者lastObject或者[0]都可以；因为我们的XIB文件中，只有一个Cell
    return [[[NSBundle mainBundle] loadNibNamed:@"DeviceTableViewCell" owner:nil options:nil] lastObject];
 }

- (void)setDeviceName:(NSString *)name state:(SmartDeviceState)state info:(SmartBattery *)battery {
    
    self.deviceName.text = name;
//    cell.deviceImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"BatPack%d.0", capacity]];
    
    if (state == SmartDeviceConnectSuccess)
    {
        if (battery.temperature == nil && battery.state == nil && battery.percent == nil) { // 如果其中一个数据未准备好
            [self.connectBtn setTitle:@"Request data.." forState:UIControlStateNormal];
            return ;
        }
        
        self.connectBtn.hidden = true;
        self.tempIcon.hidden = self.percentIcon.hidden = self.statusIcon.hidden = false;
        self.bleImage.image = [UIImage imageNamed:@"蓝牙已连接"];
        if (battery.temperature)
            self.tempValue.text = battery.temperature;
        if (battery.percent)
            self.percentValue.text = battery.percent;
        if (battery.state) {
            self.statusDescribe.text = battery.state;
            if ([battery.state isEqualToString:@"Standby"]) {
                self.statusIcon.image = [UIImage imageNamed:@"待机中"];
                self.statusDescribe.textColor = [UIColor colorWithHexString:@"FF9040"];
            } else if ([battery.state isEqualToString:@"Charging"]) {
                self.statusIcon.image = [UIImage imageNamed:@"充电中"];
                self.statusDescribe.textColor = [UIColor colorWithHexString:@"6BD7B0"];
            } else if ([battery.state isEqualToString:@"Discharging"]) {
                self.statusIcon.image = [UIImage imageNamed:@"放电中"];
                self.statusDescribe.textColor = [UIColor colorWithHexString:@"3E95D5"];
            } else if ([battery.state isEqualToString:@"Charge complete"]) {
                self.statusIcon.image = [UIImage imageNamed:@"充电完成"];
                self.statusDescribe.textColor = [UIColor colorWithHexString:@"6BD7B0"];
            }
        }
    }
    else
    {
        self.connectBtn.hidden = false;
        self.tempValue.text = self.percentValue.text = self.statusDescribe.text = @"";
        self.tempIcon.hidden = self.percentIcon.hidden = self.statusIcon.hidden = true;
        self.bleImage.image = [UIImage imageNamed:@"蓝牙已断开"];
        if (state == SmartDeviceBLEConnected)
            [self.connectBtn setTitle:@"Discover srervices.." forState:UIControlStateNormal];
        else if (state == SmartDeviceBLEDiscoverServer)
            [self.connectBtn setTitle:@"Discover characteristics.." forState:UIControlStateNormal];
        else if (state == SmartDeviceBLEDiscoverCharacteristic)
            [self.connectBtn setTitle:@"Enable nootify.." forState:UIControlStateNormal];
        else if (state == SmartDeviceBLENotifyEnable)
            [self.connectBtn setTitle:@"Shaking.." forState:UIControlStateNormal];
        else
            [self.connectBtn setTitle:@"Connect device" forState:UIControlStateNormal];
        self.connectBtn.layer.cornerRadius = 10.0; // 设置圆角的弧度
        self.connectBtn.layer.borderWidth = 1.0f; // 边宽
        self.connectBtn.layer.borderColor = [UIColor colorWithHexString:@"FF9040"].CGColor;
        self.connectBtn.backgroundColor = [UIColor colorWithHexString:@"FF9040" alpha:0.1];
    }
}

// 重新布局视图控件
-(void)layoutSubviews {

    CGFloat x, y, width;
    CGFloat crosswiseCornerInterval = self.contentView.frame.size.width * 0.01; // 横向边角间隔
    CGFloat lengthwaysCornerInterval = self.contentView.frame.size.height * 0.05; // 纵向边角间隔
    CGFloat imageAndInfoInterval = self.contentView.frame.size.width * 0.05; // 设备图片与信息的间隔
    CGFloat infoX = self.deviceImage.frame.origin.x + self.deviceImage.frame.size.width + imageAndInfoInterval;; // 信息的x坐标
    
    // 设置设备名布局位置
    width = self.contentView.frame.size.width - infoX - self.bleImage.frame.size.width - crosswiseCornerInterval;
    self.deviceName.frame = CGRectMake(infoX, lengthwaysCornerInterval, width, self.deviceName.frame.size.height);
    
    // 设置蓝牙图标位置
    x = self.deviceName.frame.origin.x + self.deviceName.frame.size.width;
    self.bleImage.frame = CGRectMake(x, lengthwaysCornerInterval, self.bleImage.frame.size.width, self.bleImage.frame.size.height);
    
    // 设置状态图标位置
    y = self.contentView.frame.size.height / 2 - self.statusIcon.frame.size.height / 2;
    self.statusIcon.frame = CGRectMake(infoX, y, self.statusIcon.frame.size.width, self.statusIcon.frame.size.height);
    
    // 设置状态描述位置
    x = self.statusIcon.frame.origin.x + self.statusIcon.frame.size.width;
    self.statusDescribe.frame = CGRectMake(x, y, self.statusDescribe.frame.size.width, self.statusDescribe.frame.size.height);
    
    // 设置温度图标位置
    y = self.contentView.frame.size.height - self.tempIcon.frame.size.height;
    y -= self.contentView.frame.size.height * 0.1; // 温度以及电量的边角间隔
    self.tempIcon.frame = CGRectMake(infoX, y, self.tempIcon.frame.size.width, self.tempIcon.frame.size.height);
    
    // 设置温度值显示位置
    x = infoX + self.tempIcon.frame.size.width;
    self.tempValue.frame = CGRectMake(x, y, self.tempValue.frame.size.width, self.tempValue.frame.size.height);
    
    // 设置电量图标位置
    x = x + (self.contentView.frame.size.width - infoX) * 0.4; // 温度与电量之间的间隔
    self.percentIcon.frame = CGRectMake(x, y, self.percentIcon.frame.size.width, self.percentIcon.frame.size.height);
    
    // 设置电量值显示位置
    x = x + self.percentIcon.frame.size.width;
    self.percentValue.frame = CGRectMake(x, y, self.percentValue.frame.size.width, self.percentValue.frame.size.height);
    
    // 设置连接按钮位置
    x = self.contentView.frame.size.width - self.connectBtn.frame.size.width - crosswiseCornerInterval;
    y = self.contentView.frame.size.height - self.connectBtn.frame.size.height - lengthwaysCornerInterval;
    self.connectBtn.frame = CGRectMake(x, y, self.connectBtn.frame.size.width, self.connectBtn.frame.size.height);
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

