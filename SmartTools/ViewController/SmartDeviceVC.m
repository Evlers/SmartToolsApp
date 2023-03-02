//
//  SmartDeviceVC.m
//  SmartTools
//
//  Created by Evler on 2022/12/27.
//

#import "SelectDevice.h"
#import "SmartProtocol.h"
#import "SmartDevice.h"
#import "SmartDeviceVC.h"
#import "FirmwareFile.h"
#import "Utility.h"
#import "SSZipArchive.h"
#import "Masonry.h"
#import "DeviceTableViewCell.h"

@implementation DataPoint

- (DataPoint *)initWithName:(NSString *)name {
    self.name = name;
    self.value = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    return self;
}

- (DataPoint *)initWithName:(NSString *)name type:(UITableViewCellAccessoryType)type {
    self.name = name;
    self.value = nil;
    self.accessoryType = type;
    return self;
}

- (DataPoint *)initWithName:(NSString *)name value:(NSString *)value {
    self.name = name;
    self.value = value;
    self.accessoryType = UITableViewCellAccessoryNone;
    return self;
}

@end


@interface SmartDeviceVC () <UITableViewDelegate, UITableViewDataSource, SmartDeviceDelegate>
{
    CGFloat cornerRadius; // cell圆角
    CGRect bounds; // cell尺寸
}

//@property (nonatomic, strong) SmartDevice *smart_device;
@property (nonatomic, strong) UIAlertController *alert;     // 提示窗口
@property (nonatomic, strong) UITableView *table;           // 功能列表视图
@property (nonatomic, strong) NSMutableArray *data_point;   // 数据点,嵌套可变数组,第一级为 Table 组
@property (nonatomic, strong) UIAlertController *alertFirmwareUpgrade; // 固件升级提示框
@property (nonatomic, strong) UIProgressView *upgradeProgress; // 固件升级进度
@property (nonatomic, strong) NSMutableArray<FileInfo *> *allFileInfo; // App内所有文件信息
@property (nonatomic, strong) NSMutableArray<FileInfo *> *upgradeFile; // 可用的升级文件
@property (nonatomic, assign) NSInteger upgrqadeFileSelect; // 升级文件的选择

@end

@implementation SmartDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.upgradeFile = nil;
    cornerRadius = 8.f;
    self.data_point = [NSMutableArray array];
    
    // 创建TableView
    self.table = [[UITableView alloc]init];
    self.table.delegate = self;
    self.table.dataSource = self;
    self.table.estimatedRowHeight = UITableViewAutomaticDimension; // 预计高度
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone; // 每行之间无分割线
    [self.view addSubview:self.table];
    [self.table mas_makeConstraints:^(MASConstraintMaker * make) {
        make.edges.equalTo(self.view);
    }];
    
    // device base info
    NSMutableArray *dev_base_info = [NSMutableArray array];
    [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Firmware version"]];
    [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Hardware version"]];
    [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Device uuid"]];
    [self.data_point addObject:dev_base_info];
    [self.table insertSections:[NSIndexSet indexSetWithIndex:self.data_point.count] withRowAnimation:UITableViewRowAnimationNone]; // 插入数据
    
    // battery base info
    NSMutableArray *bat_base_info = [NSMutableArray array];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Battery temperature"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Protection voltage"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Maximum discharge current"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Function switch"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Battery status"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Work mode"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Work time"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Charger times"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Discharger times"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Current current"]];
    [bat_base_info addObject:[[DataPoint alloc]initWithName:@"Battery percent"]];
    [self.data_point addObject:bat_base_info];
    [self.table insertSections:[NSIndexSet indexSetWithIndex:self.data_point.count] withRowAnimation:UITableViewRowAnimationNone]; // 插入数据
    
    // 读取所有文件
    NSString *inboxPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Inbox/"]]; // 总文件夹
    self.allFileInfo = [FileInfo readAllFileInfoInFolder:inboxPath]; // 读取该文件夹下的所有文件信息
}

