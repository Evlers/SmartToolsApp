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
#import "Masonry.h"

@interface SelectDevice () <UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate, SmartDeviceDelegate>
{
    CGFloat cornerRadius; // cell圆角
    CGRect bounds; // cell尺寸
}

@property (nonatomic, strong) NSDictionary *productInfo;
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray<SmartDevice *> *smartDevice;
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) UILabel *placeholder;
@property (nonatomic, strong) NSArray<NSDictionary<NSString *, NSString *> *> *myDevice;

@end

@implementation SelectDevice

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.smartDevice = [NSMutableArray array]; // 创建智能设备数组
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()]; // 创建中心管理者
    
    // 初始化产品信息
    ProductInfo *product_info = [ProductInfo alloc];
    product_info.default_name = @"Smart Battery";
    product_info.image = nil;
    product_info.type = SmartDeviceProductTypeBattery;
    product_info.identity = @"11223344";
    self.productInfo = @{product_info.identity: product_info};
    
    // 装载已储存的设备
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.myDevice = [defaults valueForKey:@"MyDevice"];
    for (NSDictionary *dev in self.myDevice) {
        DeviceBaseInfo *baseInfo = [[DeviceBaseInfo alloc]init];
        baseInfo.product_info = self.productInfo[dev[@"pid"]];
        baseInfo.name = dev[@"name"];
        baseInfo.BLEUUID = dev[@"uuid"];
        SmartDevice *smartDevice = [[SmartDevice alloc]init]; // 创建智能设备
        smartDevice.baseInfo = baseInfo; // 复制设备基本信息
        [self.smartDevice addObject:smartDevice]; // 添加该设备到数组
    }
    
    // 配置导航栏信息
    UITabBarItem *tabBarItem = [[UITabBarItem alloc]initWithTitle:@"Home" image:nil tag:101];
    tabBarItem.image = [[UIImage imageNamed:@"home60x60"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    tabBarItem.selectedImage = tabBarItem.image;
    self.tabBarItem = tabBarItem;
    
    // 配置背景
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
//    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"背景"]];
//    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init]; // 初始化梯度图层
//    gradientLayer.colors = @[(__bridge id)[UIColor colorWithHexString:@"E9322D"].CGColor, // 设置梯度变化颜色数组
//                             (__bridge id)[UIColor colorWithWhite:0.95 alpha:1].CGColor,
//                             (__bridge id)[UIColor colorWithHexString:@"FF9040"].CGColor,
//                             (__bridge id)[UIColor colorWithWhite:0.9 alpha:1].CGColor,
//                             (__bridge id)[UIColor colorWithWhite:0.7 alpha:1].CGColor,
//                             (__bridge id)[UIColor colorWithWhite:0.7 alpha:1].CGColor,
//                             (__bridge id)[UIColor colorWithWhite:0.7 alpha:1].CGColor,
//                             (__bridge id)[UIColor colorWithWhite:0.7 alpha:1].CGColor,
//                             (__bridge id)[UIColor colorWithWhite:0.7 alpha:1].CGColor];
//    gradientLayer.startPoint = CGPointMake(0, 0); // 设置开始点
//    gradientLayer.endPoint = CGPointMake(1, 1); // 设置结束点
//    gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); // 设置图层大小
//    [self.view.layer addSublayer:gradientLayer]; // 添加涂层
    
    // 配置 TableView
    cornerRadius = 10.0; // 初始化cell的圆角半径
    self.table = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStyleGrouped];
    self.table.delegate = self;              // 设置代理
    self.table.dataSource = self;            // 设置数据源
    self.table.estimatedRowHeight = UITableViewAutomaticDimension;
    self.table.backgroundColor = [UIColor clearColor];
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone; // 每行之间无分割线
    [self.view addSubview:self.table];
    [self.table mas_makeConstraints:^(MASConstraintMaker * make) {
        make.edges.equalTo(self.view);
    }];
    
    // 配置下拉刷新的控件
    UIRefreshControl *RefreshControl = [[UIRefreshControl alloc]init];
    RefreshControl.backgroundColor = [UIColor clearColor];
    RefreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:@"Pull to refresh"];
    [RefreshControl addTarget:self action:@selector(DownPullUpdate:) forControlEvents:UIControlEventValueChanged];
    self.table.refreshControl = RefreshControl;
    
    // 配置TableView占位符
    if (self.myDevice.count == 0) {
        self.placeholder = [[UILabel alloc]init];
        self.placeholder.text = @"No device found";
        self.placeholder.numberOfLines = 3;
        self.placeholder.font = [UIFont  boldSystemFontOfSize:30.0];
        self.placeholder.textColor = [UIColor lightGrayColor];
        self.placeholder.textAlignment = NSTextAlignmentCenter;
        [self.table addSubview:self.placeholder];
        
        [self.placeholder mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.view.mas_centerX);
            make.centerY.equalTo(self.view.mas_centerY);
        }];
    }
}

