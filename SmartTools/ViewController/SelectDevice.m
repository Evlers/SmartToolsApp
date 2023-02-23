//
//  SelectDevice.m
//  SmartTools
//
//  Created by Evler on 2022/12/19.
//

#import "SelectDevice.h"
#import "SmartDevice.h"
#import "SmartProtocol.h"
#import "SmartDeviceVC.h"
#import "DeviceTableViewCell.h"

@interface SelectDevice () <UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, SmartDeviceDelegate>

@property (nonatomic, strong) dispatch_block_t connectFailedBlock;
@property (nonatomic, strong) NSDictionary *productInfo;
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray<SmartDevice *> *smartDevice;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UILabel *placeholder;

@property (nonatomic, strong) SmartDeviceVC *device_view;

@end

@implementation SelectDevice

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化产品信息
    ProductInfo *product_info = [ProductInfo alloc];
    product_info.default_name = @"Smart Battery package";
    product_info.image = nil;
    product_info.type = SmartDeviceProductTypeBattery;
    self.productInfo = @{@"11223344": product_info};
    
//    NSLog(@"productInfo: %@", self.productInfo);
    
    // 配置 TableView
    self.table = [self.view viewWithTag:1];  // 根据 TAG ID 获取到主页面的 TableView 控件
    [self.table registerNib:[UINib nibWithNibName:@"DeviceTableViewCell" bundle:nil] forCellReuseIdentifier:@"DeviceTableViewCell"];
    self.table.delegate = self;              // 设置代理
    self.table.dataSource = self;            // 设置数据源
    self.table.rowHeight = 100;              // 设置每行高度
//    self.table.estimatedRowHeight = 128;     // 预估高度
//    self.table.rowHeight = UITableViewAutomaticDimension; // 自动计算高度
    
    // 配置TableView占位符
    self.placeholder = [[UILabel alloc]initWithFrame:CGRectMake(20, self.table.frame.size.height / 2 - 60, self.table.frame.size.width - 40, 60)];
    self.placeholder.text = @"No device found";
    self.placeholder.numberOfLines = 3;
    self.placeholder.font = [UIFont  boldSystemFontOfSize:30.0];
    self.placeholder.textColor = [UIColor lightGrayColor];
    self.placeholder.textAlignment = NSTextAlignmentCenter;
    [self.table addSubview:self.placeholder];
    
    self.smartDevice = [NSMutableArray array];
    
    // 配置下拉刷新的控件
    UIRefreshControl *RefreshControl = [[UIRefreshControl alloc]init];
    RefreshControl.backgroundColor = [UIColor grayColor];
    RefreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:@"下拉刷新"];
    [RefreshControl addTarget:self action:@selector(DownPullUpdate:) forControlEvents:UIControlEventValueChanged];
    self.table.refreshControl = RefreshControl;
    
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()]; // 创建中心管理者
    
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil]; // 获取XIB文件
    self.device_view = [mainStory instantiateViewControllerWithIdentifier:@"DeviceView"]; // 获取试图控制器
}

// 下拉更新回调
-(void)DownPullUpdate:(UIRefreshControl *)refc {
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        [self.centralManager stopScan]; // 停止扫描
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            while (self.smartDevice.count) { // 删除所有搜索到的设备
                NSIndexPath *IndexPath = [NSIndexPath indexPathForRow:self.smartDevice.count-1 inSection:0]; // 设定行数
                if ([self.smartDevice lastObject].baseInfo.peripheral.state == CBPeripheralStateConnected) {
                    [self.centralManager cancelPeripheralConnection:[self.smartDevice lastObject].baseInfo.peripheral]; // 断开连接
                }
                [self.smartDevice removeObjectAtIndex:self.smartDevice.count-1]; // 删除一个设备
                [self.table deleteRowsAtIndexPaths:[NSArray arrayWithObject:IndexPath] withRowAnimation:UITableViewRowAnimationRight];//动画删除设备
            }
            
            [refc endRefreshing];//停止更新
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                [self.centralManager scanForPeripheralsWithServices:nil options:nil]; // 搜索周围所有蓝牙设备
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{ // 1秒后如果没搜索到设备则显示占位符
                    if (self.smartDevice.count == 0)
                        [self.table addSubview:self.placeholder];
                });
            });
        });
    }
    else {
       [refc endRefreshing];//停止更新
    }
}

