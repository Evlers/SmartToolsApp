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
#import "FirmwareUpgradeCell.h"
#import "Utility.h"
#import "SSZipArchive.h"

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

@property (nonatomic, strong) SmartDevice *smart_device;
@property (nonatomic, strong) UIAlertController *alert;     // 提示窗口
@property (nonatomic, strong) UITableView *table;           // 功能列表视图
@property (nonatomic, strong) NSMutableArray *data_point;   // 数据点,嵌套可变数组,第一级为 Table 组
@property (nonatomic, strong) UIAlertController *alertFirmwareUpgrade; // 固件升级提示框
@property (nonatomic, strong) UIProgressView *upgradeProgress; // 固件升级进度
@property (nonatomic, strong) NSMutableArray *allFileInfo; // App内所有文件信息

@end

@implementation SmartDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.data_point = [NSMutableArray array];
    
    self.table = [self.view viewWithTag:10];
    self.table.delegate = self;
    self.table.dataSource = self;
    
    self.allFileInfo = [NSMutableArray array];
    NSString *inboxPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Inbox/"]]; // 总文件夹
    [Utility readAllFileInfo:self.allFileInfo folderPath:inboxPath]; // 读取该文件夹下的所有文件信息
    
    // SSZipArchive: https://github.com/ZipArchive/ZipArchive
//    for (FileInfo *info in self.allFileInfo) { // 遍历文件
//        if ([info.path hasSuffix:@".zip"]) { // zip文件
//            NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject]; // caches路径
//            NSString *path = [cachesPath stringByAppendingPathComponent:@"firmwareFile"]; // 解压目标路径
//            if ([SSZipArchive unzipFileAtPath:info.path toDestination:path]) { // 解压该文件到caches中的firmwareFile目录
//                NSLog(@"file path: %@\r\n%@", info.path, path);
//                NSMutableArray *firmwareFile = [NSMutableArray array];
//                [Utility readAllFileInfo:firmwareFile folderPath:path];
//                for (FileInfo *info in firmwareFile) {
//                    NSLog(@"name: %@ size: %lu", info.name, info.size);
//                }
//            }
//        }
//    }
    
    NSLog(@"Smart device view init done");
}

// 即将进入视图
-(void)viewWillAppear:(BOOL)animated {
    
    [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES]; // 取消选中
    if (self.device.peripheral.state == CBPeripheralStateConnected) return ; // 如果已连接则不执行以下处理
    
    self.smart_device = [[SmartDevice alloc]initWithCentralManager:self.centralManager]; // 创建智能设备
    self.smart_device.delegate = self; // 代理智能设备接口
    self.smart_device.device = self.device; // 复制设备信息
    [self.smart_device connectDevice:self.device]; // 连接设备
    
    self.alert = [UIAlertController alertControllerWithTitle:@"Cconnecting" message:@"Connect device.." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:self.alert animated:YES completion:nil]; // 显示提示窗口
    
    // 配置数据点列表
    [self.data_point removeAllObjects];
    [self.table reloadData];
    
    // device base info
    NSMutableArray *dev_base_info = [NSMutableArray array];
    if (self.allFileInfo.count) // 有固件包
        [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Firmware version" type:UITableViewCellAccessoryDisclosureIndicator]];
    else // 本地没有固件包
        [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Firmware version"]];
    [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Hardware version"]];
    [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Device uuid"]];
    [self.data_point addObject:dev_base_info];
    [self.table insertSections:[NSIndexSet indexSetWithIndex:self.data_point.count-1] withRowAnimation:UITableViewRowAnimationLeft]; // 插入数据
    
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
    [self.table insertSections:[NSIndexSet indexSetWithIndex:self.data_point.count-1] withRowAnimation:UITableViewRowAnimationLeft]; // 插入数据
    
    // 组合设备名
    uint8_t capacity = self.device.manufacture_data->capacity_value * 0.5 + 1.5; // 计算电池容量
    NSString *dev_name = [NSString stringWithFormat:@"%@ %dAH",
                          self.device.product_info.default_name, capacity];
    self.title = dev_name; // 刷新标题
}

// 已经离开此页面
- (void)viewDidDisappear:(BOOL)animated {
    [self.smart_device disconnectDevice]; // 断开设备连接
}

#pragma mark -- TableView 接口

// 返回组数量
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data_point.count;
}

// 返回每组行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSMutableArray *)[self.data_point objectAtIndex:section]).count;
}

// 返回每组的头数据
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section)
    {
        case 0: return @"Device info";
        case 1: return @"Battery info";
        default: return @"Unknown section";
    }
}

