//
//  FirmwareUpgradeCell.h
//  SmartTools
//
//  Created by Evler on 2023/1/10.
//

#ifndef FirmwareUpgradeCell_h
#define FirmwareUpgradeCell_h

#import <UIKit/UIKit.h>

@interface FirmwareUpgradeCell : UITableViewCell

@property (nonatomic, strong) UILabel     *currentVersion;    // 当前版本
@property (nonatomic, strong) UILabel     *latestVersion;     // 最新版本
@property (nonatomic, strong) UILabel     *updateContent;     // 更新内容
@property (nonatomic, strong) UIButton    *upgradeBtn;        // 升级按钮

@end


#endif /* FirmwareUpgradeCell_h */
