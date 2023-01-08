//
//  SmartDevice.m
//  SmartTools
//
//  Created by Evler on 2022/12/27.
//

#import "SelectDevice.h"
#import "SmartProtocol.h"
#import "SmartDevice.h"
#import "FirmwareUpgrade.h"

#define DEFAULT_SERVIICE_UUID       @"FFF0"
#define DEFAULT_UPLOAD_UUID         @"FFF1"
#define DEFAULT_DOWNLOAD_UUID       @"FFF2"

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


@interface SmartDevice () <CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource, SmartProtocolDelegate>

@property (nonatomic, strong) UIAlertController *alert;     // 提示窗口
@property (nonatomic, strong) UITableView *table;           // 功能列表视图
@property (nonatomic, strong) NSMutableArray *send_queue;   // 数据发送队列
@property (nonatomic, strong) NSMutableArray *data_point;   // 数据点,嵌套可变数组,第一级为 Table 组
@property (nonatomic, strong) NSString *service_uuid;       // 服务 UUID
@property (nonatomic, strong) NSString *upload_uuid;        // 上报特征 UUID
@property (nonatomic, strong) NSString *download_uuid;      // 下发特征 UUID
@property (nonatomic, strong) CBCharacteristic *write_char; // 写入特征

@end

@implementation SmartDevice

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.smart_protocol = [[SmartProtocol alloc]init];
    self.smart_protocol.delegate = self;
    self.data_point = [NSMutableArray array];
    self.send_queue = [NSMutableArray array];
    
    self.table = [self.view viewWithTag:10];
    self.table.delegate = self;
    self.table.dataSource = self;
    
    NSLog(@"Smart device view init done");
}

// 即将进入视图
-(void)viewWillAppear:(BOOL)animated {
    
}

// 已经进入视图
-(void)viewDidAppear:(BOOL)animated {
    [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES]; // 取消选中
}

