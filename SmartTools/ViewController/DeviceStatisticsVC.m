//
//  DeviceStatisticsVC.m
//  SmartTools
//
//  Created by Evler on 2023/3/8.
//

#import <Foundation/Foundation.h>
#import "SmartDevice.h"
#import "DeviceStatisticsVC.h"
#import "DeviceTableViewCell.h"
#import "Masonry.h"

@interface DeviceStatisticsVC () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SmartDeviceDelegate>
{
    CGFloat cornerRadius; // cell圆角
    CGRect bounds; // cell尺寸
}

@property (nonatomic, strong) UITableView *table; // TableView
@property (nonatomic, strong) NSMutableArray<NSArray<NSString *> *> *tableData; // 设备信息 嵌套：组 行

@end

@implementation DeviceStatisticsVC


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Statistics";
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    cornerRadius = 10.0;
    
    // 设置智能设备
    self.smartDevice.delegate = self; // 代理智能设备接口
    if (self.smartDevice.baseInfo.product_info.type == SmartDeviceProductTypeBattery)
        [self.smartDevice getBatteryVoltage]; // 查询电池电压
    
    // 创建TableView
    self.table = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
    self.table.delegate = self;
    self.table.dataSource = self;
    self.table.estimatedRowHeight = UITableViewAutomaticDimension; // 预计高度
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone; // 每行之间无分割线
    [self.view addSubview:self.table];
    [self.table mas_makeConstraints:^(MASConstraintMaker * make) {
        make.edges.equalTo(self.view);
    }];
    
    // 配置列表项目
    self.tableData = [NSMutableArray array];
    [self.tableData addObject:@[@"Accum work hours"]];
    [self.tableData addObject:@[@"Number of charging", @"Number of discharging"]];
    [self.tableData addObject:@[@"Number of over current", @"Number of short circuits"]];
}

#pragma mark -- TableView 接口

// 返回每行的数据
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"System Cell";
    NSString *title = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; // 通过通用队列ID出列Cell
    
    if(cell == nil) { // 没有创建过此Cell
        cell = [[DevParamUITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier]; // 创建新的Cell
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.textLabel.text = title;
    if ([title containsString:@"Accum work hours"]) {
        int hour = self.smartDevice.battery.accumulatedWorkTime / 60;
        int minute = self.smartDevice.battery.accumulatedWorkTime - (hour * 60);
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%u hour and %u minutes", hour, minute];
        
    } else if ([title containsString:@"Number of charging"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%u times", self.smartDevice.battery.numberOfCharging];
    } else if ([title containsString:@"Number of discharging"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%u times", self.smartDevice.battery.numberOfDischarging];
    } else if ([title containsString:@"Number of over current"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%u times", self.smartDevice.battery.numberOfOverCurrent];
    } else if ([title containsString:@"Number of short circuits"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%u times", self.smartDevice.battery.numberOfShortCircuit];
    }
    
    return cell;
}

// 返回组数量
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tableData.count;
}

// 返回每组行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableData objectAtIndex:section].count;
}

// 组头高度
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 30;
    return 1;
}

// 返回每组的头数据
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

// TableView接口：即将显示Cell
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 0.cell背景透明，否则不会出现圆角效果
    cell.backgroundColor = [UIColor clearColor];

    // 1.创建path,保存绘制的路径
    CGMutablePathRef pathRef = CGPathCreateMutable();
    pathRef = [self drawPathRef:pathRef forCell:cell atIndexPath:indexPath];

    // 2.创建layer,渲染效果
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    [self renderCornerRadiusLayer:layer withPathRef:pathRef toCell:cell];
}

// 选中
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES]; // 取消选中
}

#pragma mark - private method
- (CGMutablePathRef)drawPathRef:(CGMutablePathRef)pathRef forCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // cell的bounds
    bounds = cell.bounds;
    
    if (indexPath.row == 0 && indexPath.row == [self.table numberOfRowsInSection:indexPath.section] - 1) {
        // 1.既是第一行又是最后一行
        // 1.1.底端中点 -> cell左下角
        CGPathMoveToPoint(pathRef, nil, CGRectGetMidX(bounds), CGRectGetMaxY(bounds));
        // 1.2.左下角 -> 左端中点
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMinX(bounds), CGRectGetMidY(bounds), cornerRadius);
        // 1.3.左上角 -> 顶端中点
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
        // 1.4.cell右上角 -> 右端中点
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        // 1.5.cell右下角 -> 底端中点
        CGPathAddArcToPoint(pathRef, nil,   CGRectGetMaxX(bounds), CGRectGetMaxY(bounds),CGRectGetMidX(bounds), CGRectGetMaxY(bounds),cornerRadius);
        
        return pathRef;
        
    } else if (indexPath.row == 0) {
        // 2.每组第一行cell
        // 2.1.起点： 左下角
        CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
        // 2.2.cell左上角 -> 顶端中点
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
        // 2.3.cell右上角 -> 右端中点
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        // 2.4.cell右下角
        CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
        // 绘制cell分隔线
        // addLine = YES;
        return pathRef;
        
    } else if (indexPath.row == [self.table numberOfRowsInSection:indexPath.section] - 1) {
        // 3.每组最后一行cell
        // 3.1.初始起点为cell的左上角坐标
        CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
        // 3.2.cell左下角 -> 底端中点
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
        // 3.3.cell右下角 -> 右端中点
        CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
        // 3.4.cell右上角
        CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
       
        return pathRef;
        
    } else if (indexPath.row != 0 && indexPath.row != [self.table numberOfRowsInSection:indexPath.section] - 1) {
        // 4.每组的中间行
        CGPathAddRect(pathRef, nil, bounds);
        
        return pathRef;
    }
    return nil;
}

- (void)renderCornerRadiusLayer:(CAShapeLayer *)layer withPathRef:(CGMutablePathRef)pathRef toCell:(UITableViewCell *)cell {
    // 绘制完毕，路径信息赋值给layer
    layer.path = pathRef;
    // 注意：但凡通过Quartz2D中带有creat/copy/retain方法创建出来的值都必须要释放
    CFRelease(pathRef);
    // 按照shape layer的path填充颜色，类似于渲染render
    layer.fillColor = [UIColor whiteColor].CGColor;
    
    // 创建和cell尺寸相同的view
    UIView *backView = [[UIView alloc] initWithFrame:bounds];
    // 添加layer给backView
    [backView.layer addSublayer:layer];
    // backView的颜色
    backView.backgroundColor = [UIColor clearColor];
    // 把backView添加给cell
    cell.backgroundView = backView;
}

#pragma mark -- Smart device interface

// 智能设备数据更新
- (void)smartDevice:(SmartDevice *)device dataUpdate:(NSDictionary <NSString *, id>*)data; {
    
    if (self.tableData == nil) return ;
    for (int section = 0; section < self.tableData.count; section ++) { // 刷新列表中的数据
        for (int row = 0; row < [self.tableData objectAtIndex:section].count; row ++) {
            [UIView performWithoutAnimation:^{ // 无动画
                NSIndexPath *i = [NSIndexPath indexPathForRow:row inSection:section];
                [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:i] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
            }];
        }
    }
}

// 智能设备状态已更新
- (void)smartDevice:(SmartDevice *)device didUpdateState:(SmartDeviceState)state {
    
    switch (state)
    {
        case SmartDeviceBLECononectFailed:
        case SmartDeviceBLEServiceError:
        case SmartDeviceBLECharacteristicError:
        case SmartDeviceBLEDisconnected:
            [self.navigationController popToRootViewControllerAnimated:YES]; // 退出到主窗口
            break;
            
        default: break;
    }
}

@end
