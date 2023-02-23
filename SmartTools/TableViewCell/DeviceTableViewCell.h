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

@property (nonatomic, weak) IBOutlet UILabel *deviceName;
@property (nonatomic, weak) IBOutlet UILabel *statusDescribe;
@property (nonatomic, weak) IBOutlet UILabel *tempValue;
@property (nonatomic, weak) IBOutlet UILabel *percentValue;
@property (nonatomic, weak) IBOutlet UIImageView *statusIcon;
@property (weak, nonatomic) IBOutlet UIImageView *deviceImage;
@property (nonatomic, weak) IBOutlet UIImageView *bleImage;
@property (weak, nonatomic) IBOutlet UIImageView *tempIcon;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UIImageView *percentIcon;

+(instancetype)xibTableViewCell;

@end

#endif /* DeviceTableViewCell_h */