// 已经进入界面
-(void)viewDidAppear:(BOOL)animated {
    
    for (SmartDevice *smartDevice in self.smartDevice) {
        smartDevice.delegate = self; // 夺回设备的代理
        if (smartDevice.baseInfo.peripheral.state == CBPeripheralStateConnected) { // 如果已连接的设备
            [smartDevice getBattreyBaseInfo]; // 获取电池包基本信息(刷新卡片中的信息)
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 连接按钮单击
- (void)connectButtonClicked:(UIButton *)btn {
    
    if ([self.smartDevice objectAtIndex:btn.tag].baseInfo.peripheral.state == CBPeripheralStateConnected) return;
    
    [btn setTitle:@"Connecting.." forState:UIControlStateNormal];
    [self.smartDevice objectAtIndex:btn.tag].delegate = self; // 代理智能设备接口
    [self.centralManager connectPeripheral:[self.smartDevice objectAtIndex:btn.tag].baseInfo.peripheral options:nil]; // 连接设备蓝牙
}

#pragma mark -- TableView 接口

// Tableview接口: 返回组头数据
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    return @"Nearby equipment";
    return nil;
}

// Tableview接口: 返回行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.smartDevice.count) {
        [self.placeholder removeFromSuperview]; // 移除占位符
    }
    return self.smartDevice.count;
}

// Tableview接口: 返回每行的数据
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceTableViewCell"]; // 通过队列ID出列Cell
    DeviceBaseInfo *baseInfo = [self.smartDevice objectAtIndex:indexPath.row].baseInfo;
    SmartBattery *battery = [self.smartDevice objectAtIndex:indexPath.row].battery;
    
    uint8_t *dev_id = baseInfo.manufacture_data->device_id;
    uint8_t capacity = baseInfo.manufacture_data->capacity_value * 0.5 + 1.5; // 计算电池容量
    NSString *dev_name = [NSString stringWithFormat:@"%@ %dAH #%02X%02X", baseInfo.product_info.default_name, capacity, dev_id[0], dev_id[1]];

    cell.deviceName.text = dev_name;
//    cell.deviceImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"BatPack%d.0", capacity]];
    
    if (baseInfo.state == SmartDeviceConnectSuccess)
    {
        cell.connectBtn.hidden = true;
        cell.tempIcon.hidden = cell.percentIcon.hidden = cell.statusIcon.hidden = false;
        cell.bleImage.image = [UIImage imageNamed:@"蓝牙已连接"];
        if (battery.temperature)
            cell.tempValue.text = battery.temperature;
        if (battery.percent)
            cell.percentValue.text = battery.percent;
        if (battery.state) {
            cell.statusDescribe.text = battery.state;
            if ([battery.state isEqualToString:@"Standby"]) {
                cell.statusIcon.image = [UIImage imageNamed:@"待机中"];
                cell.statusDescribe.textColor = [UIColor colorWithHexString:@"FF9040"];
            } else if ([battery.state isEqualToString:@"Charging"]) {
                cell.statusIcon.image = [UIImage imageNamed:@"充电中"];
                cell.statusDescribe.textColor = [UIColor colorWithHexString:@"6BD7B0"];
            } else if([battery.state isEqualToString:@"Discharging"]) {
                cell.statusIcon.image = [UIImage imageNamed:@"放电中"];
                cell.statusDescribe.textColor = [UIColor colorWithHexString:@"3E95D5"];
            }
        }
    }
    else
    {
        cell.connectBtn.hidden = false;
        cell.tempValue.text = cell.percentValue.text = cell.statusDescribe.text = @"";
        cell.tempIcon.hidden = cell.percentIcon.hidden = cell.statusIcon.hidden = true;
        cell.bleImage.image = [UIImage imageNamed:@"蓝牙已断开"];
        if (baseInfo.state == SmartDeviceBLEConnected)
            [cell.connectBtn setTitle:@"Discover srervices.." forState:UIControlStateNormal];
        else if (baseInfo.state == SmartDeviceBLEDiscoverServer)
            [cell.connectBtn setTitle:@"Discover characteristics.." forState:UIControlStateNormal];
        else if (baseInfo.state == SmartDeviceBLEDiscoverCharacteristic)
            [cell.connectBtn setTitle:@"Enable nootify.." forState:UIControlStateNormal];
        else if (baseInfo.state == SmartDeviceBLENotifyEnable)
            [cell.connectBtn setTitle:@"Shaking.." forState:UIControlStateNormal];
        else
            [cell.connectBtn setTitle:@"Connect device" forState:UIControlStateNormal];
        cell.connectBtn.layer.cornerRadius = 10.0; // 设置圆角的弧度
        cell.connectBtn.layer.borderWidth = 1.0f; // 边宽
        cell.connectBtn.layer.borderColor = [UIColor colorWithHexString:@"FF9040"].CGColor;
        cell.connectBtn.backgroundColor = [UIColor colorWithHexString:@"FF9040" alpha:0.1];
        cell.connectBtn.tag = indexPath.row; // 记录按钮位置
        [cell.connectBtn addTarget:self action:@selector(connectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return cell;
}

// Tableview接口:选中设备
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SmartDevice *smartDevice = [self.smartDevice objectAtIndex:indexPath.row];
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil]; // 获取XIB文件
    self.device_view = [mainStory instantiateViewControllerWithIdentifier:@"DeviceView"]; // 获取试图控制器
    self.device_view.smartDevice = [self.smartDevice objectAtIndex:indexPath.row]; // 传递设备信息到设备窗口
    if (smartDevice.baseInfo.peripheral.state != CBPeripheralStateConnected)
        [self.centralManager connectPeripheral:smartDevice.baseInfo.peripheral options:nil]; // 连接设备蓝牙
    [self.navigationController pushViewController:self.device_view animated:YES]; // 跳转到设备窗口
}