// 下拉更新回调
-(void)DownPullUpdate:(UIRefreshControl *)refc {
    if (self.centralManager.state == CBManagerStatePoweredOn) {
        [self.centralManager stopScan]; // 停止扫描
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            
            while (self.smartDevice.count > self.myDevice.count) { // 删除所有搜索到的设备
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.smartDevice.count - self.myDevice.count - 1 inSection:self.myDevice.count];
                [self.smartDevice lastObject].delegate = nil;
                [[self.smartDevice lastObject] disconnectToDevice];
                [self.smartDevice removeObjectAtIndex:self.smartDevice.count-1]; // 删除一个设备
                [self.table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
                if ([self.smartDevice lastObject].baseInfo.BLEUUID != nil) break;
            }
            
            [refc endRefreshing]; // 停止更新
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                [self.centralManager scanForPeripheralsWithServices:nil options:nil]; // 搜索周围所有蓝牙设备
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{ // 1秒后如果没搜索到设备则显示占位符
                    if (self.smartDevice.count == 0 && self.myDevice.count == 0)
                        self.placeholder.hidden = false; // 显示占位符
                });
            });
        });
    }
    else {
       [refc endRefreshing];//停止更新
    }
}

// 将进入界面
- (void)viewWillAppear:(BOOL)animated {
    [self.table reloadData];
}

// 已经进入界面
-(void)viewDidAppear:(BOOL)animated {
    
    for (SmartDevice *smartDevice in self.smartDevice) {
        smartDevice.delegate = self; // 夺回设备的代理
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 连接按钮单击
- (void)connectButtonClicked:(UIButton *)btn {
    
    SmartDevice *smartDevice = [self.smartDevice objectAtIndex:btn.tag];
    if (smartDevice.baseInfo.BLEUUID && smartDevice.baseInfo.peripheral == nil) return ; // 已储存设备未搜索到广播不允许连接
    if (smartDevice.baseInfo.peripheral.state != CBPeripheralStateDisconnected) return;
    
    [self.smartDevice objectAtIndex:btn.tag].delegate = self; // 代理智能设备接口
    [[self.smartDevice objectAtIndex:btn.tag] connectToDevice]; // 连接到设备
}

#pragma mark -- TableView 接口

// Tableview接口: 返回组头数据
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == self.myDevice.count)
        return @"Nearby equipment";
    else if (section == 0)
        return @"MyDevice";
    return @" ";
}

// 返回组数量
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.smartDevice.count && self.placeholder != nil) {
        self.placeholder.hidden = true; // 隐藏占位符
    }
    if (self.myDevice.count == 0 && self.smartDevice.count == 0)
        return 1; // 至少有一个组 用于插入搜索到的设备
    return self.myDevice.count + (self.smartDevice.count ? 1 : 0);
}

// 组头高度
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 60;
    else if (section == self.myDevice.count) return 30;
    return 1;
}