// 返回每行的数据
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DataPoint *data_point = [(NSMutableArray *)[self.data_point objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *identifier = [NSString stringWithFormat:@"cell %ld %ld",(long)indexPath.section,(long)indexPath.row]; // 生成通用队列ID
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; // 通过通用队列ID出列Cell
    
    if(cell == nil) { // 没有创建过此Cell
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier]; // 创建新的Cell
        cell.accessoryType = data_point.accessoryType;
    }
    
    // 配置通用Cell的显示数据
    cell.textLabel.text = data_point.name;
    cell.detailTextLabel.text = (data_point.value == nil) ? @"" : data_point.value;
    return cell;
}

// 选中
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DataPoint *data_point = [(NSMutableArray *)[self.data_point objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if ( self.allFileInfo.count && [data_point.name containsString:@"Firmware version"]) {
        UIAlertController *upgradeAlertView = [UIAlertController alertControllerWithTitle:@"Firmware upgrade" message:@"latest version: v1.0.0" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *actionUpgrade = [UIAlertAction actionWithTitle:@"Upgrade" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
            [self startFirmwareUpgrade];
        }];
        
        [upgradeAlertView addAction:actionCancel];
        [upgradeAlertView addAction:actionUpgrade];
        [self presentViewController:upgradeAlertView animated:YES completion:^{
            [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES]; // 取消选中
        }]; // 显示提示窗口
        
    } else {
        [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES]; // 取消选中
    }
}

// 设置数据点
- (NSIndexPath *)set_data_poinit:(NSString *)name value:(NSString *)value {
    for (NSMutableArray *group in self.data_point) {
        for (DataPoint *data_point in group) {
            if (data_point.name == name) {
                data_point.value = value;
                return [NSIndexPath indexPathForRow:[group indexOfObject:data_point] inSection:[self.data_point indexOfObject:group]];
            }
        }
    }
    return nil;
}

#pragma mark -- Smart device interface

// 开始固件升级
- (void)startFirmwareUpgrade {
    
    NSString *FirmwareFilePath = nil;
    for (FileInfo *info in self.allFileInfo) { // 遍历文件
        if ([info.path hasSuffix:@".zip"]) // zip文件
            FirmwareFilePath = info.path;
    }
    if (FirmwareFilePath == nil) {
        NSLog(@"No upgrade file found");
        return ;
    }
    
    NSLog(@"Start firmware upgrade.");
    self.alertFirmwareUpgrade = [UIAlertController alertControllerWithTitle:@"updating..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    self.upgradeProgress = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    [self.upgradeProgress setFrame:CGRectMake(15, 50, 235, 10)];
    self.upgradeProgress.progress = 0;
    [self.alertFirmwareUpgrade.view addSubview:self.upgradeProgress];
    
    if ([self.smart_device startFirmwareUpgrade:FirmwareFilePath] == false) {// 开始升级智能设备
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
        UIAlertController *alertUpgradeDone = [UIAlertController alertControllerWithTitle:@"Firmware upgrade success" message:@"Device will reboot" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertUpgradeDone addAction:actionOK];
        [self presentViewController:alertUpgradeDone animated:YES completion:nil]; // 提示升级完成窗口
    }
}

// 设备固件升级进度
- (void)smartDeviceUpgradeProgress:(float)progress {
    self.upgradeProgress.progress = progress;
    self.alertFirmwareUpgrade.title = [NSString stringWithFormat:@"updating... %u%%", (uint32_t)(progress * 100.0)];
}

// 智能设备数据更新
- (void)smartDeviceDataUpdate:(NSDictionary <NSString *, id>*)data; {
    
    NSIndexPath *index = nil;
    
    for (NSString *key in data) { // 遍历字典
        if ([key containsString:@"Handshake connection"]) { // 握手连接
            NSLog(@"Handshake connect success.");
            
        } else if ([key containsString:@"Firmware version"]) { // 固件版本
            NSArray *version_info = data[key];
            NSString *boot_version = version_info[0];
            NSString *app_version = version_info[1];
            NSLog(@"Smart device bootloader version: %@", boot_version);
            index = [self set_data_poinit:key value:app_version];
            
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
    }
}

// 智能设备状态已更新
- (void)smartDeviceDidUpdateState:(SmartDeviceState)state {
    switch (state)
    {
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
