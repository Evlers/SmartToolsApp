//
//  DeviceTableViewCell.m
//  SmartTools
//
//  Created by Evler on 2023/2/20.
//

#import "DeviceTableViewCell.h"

//@interface DeviceTableViewCell()
//
//@end

@implementation DeviceTableViewCell

+ (instancetype)xibTableViewCell {
    //在类方法中加载xib文件,注意:loadNibNamed:owner:options:这个方法返回的是NSArray,所以在后面加上firstObject或者lastObject或者[0]都可以；因为我们的XIB文件中，只有一个Cell
    return [[[NSBundle mainBundle] loadNibNamed:@"DeviceTableViewCell" owner:nil options:nil] lastObject];
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

