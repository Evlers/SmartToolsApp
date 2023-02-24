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

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // 调整图片大小
//    CGSize itemSize = CGSizeMake(50, 50);
//    UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
//    CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
//    [self.deviceImage.image drawInRect:imageRect];
//    self.deviceImage.image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    // 不执行高亮动作
//    [super setHighlighted:highlighted animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
}

@end