// 即将进入视图
-(void)viewWillAppear:(BOOL)animated {
    
    self.smartDevice.delegate = self; // 代理智能设备接口
    if (self.smartDevice.baseInfo.peripheral.state == CBPeripheralStateConnected) // 如果已连接蓝牙
        [self.smartDevice getDeviceAllData]; // 查询所有设备信息
    else { // 未连接，等待设备连接
        self.alert = [UIAlertController alertControllerWithTitle:@"Cconnecting" message:@"Connecting device.." preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:self.alert animated:YES completion:nil]; // 显示提示窗口
    }
    
    self.title = self.smartDevice.baseInfo.product_info.default_name; // 刷新标题
}

#pragma mark -- TableView 接口

// 返回组数量
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data_point.count + 1;
}

// 返回每组行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    
    return ((NSMutableArray *)[self.data_point objectAtIndex:section - 1]).count;
}

// 返回每组的头数据
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section)
    {
        case 0: return @"Base info";
        case 1: return @"Device info";
        case 2: return @"Battery info";
        default: return @"Unknown section";
    }
}

// TableView接口：即将显示Cell
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 0.cell背景透明，否则不会出现圆角效果
    cell.backgroundColor = [UIColor clearColor];

    // 原因如下：
    // 之所以设置为透明，是因为cell背景色backGroundColor是直接设置在UITableViewCell上面的，位于cell的第四层
    // backGroundView是在UITableViewCell之上的，也就是位于cell的第三层
    // 我们所要做的操作是在backGroundView上，也就是第三层
    // 第三层会挡住第四层，如果第四层设置了颜色，那么将来cell的圆角部分会露出第四层的颜色，也就是背景色
    // 所以，必须设置cell的背景色为透明色！
    // 另外:
    // 第二层是UITableViewCellContentView，默认就是透明的，无需设置
    // 第一层是UITableViewLabel，也就是cell.textLabel

    // 1.创建path,保存绘制的路径
    CGMutablePathRef pathRef = CGPathCreateMutable();
    pathRef = [self drawPathRef:pathRef forCell:cell atIndexPath:indexPath];

    // 2.创建layer,渲染效果
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    [self renderCornerRadiusLayer:layer withPathRef:pathRef toCell:cell];
}