// 连接中
- (void)connecting {
    self.alert = [UIAlertController alertControllerWithTitle:@"Cconnecting" message:@"Connect device.." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:self.alert animated:NO completion:nil]; // 显示提示窗口
    
    if (self.device.manufacture_data->uuid_flag == 0x5A) { // 使用自定义UUID
        self.service_uuid = [NSString stringWithFormat:@"%04X", self.device.manufacture_data->server_uiud];
        self.upload_uuid = [NSString stringWithFormat:@"%04X", self.device.manufacture_data->upload_uuid];
        self.download_uuid = [NSString stringWithFormat:@"%04X", self.device.manufacture_data->download_uuid];
    } else { // 使用默认的UUID
        self.service_uuid = DEFAULT_SERVIICE_UUID;
        self.upload_uuid = DEFAULT_UPLOAD_UUID;
        self.download_uuid = DEFAULT_DOWNLOAD_UUID;
    }
    
    // 配置数据点列表
    [self.data_point removeAllObjects];
    [self.table reloadData];
    
    // device base info
    NSMutableArray *dev_base_info = [NSMutableArray array];
    [dev_base_info addObject:[[DataPoint alloc]initWithName:@"Firmware version" type:UITableViewCellAccessoryDisclosureIndicator]];
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

// 已连接
- (void)connected {
    self.alert.message = @"Discover srervices..";
    self.device.peripheral.delegate = self; // 设置代理
    [self.device.peripheral discoverServices:nil]; // 扫描服务
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

#pragma mark -- Smart battery package protocool interface

// 设备应答处理
- (void)SmartProtocolResponseHandler:(protocol_body_t *)body with_code:(uint8_t)code {
    
    uint8_t result = body->code & ~0x80; // 获取应答结果
    NSData *data = [NSData dataWithBytes:body->data length:body->len];
    NSLog(@"Device response seq: %d, code: %d, result: %d, data:%@", body->seq, code, result, data);
    
    if (result != 0) { // 应答错误
        if (code == SP_CODE_CONNECT)
            [self.smart_protocol send_connect]; // 尝试再次发送握手指令
        return ;
    }
    
    [self commandHandler:code body:body]; // 处理指令应答
}

//  设备上报处理
- (uint8_t)SmartProtocolUploadHandler:(protocol_body_t *)body response:(protocol_body_t *)rsp_body {
    
    NSData *data = [NSData dataWithBytes:body->data length:body->len];
    NSLog(@"Device upload seq: %d, code: %d, data:%@", body->seq, body->code, data);
    
    [self commandHandler:body->code body:body]; // 处理指令上报
    
    return 0;
}

- (void)commandHandler:(uint8_t) code body:(protocol_body_t *) body {

    NSString *value = nil;
    NSIndexPath *index = nil;
    
    switch (code)
    {
        case SP_CODE_CONNECT: // 握手连接
        {
            [self.smart_protocol send_get_command:SP_CODE_BAT_TEMP];            // 发送电池温度查询指令
            [self.smart_protocol send_get_command:SP_CODE_FIRMWARE_VER];        // 发送固件版本查询指令
            [self.smart_protocol send_get_command:SP_CODE_HARDWARE_VER];        // 发送硬件版本查询指令
            [self.smart_protocol send_get_command:SP_CODE_DEV_UUID];            // 发送设备UIUD查询指令
            [self.smart_protocol send_get_command:SP_CODE_PROTECT_VOLT];        // 发送电池保护电压查询指令
            [self.smart_protocol send_get_command:SP_CODE_MAX_DISCHARGE_CUR];   // 发送最大放电电流查询指令
            [self.smart_protocol send_get_command:SP_CODE_FUNCTION_SW];         // 发送功能开关状态查询指令
            [self.smart_protocol send_get_command:SP_CODE_WORK_MODE];           // 发送工作模式查询指令
            [self.smart_protocol send_get_command:SP_CODE_WORK_TIME];           // 发送工作时间查询指令
            [self.smart_protocol send_get_command:SP_CODE_CHARGE_TIMES];        // 发送充电次数查询指令
            [self.smart_protocol send_get_command:SP_CODE_DISCHARGE_TIMES];     // 发送放电次数查询指令
            [self.smart_protocol send_get_command:SP_CODE_CURRENT_CUR];         // 发送当前电流查询指令
            [self.smart_protocol send_get_command:SP_CODE_CURRENT_PER];         // 发送当前电量查询指令
            [self.smart_protocol send_get_command:SP_CODE_BATTERY_STATUS];      // 发送电池包状态查询指令
            [self dismissViewControllerAnimated:YES completion:nil]; // 退出提示框
        }
        break;
            
        case SP_CODE_FIRMWARE_VER: // 设备应答固件版本信息
           if (body->len == 6) {
               NSString *bootloader_version = [NSString stringWithFormat:@"v%d.%d.%d", body->data[0], body->data[1], body->data[2]];
               value = [NSString stringWithFormat:@"v%d.%d.%d", body->data[3], body->data[4], body->data[5]];
               index = [self set_data_poinit:@"Firmware version" value:value];
               NSLog(@"Bootloader version: %@", bootloader_version);
            }
        break;
            
        case SP_CODE_HARDWARE_VER: // 设备应答硬件版本信息
            if (body->len == 3) {
                value = [NSString stringWithFormat:@"v%d.%d.%d", body->data[0], body->data[1], body->data[2]];
                index = [self set_data_poinit:@"Hardware version" value:value];
            }
        break;
            
        case SP_CODE_DEV_UUID:
            if (body->len == 12) {
                value = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                                         body->data[0], body->data[1], body->data[2], body->data[3], body->data[4], body->data[5],
                                         body->data[6], body->data[7], body->data[8], body->data[9], body->data[10], body->data[11]];
                index = [self set_data_poinit:@"Device uuid" value:value];
            }
        break;
            
        case SP_CODE_BAT_TEMP:
            if (body->len == sizeof(int16_t)) {
                int16_t bat_temp = body->data[0] | (((uint16_t)body->data[1]) << 8);
                value = [NSString stringWithFormat:@"%0.1f°C", (float)bat_temp / 10.0];
                index = [self set_data_poinit:@"Battery temperature" value:value];
            }
        break;
            
        case SP_CODE_PROTECT_VOLT:
            if (body->len == sizeof(uint16_t)) {
                uint16_t volt = body->data[0] | (((uint16_t)body->data[1]) << 8);
                value = [NSString stringWithFormat:@"%0.2fV", (float)volt / 1000.0];
                index = [self set_data_poinit:@"Protection voltage" value:value];
            }
        break;
            
        case SP_CODE_MAX_DISCHARGE_CUR:
            if (body->len == sizeof(uint16_t)) {
                uint16_t cur = body->data[0] | (((uint16_t)body->data[1]) << 8);
                value = [NSString stringWithFormat:@"%uA", cur];
                index = [self set_data_poinit:@"Maximum discharge current" value:value];
            }
        break;
            
        case SP_CODE_FUNCTION_SW:
            if (body->len == sizeof(uint32_t)) {
                uint32_t sw = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                value = [NSString stringWithFormat:@"BM[%08X]", sw];
                index = [self set_data_poinit:@"Function switch" value:value];
            }
        break;
            
        case SP_CODE_BATTERY_STATUS:
            if (body->len == sizeof(uint32_t)) {
                uint32_t status = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                uint8_t io_sta = status & 0x00000003;
                switch (io_sta)
                {
                    case 0: value = [NSString stringWithFormat:@"Standby"]; break;
                    case 1: value = [NSString stringWithFormat:@"Charger"]; break;
                    case 2: value = [NSString stringWithFormat:@"Discharger"]; break;
                }
                index = [self set_data_poinit:@"Battery status" value:value];
            }
        break;
            
        case SP_CODE_WORK_MODE:
            if (body->len == sizeof(uint8_t)) {
                uint8_t mode = body->data[0];
                value = [NSString stringWithFormat:@"%d", mode];
                index = [self set_data_poinit:@"Work mode" value:value];
            }
        break;
            
        case SP_CODE_CHARGE_TIMES:
            if (body->len == sizeof(uint32_t)) {
                uint32_t times = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                value = [NSString stringWithFormat:@"%u", times];
                index = [self set_data_poinit:@"Charger times" value:value];
            }
        break;
            
        case SP_CODE_DISCHARGE_TIMES:
            if (body->len == sizeof(uint32_t)) {
                uint32_t times = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                value = [NSString stringWithFormat:@"%u", times];
                index = [self set_data_poinit:@"Discharger times" value:value];
            }
        break;
            
        case SP_CODE_WORK_TIME:
            if (body->len == sizeof(uint32_t)) {
                uint32_t time = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                value = [NSString stringWithFormat:@"%u hour", time];
                index = [self set_data_poinit:@"Work time" value:value];
            }
        break;
            
        case SP_CODE_CURRENT_CUR:
            if (body->len == sizeof(uint32_t)) {
                uint32_t cur = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                value = [NSString stringWithFormat:@"%0.2fA", (float)cur / 1000.0];
                index = [self set_data_poinit:@"Current current" value:value];
            }
        break;
            
        case SP_CODE_CURRENT_PER:
            if (body->len == sizeof(uint8_t)) {
                uint8_t percent = body->data[0];
                value = [NSString stringWithFormat:@"%d%%", percent];
                index = [self set_data_poinit:@"Battery percent" value:value];
            }
            break;
            
        default:
            NSLog(@"Unknown code: %d", code);
            return ;
        break;
    }
    
    if (index != nil) {
        [UIView performWithoutAnimation:^{ // 无动画
            [self.table reloadRowsAtIndexPaths:[NSArray arrayWithObject:index] withRowAnimation:UITableViewRowAnimationNone]; // 通知 TableView 刷新
        }];
    }
}

// 智能包协议数据帧下发接口
- (void)SmartProtocolDataSend:(NSData *)data {
    if (self.device.peripheral.canSendWriteWithoutResponse != true || self.send_queue.count != 0) { // BLE未就绪 或者 发送队列中还有数据未发送
        [self.send_queue addObject:data]; // 保存数据等待就绪后发送
    } else { // 蓝牙就绪且队列已发送完
        [self.device.peripheral writeValue:data forCharacteristic:self.write_char type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark -- BLE 接口

// 已经发现服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    self.alert.message = @"Discover characteristics..";
    for (CBService *service in peripheral.services) {
        NSLog(@"Server: %@", service);
        [peripheral discoverCharacteristics:nil forService:service];//扫描服务里面的特征
    }
}

// 发现特征
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if (service.UUID.UUIDString != self.service_uuid) return ;
    
    for (CBCharacteristic *Characteristic in service.characteristics) { // 遍历所有特征
        
        if (Characteristic.UUID.UUIDString == self.upload_uuid) { // 如果是上报的特征
            if (Characteristic.properties & CBCharacteristicPropertyNotify) { // 如果特征支持通知
                NSLog(@"Discover the upload characteristic, will enable the notify in the characteristic %@", Characteristic.UUID.UUIDString);
                [peripheral setNotifyValue:YES forCharacteristic:Characteristic]; // 打开通知功能
            } else { // 错误：上报的特征不支持通知功能
                NSLog(@"Upload Characteristic %@ no support notify", Characteristic.UUID.UUIDString);
            }
        }
        
        if (Characteristic.UUID.UUIDString == self.download_uuid) { // 如果是下发特征
            self.write_char = Characteristic; // 保存该特征 用于下发数据
        }
        
    }
}

// 发现特征描述
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"Discover the characteristic descriptors");
}

