//
//  FirmwareUpgradeCell.m
//  SmartTools
//
//  Created by Evler on 2023/1/10.
//

#import "FirmwareUpgradeCell.h"

@implementation FirmwareUpgradeCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.currentVersion = [[UILabel alloc]init];
        self.currentVersion.text = @"Current version";
        [self.contentView addSubview:self.currentVersion];
        
        self.latestVersion = [[UILabel alloc]init];
        [self.contentView addSubview:self.latestVersion];
        
        self.updateContent = [[UILabel alloc]init];
        [self.contentView addSubview:self.updateContent];
        
        self.upgradeBtn = [[UIButton alloc]init];
        [self.contentView addSubview:self.upgradeBtn];
        NSLog(@"Firmware upgrqade cell init done");
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

// 选中
-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    NSLog(@"Firmware upgrade cell selected");
}

@end