#pragma mark -- Smart device interface

- (void)smartDeviceInfoUpdate:(SmartDevice *)device {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.smartDevice indexOfObject:device] inSection:0];
    [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
}

// 智能设备数据更新
- (void)smartDevice:(SmartDevice *)device dataUpdate:(NSDictionary <NSString *, id>*)data; {
    [self smartDeviceInfoUpdate: device];
}

// 智能设备状态已更新
- (void)smartDevice:(SmartDevice *)device didUpdateState:(SmartDeviceState)state {
    [self smartDeviceInfoUpdate: device];
}

#pragma mark -- BLE 接口

// 控制器改变状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if(central.state == CBManagerStatePoweredOn){
        NSLog(@"BlueTooth is startup");
        [self.centralManager scanForPeripheralsWithServices:nil options:nil]; // 搜索周围所有蓝牙设备
        [self.indicatorView startAnimating]; // 开始旋转动画 提示正在扫描中
    }
}

// 搜索到设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSString *dev_name = advertisementData[@"kCBAdvDataLocalName"]; // 获取广播数据中的蓝牙名称
    NSData *manufacturer_data = advertisementData[@"kCBAdvDataManufacturerData"]; // 获取厂商自定义数据
    
    if(dev_name == nil || ![dev_name isEqual:@"LGT"]) return ; // 只显示LGT设备
    if(manufacturer_data == nil || manufacturer_data.length != sizeof(manufacture_data_t)) return ; // 未搜索到厂商数据的设备也过滤掉
    
    DeviceBaseInfo *baseInfo = [[DeviceBaseInfo alloc]init]; // 创建新的设备类
    baseInfo.peripheral = [peripheral copy]; // 复制BLE外设
    baseInfo.manufacture_data = malloc(sizeof(manufacture_data_t)); // 分配厂商数据内存
    memcpy(baseInfo.manufacture_data, manufacturer_data.bytes, sizeof(manufacture_data_t));
    
    // 获取产品信息
    uint8_t *pid = baseInfo.manufacture_data->product_id;
    NSString *product_id = [NSString stringWithFormat:@"%02X%02X%02X%02X", pid[0], pid[1], pid[2], pid[3]];
    baseInfo.product_info = self.productInfo[product_id];
    
    // 遍历数组中的蓝牙模型，更新原有的数据
    for (NSInteger i = 0; i < self.smartDevice.count; i++) {
        CBPeripheral *tempPeripheral = self.smartDevice[i].baseInfo.peripheral;
        if ([peripheral.identifier.UUIDString isEqualToString:tempPeripheral.identifier.UUIDString]) {
            [self.smartDevice objectAtIndex:i].baseInfo = baseInfo; // 更新设备基本信息
//            [self.smartDevice replaceObjectAtIndex:i withObject:device];//更新数组中的数据
            [UIView performWithoutAnimation:^{ // 无动画
                NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
                [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:index] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
            }];
            return ;
        }
    }
    
    for (NSInteger i = 0; i < self.smartDevice.count; i ++) {
        CBPeripheral *tempPeripheral = self.smartDevice[i].baseInfo.peripheral;
        if ([peripheral.identifier.UUIDString isEqualToString:tempPeripheral.identifier.UUIDString]) {
            return ; // 已经添加过此设备 无需再次添加
        }
    }
    
    SmartDevice *smartDevice = [[SmartDevice alloc]init]; // 创建智能设备
    smartDevice.baseInfo = baseInfo; // 复制设备基本信息
    [self.smartDevice addObject:smartDevice]; // 添加该设备到数组
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[self.smartDevice indexOfObject:smartDevice] inSection:0];
    [self.table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationLeft];//插入Cell
    
//    if(![self.device containsObject:device]) // 没有添加过的设备
//    {
//        [self.device addObject:device]; // 添加该设备到数组
//        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[self.device indexOfObject:device] inSection:0];
//        [self.table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationLeft];//插入Cell
//    }
}

// 已经连接设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    for (SmartDevice *smartDevice in self.smartDevice) {
        if ([smartDevice.baseInfo.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            [smartDevice BLEConnected]; // 已连接到设备蓝牙，开始连接设备协议
        }
    }
    
    NSLog(@"Connected to %@", peripheral.name);
}

// 断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    for (SmartDevice *smartDevice in self.smartDevice) {
        if ([smartDevice.baseInfo.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            [self smartDeviceInfoUpdate: smartDevice];
            [smartDevice BLEdisconnected];
        }
    }
    NSLog(@"Disconnect is %@", peripheral.name);
}

@end
