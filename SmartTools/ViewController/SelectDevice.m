//
//  SelectDevice.m
//  SmartTools
//
//  Created by Evler on 2022/12/19.
//

#import "SelectDevice.h"
#import "SmartProtocol.h"
#import "SmartDevice.h"

@implementation ProductInfo

@end

@implementation Device

@end

@interface SelectDevice () <UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate>

@property (nonatomic, strong) dispatch_block_t connectFailedBlock;
@property (nonatomic, strong) NSDictionary *productInfo;
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray<Device *> *device;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, strong) SmartDevice *device_view;

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
    self.productInfo = @{@"11223344": product_info};
    
    NSLog(@"productInfo: %@", self.productInfo);
    
    // 配置 TableView
    self.table = [self.view viewWithTag:1];  // 根据 TAG ID 获取到主页面的 TableView 控件
    self.table.delegate = self;              // 设置代理
    self.table.dataSource = self;            // 设置数据源
    
    // 配置扫描动画
    self.indicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.indicatorView.center = CGPointMake(90, 35);
    [self.table addSubview:self.indicatorView];
    
    self.device = [NSMutableArray array]; // 创建用于储存设备的可变数组
    
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
    if(self.centralManager.state == CBManagerStatePoweredOn){
        [self.centralManager stopScan];//停止扫描
        [self.indicatorView stopAnimating];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            while (self.device.count) {//删除所有搜索到的设备
                NSIndexPath *IndexPath = [NSIndexPath indexPathForRow:self.device.count-1 inSection:0];//设定行数
                [self.device removeObjectAtIndex:self.device.count-1];//删除一个设备
                [self.table deleteRowsAtIndexPaths:[NSArray arrayWithObject:IndexPath] withRowAnimation:UITableViewRowAnimationRight];//动画删除设备
            }
            
            [refc endRefreshing];//停止更新
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                [self.centralManager scanForPeripheralsWithServices:nil options:nil]; // 搜索周围所有蓝牙设备
                [self.indicatorView startAnimating];
            });
        });
    }
    else {
       [refc endRefreshing];//停止更新
    }
}

// 已经进入界面
-(void)viewDidAppear:(BOOL)animated {
    if (self.device.count && [self.device objectAtIndex:self.table.indexPathForSelectedRow.row].peripheral.state == CBPeripheralStateConnected) {//若果设备已经连接
        [self.centralManager cancelPeripheralConnection:[self.device objectAtIndex:self.table.indexPathForSelectedRow.row].peripheral];//断开连接
    }
}

#pragma mark -- TableView 接口

// Tableview接口: 返回组头数据
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"选择设备..";
}

// Tableview接口: 返回行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.device.count;
}

// Tableview接口: 返回每行的数据
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    NSString *identifier = [NSString stringWithFormat:@"cell %ld %ld",(long)indexPath.section,(long)indexPath.row]; // 生成队列ID
    cell = [tableView dequeueReusableCellWithIdentifier:identifier]; // 通过队列ID出列Cell
    
    if(cell == NULL) // 没有创建过此Cell
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier]; // 创建新的Cell
    
    // 组合设备名
    uint8_t *dev_id = [self.device objectAtIndex:indexPath.row].manufacture_data->device_id;
    NSString *dev_name = [NSString stringWithFormat:@"%@ #%02X%02X",
                          [self.device objectAtIndex:indexPath.row].product_info.default_name, dev_id[0], dev_id[1]];
    
    // 配置显示数据
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // 右侧有箭头的行
    cell.textLabel.text = dev_name;
    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"smartBatteryPackage"]];
    cell.detailTextLabel.text = [self.device objectAtIndex:indexPath.row].peripheral.identifier.UUIDString;
    return cell;
}

// Tableview接口:选中设备
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.centralManager connectPeripheral:[self.device objectAtIndex:indexPath.row].peripheral options:nil]; // 连接设备
    
    self.device_view.device = [self.device objectAtIndex:indexPath.row]; // 传递设备信息到设备窗口
    
    self.connectFailedBlock = dispatch_block_create(DISPATCH_BLOCK_BARRIER , ^{ // 创建超时处理的定时任务
        if([self.device objectAtIndex:indexPath.row].peripheral.state != CBPeripheralStateConnected){ // 如果没有连接
            [self.centralManager cancelPeripheralConnection:[self.device objectAtIndex:indexPath.row].peripheral]; // 取消连接
            [self.table deselectRowAtIndexPath:indexPath animated:YES]; // 取消选中
        }
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), self.connectFailedBlock); // 5秒后进入超时处理
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    Device *device = [Device alloc]; // 创建新的设备类
    device.peripheral = [peripheral copy]; // 复制BLE外设
    device.manufacture_data = malloc(sizeof(manufacture_data_t)); // 分配厂商数据内存
    memcpy(device.manufacture_data, manufacturer_data.bytes, sizeof(manufacture_data_t));
    
    // 获取产品信息
    uint8_t *pid = device.manufacture_data->product_id;
    NSString *product_id = [NSString stringWithFormat:@"%02X%02X%02X%02X", pid[0], pid[1], pid[2], pid[3]];
    device.product_info = self.productInfo[product_id];
    
    // 遍历数组中的蓝牙模型，更新原有的数据
    for (NSInteger i = 0; i < self.device.count; i++) {
        CBPeripheral *tempPeripheral = self.device[i].peripheral;
        if ([peripheral.identifier.UUIDString isEqualToString:tempPeripheral.identifier.UUIDString]) {
            [self.device replaceObjectAtIndex:i withObject:device];//更新数组中的数据
            break;
        }
    }
    
    if(![self.device containsObject:device]) // 没有添加过的设备
        [self.device addObject:device]; // 添加该设备到数组
    
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[self.device indexOfObject:device] inSection:0];
    [self.table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationLeft];//插入Cell
}

// 连接失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES];//取消选中
    dispatch_block_cancel(self.connectFailedBlock); // 取消超时任务
    NSLog(@"Connect to %@ failed", error);
}

// 断开连接
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES];//取消选中
    [self.navigationController popViewControllerAnimated:YES]; // 返回上一个窗口
    dispatch_block_cancel(self.connectFailedBlock); // 取消超时任务
    NSLog(@"Disconnect is %@", peripheral.name);
}

// 已经连接设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self.navigationController pushViewController:self.device_view animated:YES]; // 跳转到设备窗口
    dispatch_block_cancel(self.connectFailedBlock); // 取消超时任务
    NSLog(@"Connected to %@", peripheral.name);
}

@end