// Tableview接口: 返回行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section >= self.myDevice.count) { // 附近设备
        return self.smartDevice.count - self.myDevice.count;
    } else { // 保存的设备组
        return 1;
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


// Tableview接口: 返回每行的数据
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DeviceBaseInfo *baseInfo = [self.smartDevice objectAtIndex:indexPath.section].baseInfo;
    
    switch (baseInfo.product_info.type)
    {
        case SmartDeviceProductTypeBattery: // 电池包设备
        {
            if (indexPath.section == self.myDevice.count) // 附近设备
            {
                DevParamUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"device base SystemCell"]; // 通过队列ID出列Cell
                if (cell == nil) {
                    cell = [[DevParamUITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SystemCell"];
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                
                DeviceBaseInfo *baseInfo = [self.smartDevice objectAtIndex:indexPath.section + indexPath.row].baseInfo;
                uint8_t *dev_id = baseInfo.manufacture_data->device_id;
                uint8_t capacity = baseInfo.manufacture_data->capacity_value * 0.5 + 1.5; // 计算电池容量
                
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %uAH", baseInfo.product_info.default_name, capacity];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"#%02X%02X", dev_id[0], dev_id[1]];
                return cell;
            }
            else // 已储存设备(我的设备)
            {
                DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceTableViewCell"]; // 通过队列ID出列Cell
                if (cell == nil) {
                    cell = [[DeviceTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DeviceTableViewCell"];
                }
                
                SmartBattery *battery = [self.smartDevice objectAtIndex:indexPath.section].battery;
                
                [cell setDeviceName:baseInfo.name state:baseInfo.state info:battery]; // 设置基本信息
                cell.connectBtn.tag = indexPath.section; // 记录按钮位置
                [cell.connectBtn addTarget:self action:@selector(connectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                UILongPressGestureRecognizer * longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellLongPress:)];
                [cell addGestureRecognizer:longPressGesture];
                return cell;
            }
        }
        
        default: return nil;
    }
}

// 长按"我的设备"
- (void)cellLongPress:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [recognizer locationInView:self.table]; // 获取点击的坐标
        NSIndexPath *indexPath = [self.table indexPathForRowAtPoint:location]; // 通过坐标获取选中的indexPath
        SmartDevice *smartDevice = [self.smartDevice objectAtIndex:indexPath.section]; // 获取选中的设备
        
        NSString *msg = [NSString stringWithFormat:@"Whether to delete the %@ device?", smartDevice.baseInfo.name];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete device" message:msg preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            // 断开需要删除的设备连接
            if (smartDevice.baseInfo.peripheral.state == CBPeripheralStateConnected) {
                smartDevice.delegate = nil; // 取消该设备的代理
                [smartDevice disconnectToDevice]; // 断开设备连接
                [self.centralManager stopScan]; // 停止蓝牙扫描
                [self.centralManager scanForPeripheralsWithServices:nil options:nil];// 设备断开后需要重新扫描才能在附近设备中显示
            }
            
            // 从"我的设备"中删除次设备
            NSDictionary *storeInfo = @{
                @"uuid" : smartDevice.baseInfo.BLEUUID,
                @"name" : smartDevice.baseInfo.name,
                @"pid" : smartDevice.baseInfo.product_info.identity
            };
            NSMutableArray *myDevice = [NSMutableArray arrayWithArray:self.myDevice]; // 先获取储存的数组到可变数组中
            [myDevice removeObject:storeInfo]; // 从可变数组中删除此设备
            self.myDevice = [myDevice copy]; // 复制新的储存信息
            
            // 保存"我的设备"数据信息
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:self.myDevice forKey:@"MyDevice"];
            [defaults synchronize]; // 立即同步写入
            
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[self.smartDevice indexOfObject:smartDevice]]; // 获取该设备在TableView中的位置
            [self.smartDevice removeObject:smartDevice]; // 从数组中删除设备
            [self.table deleteSections:indexSet withRowAnimation:UITableViewRowAnimationRight]; // 从Tableview移除该组
        }];
        [alert addAction:cancelAction];
        [alert addAction:yesAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// Tableview接口:选中设备
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index = (indexPath.section == self.myDevice.count) ? (self.myDevice.count + indexPath.row) : indexPath.section;
    SmartDevice *smartDevice = [self.smartDevice objectAtIndex:index];
    
    if (smartDevice.baseInfo.state == SmartDeviceBLEDisconnected) {
        
        if (smartDevice.baseInfo.BLEUUID == nil) // 未储存的设备
        {
            // 删除即将连接的附近设备
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.smartDevice indexOfObject:smartDevice] - self.myDevice.count inSection:self.myDevice.count];
            [self.smartDevice removeObject:smartDevice]; // 从附近设备中删除该设备
            [self.table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
            
            [self.centralManager stopScan]; // 停止蓝牙扫描
            // 等待附近设备删除动画完成后再插入新的绑定设备 并执行扫描连接
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 400 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                
                // 备份以及删除所有的附近设备
                NSMutableArray *backup = [NSMutableArray array];
                while(self.smartDevice.count > self.myDevice.count) {
                    [backup addObject:[self.smartDevice lastObject]]; // 备份
                    [self.smartDevice removeLastObject]; // 删除
                }
                
                // 储存该设备
                NSDictionary *storeInfo = @{ // 创建储存信息
                    @"uuid" : smartDevice.baseInfo.peripheral.identifier.UUIDString,
                    @"name" : smartDevice.baseInfo.name,
                    @"pid" : smartDevice.baseInfo.product_info.identity
                };
                smartDevice.baseInfo.BLEUUID = smartDevice.baseInfo.peripheral.identifier.UUIDString; // 转为已储存的设备
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if (self.myDevice == nil) {
                    self.myDevice = [NSArray arrayWithObject:storeInfo];
                } else {
                    self.myDevice = [self.myDevice arrayByAddingObject:storeInfo];
                }
                [defaults setObject:self.myDevice forKey:@"MyDevice"];
                [defaults synchronize]; // 强制储存
                
                // 装载刚刚储存的设备到数组中准备执行连接
                DeviceBaseInfo *baseInfo = [[DeviceBaseInfo alloc]init];
                baseInfo.product_info = self.productInfo[storeInfo[@"pid"]];
                baseInfo.name = storeInfo[@"name"];
                baseInfo.BLEUUID = storeInfo[@"uuid"];
                SmartDevice *smartDevice = [[SmartDevice alloc]init]; // 创建智能设备
                smartDevice.baseInfo = baseInfo; // 复制设备基本信息
                [self.smartDevice addObject:smartDevice]; // 添加该设备到数组
            
                // 恢复附近的设备
                while(backup.count) {
                    [self.smartDevice addObject:[backup lastObject]];
                    [backup removeLastObject];
                }
                
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[self.smartDevice indexOfObject:smartDevice]];
                [self.table insertSections:indexSet withRowAnimation:UITableViewRowAnimationLeft]; // 插入新的组
                [self.centralManager scanForPeripheralsWithServices:nil options:nil]; // 扫描新加入的设备广播后执行连接
            });
            
            return ; // 加入到"我的设备中不需要进入"详情页面"
        }
        else if (smartDevice.baseInfo.peripheral != nil)// 已储存设备需要搜索广播到才能执行连接
        {
            [smartDevice connectToDevice]; // 连接到设备
        }
        else return ; // 已储存设备 未搜索到广播不允许进入详情页面
    }
    
    // 进入详情页面
    SmartDeviceVC *device_view = [[SmartDeviceVC alloc]init];
    device_view.smartDevice = smartDevice; // 传递设备信息到设备窗口
    [self.navigationController pushViewController:device_view animated:YES]; // 跳转到设备窗口
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