// 返回每行的数据
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) { // 设备基本信息
        static NSString *identifier = @"DeviceTableViewCell";
        DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; // 通过队列ID出列Cell
        if (cell == nil) {
            cell = [[DeviceTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        
        SmartBattery *battery = self.smartDevice.battery;
        
        uint8_t *dev_id = self.smartDevice.baseInfo.manufacture_data->device_id;
        uint8_t capacity = self.smartDevice.baseInfo.manufacture_data->capacity_value * 0.5 + 1.5; // 计算电池容量
        NSString *dev_name = [NSString stringWithFormat:@"%@ %dAH #%02X%02X", self.smartDevice.baseInfo.product_info.default_name, capacity, dev_id[0], dev_id[1]];
        
        [cell setDeviceName:dev_name state:self.smartDevice.baseInfo.state info:battery]; // 设置基本信息
        return cell;
    }
    else
    {
        static NSString *identifier = @"System Cell";
        DataPoint *data_point = [(NSMutableArray *)[self.data_point objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; // 通过通用队列ID出列Cell
        
        if(cell == nil) { // 没有创建过此Cell
            cell = [[DevParamUITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier]; // 创建新的Cell
        }
        
        // 配置通用Cell的显示数据
        cell.accessoryType = data_point.accessoryType;
        cell.textLabel.text = data_point.name;
        cell.detailTextLabel.text = (data_point.value == nil) ? @"" : data_point.value;
        return cell;
    }
}

// 选中
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section != 0)
    {
        DataPoint *data_point = [(NSMutableArray *)[self.data_point objectAtIndex:indexPath.section - 1] objectAtIndex:indexPath.row];
        if ( self.allFileInfo.count && [data_point.name containsString:@"Firmware version"]) {
            self.upgrqadeFileSelect = 0; // 先选择第一个升级文件(根据读取文件的方法，第一个是旧的文件)
            [self promptUpdateInformation]; // 提示更新信息
        }
    }
    [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES]; // 取消选中
}

// 设置数据点
- (NSIndexPath *)set_data_poinit:(NSString *)name value:(NSString *)value {
    for (NSMutableArray *group in self.data_point) {
        for (DataPoint *data_point in group) {
            if (data_point.name == name) {
                data_point.value = value;
                return [NSIndexPath indexPathForRow:[group indexOfObject:data_point] inSection:[self.data_point indexOfObject:group] + 1];
            }
        }
    }
    return nil;
}

- (NSIndexPath *)set_data_poinit:(NSString *)name value:(NSString *)value type:(UITableViewCellAccessoryType)type {
    for (NSMutableArray *group in self.data_point) {
        for (DataPoint *data_point in group) {
            if (data_point.name == name) {
                data_point.value = value;
                data_point.accessoryType = type;
                return [NSIndexPath indexPathForRow:[group indexOfObject:data_point] inSection:[self.data_point indexOfObject:group] + 1];
            }
        }
    }
    return nil;
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

// 提示更新信息
- (void)promptUpdateInformation {
    
    if (self.upgradeFile.count == 0) return ; // 没有可用的升级文件
    Firmware *firmware = [[Firmware alloc]initWithLoadFirmware:self.upgradeFile[self.upgrqadeFileSelect].path];
    if (firmware == nil) {
        NSLog(@"Failed to parse the upgrade file: %@", self.upgradeFile[self.upgrqadeFileSelect].path);
        return ;
    }
    
    // 设置消息内容
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss a\r\n"]; // 格式化时间
    NSString *msg = [NSMutableString stringWithFormat:@"Date: %@", [dateFormatter stringFromDate:self.upgradeFile[self.upgrqadeFileSelect].date]];
    for (FirmwareFile *bin_file in firmware.bin_file) {
        if (bin_file.type == FirmwareFileTypeAppliction) {
            msg = [msg stringByAppendingFormat:@"Application version: %@", bin_file.version];
        } else if (bin_file.type == FirmwareFileTypeBootloader) {
            msg = [msg stringByAppendingFormat:@"Bootloader version: %@", bin_file.version];
        }
        
        if ([firmware.bin_file indexOfObject:bin_file] != (firmware.bin_file.count - 1) || firmware.update_content != nil) {
            msg = [msg stringByAppendingString:@"\n"];
        }
    }
    
    if (firmware.update_content != nil)
        msg = [msg stringByAppendingFormat:@"\n%@", firmware.update_content];
    
    // 设置消息内容的字体
    NSMutableAttributedString *alertControllerMessageStr = [[NSMutableAttributedString alloc] initWithString:msg];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentLeft; // 左对齐
    [alertControllerMessageStr setAttributes:@{NSParagraphStyleAttributeName:paragraph} range:NSMakeRange(0, alertControllerMessageStr.length)];
    [alertControllerMessageStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13] range:NSMakeRange(0, alertControllerMessageStr.length)];

    // 设置消息框
    UIAlertController *upgradeAlertView = [UIAlertController alertControllerWithTitle:self.upgradeFile[self.upgrqadeFileSelect].name message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *actionNext = [UIAlertAction actionWithTitle:@"Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        self.upgrqadeFileSelect ++; // 选择下一个文件
        [self promptUpdateInformation]; // 提示下一个文件信息
    }];
    UIAlertAction *actionUpgrade = [UIAlertAction actionWithTitle:@"Upgrade" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        [self startFirmwareUpgrade];
    }];
    [upgradeAlertView setValue:alertControllerMessageStr forKey:@"attributedMessage"]; // 添加消息内容
    
    if (self.upgradeFile.count > 1 && self.upgrqadeFileSelect < (self.upgradeFile.count - 1)) // 还有文件可以选择
        [upgradeAlertView addAction:actionNext];
    else
        [upgradeAlertView addAction:actionCancel];
    [upgradeAlertView addAction:actionUpgrade];
    [self presentViewController:upgradeAlertView animated:YES completion:nil]; // 显示提示窗口
}

// 开始固件升级
- (void)startFirmwareUpgrade {
    
    NSLog(@"Start firmware upgrade.");
    self.alertFirmwareUpgrade = [UIAlertController alertControllerWithTitle:@"updating..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    self.upgradeProgress = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    [self.upgradeProgress setFrame:CGRectMake(15, 50, 235, 10)];
    self.upgradeProgress.progress = 0;
    [self.alertFirmwareUpgrade.view addSubview:self.upgradeProgress];
    
    if ([self.smartDevice startFirmwareUpgrade:self.upgradeFile[self.upgrqadeFileSelect].path] == false) {// 开始升级智能设备
        return ;
    }
    
    [self presentViewController:self.alertFirmwareUpgrade animated:YES completion:nil]; // 显示升级提示框
}

// 设备固件升级状态更新
- (void)smartDeviceUpgradeStateUpdate:(SmartDeviceUpgradeState)state withResult:(uint8_t)result {
    if (result != 0) { // 升级错误
        NSString *message;
        switch (state)
        {
            case SmartDeviceUpgradeStateResponseRequest:
                message = [NSString stringWithFormat:@"Device refused to upgrade, code: %u", result];
                break;
                
            case SmartDeviceUpgradeStateSentFileInfo:
                message = [NSString stringWithFormat:@"File information error, code: %u", result];
                break;
                
            case SmartDeviceUpgradeStateSentOffset:
                message = [NSString stringWithFormat:@"Failed to set the offset address, code: %u", result];
                break;
                
            case SmartDeviceUpgradeStateTransData:
                message = [NSString stringWithFormat:@"File transfer error, code: %u", result];
                break;
                
            case SmartDeviceUpgradeStateEnd:
                message = [NSString stringWithFormat:@"File validation error, code: %u", result];
                break;
                
            case SmartDeviceUpgradeStateTimeout:
                message = [NSString stringWithFormat:@"Wait response timeout, code: %u", result];
                break;
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
        UIAlertController *alertUpgradeError = [UIAlertController alertControllerWithTitle:@"Firmware upgrade failed" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertUpgradeError addAction:actionOK];
        [self presentViewController:alertUpgradeError animated:YES completion:nil];
        
    } else if (state == SmartDeviceUpgradeStateEnd) { // 升级成功
        self.alertFirmwareUpgrade = nil;
        [self dismissViewControllerAnimated:YES completion:nil]; // 退出升级窗口
        [self.navigationController popToRootViewControllerAnimated:YES]; // 设备已断开连接并重启,退出设备页面
        UIAlertController *alertUpgradeDone = [UIAlertController alertControllerWithTitle:@"Firmware upgrade success" message:@"Device will reboot\nDo you want to delete the upgrade file ?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionNO = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action){
            NSFileManager *fileManage = [NSFileManager defaultManager];
            if ([fileManage removeItemAtPath:self.upgradeFile[self.upgrqadeFileSelect].path error:nil]) { // 删除已经升级完成的文件
                NSLog(@"Delete upgrade firmware file success");
            } else {
                NSLog(@"Delete upgrade firmware file failed!");
            }
        }];
        
        [alertUpgradeDone addAction:actionNO];
        [alertUpgradeDone addAction:actionDelete];
        [self presentViewController:alertUpgradeDone animated:YES completion:nil]; // 提示升级完成窗口
    }
}

// 设备固件升级进度
- (void)smartDevice:(SmartDevice *)device upgradeProgress:(float)progress {
    self.upgradeProgress.progress = progress;
    self.alertFirmwareUpgrade.title = [NSString stringWithFormat:@"updating... %u%%", (uint32_t)(progress * 100.0)];
}

// 搜索当前连接的智能设备可用的升级文件
- (void)searchUpgradeFile {
    
    if (self.smartDevice.baseInfo.hardware_version == nil) return ; // 硬件版本号是否已就绪
    if (self.smartDevice.baseInfo.app_firmware_version == nil) return ; // 固件版本号是否已就绪
    
    NSData *device_pid = [NSData dataWithBytes:self.smartDevice.baseInfo.manufacture_data->product_id length:sizeof(self.smartDevice.baseInfo.manufacture_data->product_id)];
    NSDictionary<NSString *, id> *filtration = @{@"product id": device_pid,
                                                 @"hardware version": self.smartDevice.baseInfo.hardware_version,
                                                 @"bootloader firmware version": self.smartDevice.baseInfo.boot_firmware_version,
                                                 @"application firmware version": self.smartDevice.baseInfo.app_firmware_version
    };
    self.upgradeFile = [Firmware getAvaliableFirmwareInAllFile:self.allFileInfo filtration:filtration]; // 通过筛选项获取当前连接设备可用的固件
}

// 智能设备数据更新
- (void)smartDevice:(SmartDevice *)device dataUpdate:(NSDictionary <NSString *, id>*)data; {
    
    NSIndexPath *index = nil;
    
    for (NSString *key in data) { // 遍历字典
        if ([key containsString:@"Handshake connection"]) { // 握手连接
            NSLog(@"Handshake connect success.");
            
        } else if ([key containsString:@"Firmware version"]) { // 固件版本
            NSArray *version_info = data[key];
//            NSString *boot_version = version_info[0];
            NSString *app_version = version_info[1];
//            NSLog(@"Smart device bootloader version: %@", boot_version);
            
            [self searchUpgradeFile]; // 搜索可用的升级文件
            UITableViewCellAccessoryType type = (self.upgradeFile == nil || self.upgradeFile.count == 0) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
            index = [self set_data_poinit:key value:app_version type:type]; // 设置Cell
            
        } else if ([key containsString:@"Hardware version"]) { // 硬件版本
            [self searchUpgradeFile]; // 搜索可用的升级文件
            UITableViewCellAccessoryType type = (self.upgradeFile == nil || self.upgradeFile.count == 0) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
            index = [self set_data_poinit:@"Firmware version" value:self.smartDevice.baseInfo.app_firmware_version type:type]; // 设置固件版本Cell
            [UIView performWithoutAnimation:^{ // 无动画
                [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:index] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
            }];
            index = [self set_data_poinit:key value:data[key]]; // 设置硬件版本Cell
            
        } else {// 其他数据的key跟数据点名称一样，且value都是NSString类型的
            index = [self set_data_poinit:key value:data[key]]; // 根据key更新对应数据点的值
            if (index == nil) { // 未知数据
                NSDictionary *unknown = data[key];
                NSLog(@"Unknown code: %d data: %@", ((uint8_t *)((NSData *)unknown[@"body code"]).bytes)[0], unknown[@"body data"]);
            }
        }
        
        if (index != nil) { // 已更新对应的数据点, 通知UITableView更新显示数据
            [UIView performWithoutAnimation:^{ // 无动画
                [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:index] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
            }];
        }
        
        // 刷新设备基本信息
        [UIView performWithoutAnimation:^{ // 无动画
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新设备基本信息
        }];
    }
}

// 智能设备状态已更新
- (void)smartDevice:(SmartDevice *)device didUpdateState:(SmartDeviceState)state {
    
    switch (state)
    {
        case SmartDeviceBLECononectFailed:
        case SmartDeviceBLEServiceError:
        case SmartDeviceBLECharacteristicError:
            [self.navigationController popToRootViewControllerAnimated:YES]; // 退出到主窗口
            break;
            
        case SmartDeviceBLEDisconnected:
            if (self.alert != nil) {// 如果还没连接完成就被退出窗口
                self.alert = nil;
                [self dismissViewControllerAnimated:YES completion:nil]; // 退出提示框
            } else if (self.alertFirmwareUpgrade != nil) {
                self.alertFirmwareUpgrade = nil;
                [self dismissViewControllerAnimated:YES completion:nil]; // 退出提示框
            }
            [self.navigationController popToRootViewControllerAnimated:YES]; // 退出到主窗口
            break;
            
        case SmartDeviceBLEConnecting:
            self.alert.message = @"Connecting device..";
            break;
            
        case SmartDeviceBLEConnected:
            self.alert.message = @"Discover srervices..";
            break;
            
        case SmartDeviceBLEDiscoverServer:
            self.alert.message = @"Discover characteristics..";
            break;
            
        case SmartDeviceBLEDiscoverCharacteristic:
            self.alert.message = @"Enable notify..";
            break;
            
        case SmartDeviceBLENotifyEnable:
            self.alert.message = @"Shaking..";
            break;
            
        case SmartDeviceConnectSuccess:
            self.alert = nil; // 清除提示窗口
            [self dismissViewControllerAnimated:YES completion:nil]; // 退出提示框
            break;
            
        case SmartDeviceConnectTimeout:
            self.alert = nil; // 清除提示窗口
            [self dismissViewControllerAnimated:YES completion:nil]; // 退出提示框
            [self.navigationController popToRootViewControllerAnimated:YES]; // 退出到主页面
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