// 更新特征描述值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSLog(@"Update the value in the characteristic descriptor");
}

// 已经更新特征值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic.UUID.UUIDString == self.upload_uuid) {
        [self.smart_protocol receive_data_handle:characteristic.value]; // 处理协议数据
    }
}

// 已经更新通知状态
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"Did enable the notification state in the characteristic %@", characteristic.UUID.UUIDString);
    self.alert.message = @"Shaking..";
    
    NSData *aes_key_tail = [NSData dataWithBytes:self.device.manufacture_data->aes_key_tail length:8];
    [self.smart_protocol aes_tail_key_set:aes_key_tail]; // 设置AES(ECB)密钥
    [self.smart_protocol send_connect]; // 发送握手连接
}

// 写入无应答数据已完成
- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    if (self.send_queue.count) { // 队列中还有数据未发送
        NSData *send_data;
        send_data = [self.send_queue objectAtIndex:0]; // 获取一帧数据
        [self.device.peripheral writeValue:send_data forCharacteristic:self.write_char type:CBCharacteristicWriteWithoutResponse]; // 发送数据
        [self.send_queue removeObject:send_data]; // 删除已发送到数据
    }
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
    UITableViewCell *cell;
    DataPoint *data_point = [(NSMutableArray *)[self.data_point objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *identifier = [NSString stringWithFormat:@"cell %ld %ld",(long)indexPath.section,(long)indexPath.row]; // 生成队列ID
    cell = [tableView dequeueReusableCellWithIdentifier:identifier]; // 通过队列ID出列Cell
    
    if(cell == NULL) {// 没有创建过此Cell
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier]; // 创建新的Cell
        cell.accessoryType = data_point.accessoryType;
    }
    
    // 配置显示数据
    cell.textLabel.text = data_point.name;
    cell.detailTextLabel.text = (data_point.value == nil) ? @"" : data_point.value;
    return cell;
}

// 选中
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DataPoint *data_point = [(NSMutableArray *)[self.data_point objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSLog(@"Seletctd %@", data_point.name);
    if ([data_point.name containsString:@"Firmware version"]) {
        UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil]; // 获取XIB文件
        FirmwareUpgrade *view = [mainStory instantiateViewControllerWithIdentifier:@"UpgradeView"]; // 获取试图控制器
        [self.navigationController pushViewController:view animated:YES]; // 进入固件更新页面
        
    } else {
        [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES]; // 取消选中
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