- (void)smartDeviceInfoUpdate:(SmartDevice *)device {
    [UIView performWithoutAnimation:^{ // 无动画
        [self.table performBatchUpdates:^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:[self.smartDevice indexOfObject:device]];
            [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
        } completion:^(BOOL finished) {
            [UIView setAnimationsEnabled:YES];
        }];
    }];
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
    if(central.state == CBManagerStatePoweredOn) {
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
    
    // 设备默认名称
    uint8_t *dev_id = baseInfo.manufacture_data->device_id;
    uint8_t capacity = baseInfo.manufacture_data->capacity_value * 0.5 + 1.5; // 计算电池容量
    baseInfo.name = [NSString stringWithFormat:@"%@ %dAH #%02X%02X", baseInfo.product_info.default_name, capacity, dev_id[0], dev_id[1]];
    
    // 遍历数组中的蓝牙模型，更新原有的数据
    for (NSInteger i = 0; i < self.smartDevice.count; i++) {
        SmartDevice *smartDevice = self.smartDevice[i];
        CBPeripheral *tempPeripheral = smartDevice.baseInfo.peripheral;
        if (smartDevice.baseInfo.BLEUUID != nil) // 当前遍历的是储存设备
        {
            if ([self.smartDevice[i].baseInfo.BLEUUID isEqualToString:peripheral.identifier.UUIDString]) // 当前搜索到的设备是已储存的设备
            {
                if (smartDevice.baseInfo.peripheral == nil || smartDevice.baseInfo.peripheral.state != CBPeripheralStateConnected) // 刚搜索到已储存的设备 或者 未连接
                {
                    smartDevice.baseInfo.peripheral = [peripheral copy];
                    smartDevice.baseInfo.manufacture_data = malloc(sizeof(manufacture_data_t)); // 分配厂商数据内存
                    memcpy(smartDevice.baseInfo.manufacture_data, manufacturer_data.bytes, sizeof(manufacture_data_t));
                    smartDevice.delegate = self; // 代理智能设备接口
                    [smartDevice connectToDevice]; // 连接到设备
                }
                return ;
            }
        }
        else // 当前遍历的是非储存设备
        {
            if ([peripheral.identifier.UUIDString isEqualToString:tempPeripheral.identifier.UUIDString]) // 当前搜索到的设备已显示
            {
                [self.smartDevice objectAtIndex:i].baseInfo = baseInfo; // 更新设备基本信息
                [UIView performWithoutAnimation:^{ // 无动画
                    NSIndexPath *index = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:index] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
                }];
                return ;
            }
        }
    }
    
    SmartDevice *smartDevice = [[SmartDevice alloc]init]; // 创建智能设备
    smartDevice.baseInfo = baseInfo; // 复制设备基本信息
    [self.smartDevice addObject:smartDevice]; // 添加该设备到数组
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.smartDevice.count - self.myDevice.count - 1 inSection:self.myDevice.count];
    [self.table insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

@end
