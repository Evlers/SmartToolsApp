//
//  SmartDevice.m
//  SmartTools
//
//  Created by Evler on 2023/1/10.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCrypto.h>
#import <zlib.h>
#import "SmartProtocol.h"
#import "SmartDevice.h"
#import "Utility.h"
#import "FirmwareFile.h"

#define DEFAULT_SERVIICE_UUID       @"FFF0"
#define DEFAULT_UPLOAD_UUID         @"FFF1"
#define DEFAULT_DOWNLOAD_UUID       @"FFF2"


@implementation ProductInfo

@end

@implementation SmartBattery

@end

@implementation DeviceBaseInfo

@end

@implementation FirmwareUpgrade

@end


@interface SmartDevice () <CBCentralManagerDelegate, CBPeripheralDelegate, SmartProtocolDelegate>

@property (nonatomic, strong) dispatch_block_t  conTimeoutBlock;    // 设备连接超时执行块
@property (nonatomic, strong) NSString          *service_uuid;      // 服务 UUID
@property (nonatomic, strong) NSString          *upload_uuid;       // 上报特征 UUID
@property (nonatomic, strong) NSString          *download_uuid;     // 下发特征 UUID
@property (nonatomic, strong) CBCharacteristic  *write_char;        // 写入特征
@property (nonatomic, strong) NSMutableArray    *send_queue;        // BLE数据发送队列
@property (nonatomic, strong) SmartProtocol     *smart_protocol;    // 智能包协议
@property (nonatomic, strong) FirmwareUpgrade   *firmwareUpgrade;   // 固件更新
@property (nonatomic, strong) CBCentralManager  *centralManager;    // 中心管理器

@end

@implementation SmartDevice

- (SmartDevice *)init {
    self.smart_protocol = [[SmartProtocol alloc]init];
    self.smart_protocol.delegate = self;
    self.send_queue = [NSMutableArray array];
    if (self.baseInfo.product_info.type == SmartDeviceProductTypeBattery) // 电池包产品
        self.battery = [SmartBattery alloc]; // 创建电池包信息
    return self;
}

// 连接到设备
- (void)connectToDevice {
    
    [self updateDeviceState:SmartDeviceBLEConnecting];
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()]; // 创建中心管理者
    
    // 创建超时任务，在指定时间内需要完成设备的握手连接
    self.conTimeoutBlock = dispatch_block_create(DISPATCH_BLOCK_BARRIER , ^{ // 创建超时连接的定时任务块
        [self updateDeviceState:SmartDeviceConnectTimeout];
        [self.centralManager cancelPeripheralConnection:self.baseInfo.peripheral]; // 取消连接
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), self.conTimeoutBlock); // 10秒后进入超时处理
}

// 断开与设备连接
- (void)disconnectToDevice {
    
    if (self.baseInfo.peripheral.state == CBPeripheralStateConnected) {
        dispatch_block_cancel(self.conTimeoutBlock); // 取消超时任务
        [self.centralManager cancelPeripheralConnection:self.baseInfo.peripheral]; // 取消设备连接
    }
}

// 开始固件更新
- (bool)startFirmwareUpgrade:(NSString *)filePath {

    if (filePath == nil || ![filePath hasSuffix:@".zip"]) return false;
    
    self.firmwareUpgrade = [FirmwareUpgrade alloc];
    if ((self.firmwareUpgrade.firmware = [[Firmware alloc]initWithLoadFirmware:filePath]) == nil) {
        NSLog(@"Firmware file %@ analysis error !", filePath);
        return false;
    }
    
    [self sendUpgradeRequest]; // 发送升级请求
    
    return true;
}

// 发送升级请求
- (void)sendUpgradeRequest {
    ota_upgrade_request_t ota_upgrade_request;
    protocol_body_t body;
    
    ota_upgrade_request.type = ((FirmwareFile *)[self.firmwareUpgrade.firmware.bin_file objectAtIndex:0]).type;
    ota_upgrade_request.length = BODY_DATA_MAX_LEN;
    
    body.len = sizeof(ota_upgrade_request_t);
    body.data = malloc(body.len);
    body.code = SP_CODE_UPGRADE_REQUEST;
    memcpy(body.data, &ota_upgrade_request, sizeof(ota_upgrade_request));
    
    [self.smart_protocol send_frame_with_fcb:FCB_DEFAULT body:&body]; // 发送升级请求
    free(body.data);
}

// 查询设备所有数据
- (void)getDeviceAllData {
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
}

// 查询设备基本信息
- (void)getDeviceBaseInfo {
    [self.smart_protocol send_get_command:SP_CODE_FIRMWARE_VER];        // 发送固件版本查询指令
    [self.smart_protocol send_get_command:SP_CODE_HARDWARE_VER];        // 发送硬件版本查询指令
    [self.smart_protocol send_get_command:SP_CODE_DEV_UUID];            // 发送设备UIUD查询指令
}

// 查询电池包基本信息
- (void)getBattreyBaseInfo {
    [self.smart_protocol send_get_command:SP_CODE_BATTERY_STATUS];      // 发送电池包状态查询指令
    [self.smart_protocol send_get_command:SP_CODE_BAT_TEMP];            // 发送电池温度查询指令
    [self.smart_protocol send_get_command:SP_CODE_CURRENT_PER];         // 发送当前电量查询指令
}

// 更新设备状态
- (void)updateDeviceState:(SmartDeviceState)state {
    self.baseInfo.state = state;
    if (self.delegate && [self.delegate respondsToSelector:@selector(smartDevice:didUpdateState:)])
        [self.delegate smartDevice:self didUpdateState:self.baseInfo.state];
}

#pragma mark -- Smart battery package protocool interface

// 设备应答处理
- (void)SmartProtocolResponseHandler:(protocol_body_t *)body with_code:(uint8_t)code {
    
    uint8_t result = body->code & ~0x80; // 获取应答结果
//    NSData *data = [NSData dataWithBytes:body->data length:body->len];
//    NSLog(@"Device response seq: %d, code: %d, result: %d, data:%@", body->seq, code, result, data);
    
    if (code == SP_CODE_CONNECT && result != 0) {
        [self.smart_protocol send_connect]; // 尝试再次发送握手指令
        return ;
        
    } else if (code >= SP_CODE_UPGRADE_REQUEST && code <= SP_CODE_UPGRADE_END) { // OTA数据
        [self firmwareUpgradeResponseHandler:body withCode:code];
        
    } else { // 其他数据
        [self commandHandler:code body:body]; // 处理其他指令应答
    }
}

//  设备上报处理
- (uint8_t)SmartProtocolUploadHandler:(protocol_body_t *)body response:(protocol_body_t *)rsp_body {
    
//    NSData *data = [NSData dataWithBytes:body->data length:body->len];
//    NSLog(@"Device upload seq: %d, code: %d, data:%@", body->seq, body->code, data);
    
    [self commandHandler:body->code body:body]; // 处理指令上报
    
    return 0;
}

// 设备指令处理
- (void)commandHandler:(uint8_t) code body:(protocol_body_t *) body {
    
    if (self.delegate == nil || [self.delegate respondsToSelector:@selector(smartDevice:dataUpdate:)] == false) {
        return ;
    }
    
    switch (code)
    {
        case SP_CODE_CONNECT: // 握手连接
            dispatch_block_cancel(self.conTimeoutBlock); // 取消超时任务
            [self.delegate smartDevice:self dataUpdate:@{@"Handshake connection": self.baseInfo}];
            [self updateDeviceState:SmartDeviceConnectSuccess];
            [self getDeviceAllData];// 查询设备所有参数
            break;
            
        case SP_CODE_FIRMWARE_VER: // 设备应答固件版本信息
           if (body->len == 6) {
               self.baseInfo.boot_firmware_version = [NSString stringWithFormat:@"v%d.%d.%d", body->data[0], body->data[1], body->data[2]];
               self.baseInfo.app_firmware_version = [NSString stringWithFormat:@"v%d.%d.%d", body->data[3], body->data[4], body->data[5]];
               NSArray *version_info = [[NSArray alloc]initWithObjects:self.baseInfo.boot_firmware_version, self.baseInfo.app_firmware_version, nil];
               [self.delegate smartDevice:self dataUpdate:@{@"Firmware version" : version_info}];
            }
            break;
            
        case SP_CODE_HARDWARE_VER: // 设备应答硬件版本信息
            if (body->len == 3) {
                self.baseInfo.hardware_version = [NSString stringWithFormat:@"v%d.%d.%d", body->data[0], body->data[1], body->data[2]];
                [self.delegate smartDevice:self dataUpdate:@{@"Hardware version" : self.baseInfo.hardware_version}];
            }
            break;
            
        case SP_CODE_DEV_UUID:
            if (body->len == 12) {
                self.baseInfo.uuid = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                                         body->data[0], body->data[1], body->data[2], body->data[3], body->data[4], body->data[5],
                                         body->data[6], body->data[7], body->data[8], body->data[9], body->data[10], body->data[11]];
                [self.delegate smartDevice:self dataUpdate:@{@"Device uuid" : self.baseInfo.uuid}];
            }
            break;
            
        case SP_CODE_BAT_TEMP:
            if (body->len == sizeof(int16_t)) {
                int16_t bat_temp = body->data[0] | (((uint16_t)body->data[1]) << 8);
                self.battery.temperature = [NSString stringWithFormat:@"%d°C", (int)((float)bat_temp / 10.0)];
                [self.delegate smartDevice:self dataUpdate:@{@"Battery temperature" : self.battery.temperature}];
            }
            break;
            
        case SP_CODE_PROTECT_VOLT:
            if (body->len == sizeof(uint16_t)) {
                uint16_t volt = body->data[0] | (((uint16_t)body->data[1]) << 8);
                NSString *voltage = [NSString stringWithFormat:@"%0.2fV", (float)volt / 1000.0];
                [self.delegate smartDevice:self dataUpdate:@{@"Protection voltage" : voltage}];
            }
            break;
            
        case SP_CODE_MAX_DISCHARGE_CUR:
            if (body->len == sizeof(uint16_t)) {
                uint16_t cur = body->data[0] | (((uint16_t)body->data[1]) << 8);
                NSString *current = [NSString stringWithFormat:@"%uA", cur];
                [self.delegate smartDevice:self dataUpdate:@{@"Maximum discharge current" : current}];
            }
            break;
            
        case SP_CODE_FUNCTION_SW:
            if (body->len == sizeof(uint32_t)) {
                uint32_t sw = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                NSString *fun_sw = [NSString stringWithFormat:@"BM[%08X]", sw];
                [self.delegate smartDevice:self dataUpdate:@{@"Function switch" : fun_sw}];
            }
            break;
            
        case SP_CODE_BATTERY_STATUS:
            if (body->len == sizeof(uint32_t)) {
                uint32_t status = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                uint8_t bat_io_sta = status & 0x00000007; // Bit0 ~ 2
                switch (bat_io_sta)
                {
                    case 0: self.battery.state = [NSString stringWithFormat:@"Standby"]; break;
                    case 1: self.battery.state = [NSString stringWithFormat:@"Charging"]; break;
                    case 2: self.battery.state = [NSString stringWithFormat:@"Discharging"]; break;
                    case 3: self.battery.state = [NSString stringWithFormat:@"Charge complete"]; break;
                }
                [self.delegate smartDevice:self dataUpdate:@{@"Battery status" : self.battery.state}];
            }
            break;
            
        case SP_CODE_WORK_MODE:
            if (body->len == sizeof(uint8_t)) {
                uint8_t mode = body->data[0];
                NSString *work_mode = [NSString stringWithFormat:@"%d", mode];
                [self.delegate smartDevice:self dataUpdate:@{@"Work mode" : work_mode}];
            }
            break;
            
        case SP_CODE_CHARGE_TIMES:
            if (body->len == sizeof(uint32_t)) {
                uint32_t times = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                NSString *charger_times = [NSString stringWithFormat:@"%u", times];
                [self.delegate smartDevice:self dataUpdate:@{@"Charger times" : charger_times}];
            }
            break;
            
        case SP_CODE_DISCHARGE_TIMES:
            if (body->len == sizeof(uint32_t)) {
                uint32_t times = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                NSString *discharger_times = [NSString stringWithFormat:@"%u", times];
                [self.delegate smartDevice:self dataUpdate:@{@"Discharger times" : discharger_times}];
            }
            break;
            
        case SP_CODE_WORK_TIME:
            if (body->len == sizeof(uint32_t)) {
                uint32_t time = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                NSString *work_time = [NSString stringWithFormat:@"%u hour", time];
                [self.delegate smartDevice:self dataUpdate:@{@"Work time" : work_time}];
            }
            break;
            
        case SP_CODE_CURRENT_CUR:
            if (body->len == sizeof(uint32_t)) {
                uint32_t cur = body->data[0] | (((uint32_t)body->data[1]) << 8) |
                (((uint32_t)body->data[2]) << 16) | (((uint32_t)body->data[3]) << 24);
                NSString *current = [NSString stringWithFormat:@"%0.2fA", (float)cur / 1000.0];
                [self.delegate smartDevice:self dataUpdate:@{@"Current current" : current}];
            }
            break;
            
        case SP_CODE_CURRENT_PER:
            if (body->len == sizeof(uint8_t)) {
                uint8_t percent = body->data[0];
                self.battery.percent = [NSString stringWithFormat:@"%d%%", percent];
                [self.delegate smartDevice:self dataUpdate:@{@"Battery percent" : self.battery.percent}];
            }
            break;
            
        default:
        {
            NSData *body_code = [[NSData alloc]initWithBytes:&code length:1];
            NSData *body_data = [[NSData alloc]initWithBytes:body->data length:body->len];
            [self.delegate smartDevice:self dataUpdate:@{@"Unknown code" : @{@"body code" : body_code, @"body data" : body_data}}];
            return ;
        }
    }
}

// 固件升级应答处理
- (void)firmwareUpgradeResponseHandler:(protocol_body_t *)body withCode:(uint8_t)code {
    
    SmartDeviceUpgradeState upgradeState = -1;
    uint8_t result = body->code & ~0x80; // 获取应答结果
    protocol_body_t res_body;
    res_body.data = malloc(BODY_DATA_MAX_LEN);
    FirmwareFile *firmwareFile = ((FirmwareFile *)[self.firmwareUpgrade.firmware.bin_file objectAtIndex:0]);
    
    switch (code)
    {
        case SP_CODE_UPGRADE_REQUEST:
        {
            ota_upgrade_response_t upgrade_response;
            memcpy(&upgrade_response, body->data, sizeof(upgrade_response));
//            NSString *version = [NSString stringWithFormat:@"v%d.%d.%d", upgrade_response.version[0], upgrade_response.version[1], upgrade_response.version[2]];
            self.firmwareUpgrade.dataTransLength = MIN(upgrade_response.length, BODY_DATA_MAX_LEN - sizeof(ota_trans_file_data_t));
            
//            if ([version compare:firmwareFile.version options:NSNumericSearch] == NSOrderedAscending) { //currentVersiion < firmwareVersion
                ota_upgrade_file_info_t ota_upgrade_file_info;
                
                [self.firmwareUpgrade.firmware.product_id getBytes:ota_upgrade_file_info.pid length:sizeof(ota_upgrade_file_info.pid)];
                NSString *str_version = [firmwareFile.version substringFromIndex:1]; // 除去前面的v字符
                NSArray *array_version = [str_version componentsSeparatedByString:@"."]; // 使用字符"."进行分割
                for (int i = 0; i < sizeof(ota_upgrade_file_info.version); i ++) {
                    ota_upgrade_file_info.version[i] = [((NSString *)[array_version objectAtIndex:i]) intValue];
                }
                memcpy(ota_upgrade_file_info.md5, firmwareFile.md5.bytes, sizeof(ota_upgrade_file_info.md5));
                ota_upgrade_file_info.crc32 = (uint32_t)firmwareFile.crc32;
                ota_upgrade_file_info.length = (uint32_t)firmwareFile.file_data.length;
                
                res_body.len = sizeof(ota_upgrade_file_info);
                res_body.code = SP_CODE_UPGRADE_FILE_INFO; // 发送文件信息
                memcpy(res_body.data, &ota_upgrade_file_info, sizeof(ota_upgrade_file_info));
                
                NSData *md5_data = [NSData dataWithBytes:ota_upgrade_file_info.md5 length:sizeof(ota_upgrade_file_info.md5)];
                NSLog(@"Firmware file CRC32: 0x%08X, MD5: %@", ota_upgrade_file_info.crc32, md5_data);
                NSLog(@"The firmware upgrade request has been responded to");
//            }
            upgradeState = SmartDeviceUpgradeStateResponseRequest;
        }
            break;
            
        case SP_CODE_UPGRADE_FILE_INFO:
        {
            ota_store_file_info_t store_file_info;
            ota_req_file_offset_t ota_req_file_offset;
            
            memcpy(&store_file_info, body->data, sizeof(store_file_info));
            if (store_file_info.store_length == 0) goto _retransmission;
            
            if (store_file_info.store_length >= firmwareFile.file_data.length) {
                NSLog(@"The stored files are larger than the firmware in this transfer, stored length: %u", store_file_info.store_length);
                goto _retransmission;
            }
            
            uint32_t data_crc32 = (uint32_t)crc32(0, firmwareFile.file_data.bytes, store_file_info.store_length); //计算已储存数据的校验值
            if (store_file_info.crc32 == data_crc32) { // 文件数据的CRC32正确
                ota_req_file_offset = store_file_info.store_length;
            } else { // 剩余文件数据的CRC32错误
                _retransmission:
                ota_req_file_offset = 0; // 重新传输文件
            }
            
            res_body.len = sizeof(ota_req_file_offset);
            res_body.code = SP_CODE_UPGRADE_FILE_OFFSET; // 发送文件偏移
            memcpy(res_body.data, &ota_req_file_offset, sizeof(ota_req_file_offset));
            self.firmwareUpgrade.fileOffset = ota_req_file_offset;
            upgradeState = SmartDeviceUpgradeStateSentFileInfo;
            NSLog(@"Firmware upgrade file info response, set offset address: %u", ota_req_file_offset);
        }
            break;
            
        case SP_CODE_UPGRADE_FILE_OFFSET:
        {
            ota_res_file_offset_t file_offset;
            memcpy(&file_offset, body->data, sizeof(file_offset));
            if (file_offset > self.firmwareUpgrade.fileOffset)
                self.firmwareUpgrade.fileOffset = 0;
            [self packFirmwareDataToBody:&res_body]; // 发送固件数据
            upgradeState = SmartDeviceUpgradeStateSentOffset;
            NSLog(@"Firmware upgrqade file offset value: %u", file_offset);
        }
            break;
            
        case SP_CODE_UPGRADE_FILE_DATA:
            if (result == 0) {
                if (self.firmwareUpgrade.fileOffset == firmwareFile.file_data.length) { // 所有数据已发送完成
                    uint8_t cmd;
                    if (self.firmwareUpgrade.firmware.bin_file.count >= 2) {
                        cmd = OTA_UPGRADE_CMD_CHECK; // 只校验固件不执行重启，等待下一个文件的发送后再重启装载
                    } else {
                        cmd = OTA_UPGRADE_CMD_CHECK_REBOOT; // 校验并重启安装新固件
                    }
                    res_body.len = sizeof(cmd);
                    res_body.code = SP_CODE_UPGRADE_END; // 发送结束升级的指令
                    memcpy(res_body.data, &cmd, sizeof(ota_upgrade_cmd_type));
                    
                } else { // 已完成部分数据传输
                    [self packFirmwareDataToBody:&res_body]; // 继续发送固件数据
                }
            }
            upgradeState = SmartDeviceUpgradeStateTransData;
            break;
            
        case SP_CODE_UPGRADE_END:
            if (result == 0) { // 升级成功
                if (self.firmwareUpgrade.firmware.bin_file.count >= 2) { // 还有固件文件需要传输
                    [self.firmwareUpgrade.firmware.bin_file removeObject:[self.firmwareUpgrade.firmware.bin_file objectAtIndex:0]]; // 删除已传输完的固件
                    [self sendUpgradeRequest]; // 发送升级请求
                    NSLog(@"Firmware transfer is successful. Transfer of the next file begins");
                    break;
                } else {
                    [self.firmwareUpgrade.firmware.bin_file removeAllObjects];
                    NSLog(@"Firmware upgrade success.");
                }
            }
            upgradeState = SmartDeviceUpgradeStateEnd;
            break;
    }
    
    if (result == 0 && code != SP_CODE_UPGRADE_END) { // 应答成功状态才需要继续发送数据
        if (res_body.code == SP_CODE_UPGRADE_FILE_INFO) { // 将发送固件文件信息
            [self.smart_protocol send_frame_with_fcb:FCB_DEFAULT body:&res_body timeout:10000]; // 发送文件信息后，芯片需要点时间进行Flash擦除
        } else {
            [self.smart_protocol send_frame_with_fcb:FCB_DEFAULT body:&res_body];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(smartDevice:upgradeStateUpdate:withResult:)]) {
        [self.delegate smartDevice:self upgradeStateUpdate:upgradeState withResult:result];
    }
    
    free(res_body.data);
}

// 打包固件文件数据到Body
- (void)packFirmwareDataToBody:(protocol_body_t *)res_body {
    
    ota_trans_file_data_t trans_file_head;
    uint8_t file_trans_head_len = sizeof(trans_file_head) - sizeof(trans_file_head.data);
    FirmwareFile *firmwareFile = ((FirmwareFile *)[self.firmwareUpgrade.firmware.bin_file objectAtIndex:0]);
    
    trans_file_head.length = MIN(self.firmwareUpgrade.dataTransLength,
                                 firmwareFile.file_data.length - self.firmwareUpgrade.fileOffset);
    trans_file_head.data = malloc(trans_file_head.length);
    memcpy(trans_file_head.data, firmwareFile.file_data.bytes + self.firmwareUpgrade.fileOffset, trans_file_head.length);
    trans_file_head.offset = (uint32_t)self.firmwareUpgrade.fileOffset;
    trans_file_head.crc16 = [self CRC16ModbusByteCalc:trans_file_head.data length:trans_file_head.length];
    
    res_body->len = file_trans_head_len + trans_file_head.length;
    res_body->code = SP_CODE_UPGRADE_FILE_DATA; // 发送文件数据
    memcpy(res_body->data, &trans_file_head, file_trans_head_len);
    memcpy(res_body->data + file_trans_head_len, trans_file_head.data, trans_file_head.length);
    
    free(trans_file_head.data);
    self.firmwareUpgrade.fileOffset += trans_file_head.length; // 计算下次发送的偏移量
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(smartDevice:upgradeProgress:)]) {
        [self.delegate smartDevice:self upgradeProgress:(float)self.firmwareUpgrade.fileOffset / (float)firmwareFile.file_data.length];
    }
}

// 智能包协议数据帧下发接口
- (void)SmartProtocolDataSend:(NSData *)data {
    if (self.write_char == nil) return ;
    if (self.baseInfo.peripheral.canSendWriteWithoutResponse != true || self.send_queue.count != 0) { // BLE未就绪 或者 发送队列中还有数据未发送
        [self.send_queue addObject:data]; // 保存数据等待就绪后发送
    } else { // 蓝牙就绪且队列已发送完
        [self.baseInfo.peripheral writeValue:data forCharacteristic:self.write_char type:CBCharacteristicWriteWithoutResponse];
    }
}

// 计算CRC16(Modbus模式)
- (uint16_t) CRC16ModbusByteCalc:(const uint8_t *)data length:(uint8_t) length {
    
    uint16_t crc = 0xFFFF;
    for (int n = 0; n < length; n++) {
        crc = data[n] ^ crc;
        for (int i = 0; i < 8; i++) {
            if (crc & 0x01) {
                crc = crc >> 1;
                crc = crc ^ 0xA001;
            } else {
                crc = crc >> 1;
            }
        }
    }
    return crc;
}

#pragma mark -- BLE 接口

// 控制器改变状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if(central.state == CBManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil]; // 扫描周围所有的设备 并执行设备蓝牙的连接
    }
}

// 搜索到设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([peripheral.identifier isEqual:self.baseInfo.peripheral.identifier]) {
        [self.centralManager stopScan]; // 停止扫描
        self.baseInfo.peripheral = peripheral; // 保存需要连接的BLE外围设备
        [self.centralManager connectPeripheral:peripheral options:nil]; // 连接设备蓝牙
    }
}

// 已经连接设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    [self updateDeviceState:SmartDeviceBLEConnected];
    
    if (self.baseInfo.manufacture_data->uuid_flag == 0x5A) { // 使用自定义UUID
        self.service_uuid = [NSString stringWithFormat:@"%04X", self.baseInfo.manufacture_data->server_uiud];
        self.upload_uuid = [NSString stringWithFormat:@"%04X", self.baseInfo.manufacture_data->upload_uuid];
        self.download_uuid = [NSString stringWithFormat:@"%04X", self.baseInfo.manufacture_data->download_uuid];
    } else { // 使用默认的UUID
        self.service_uuid = DEFAULT_SERVIICE_UUID;
        self.upload_uuid = DEFAULT_UPLOAD_UUID;
        self.download_uuid = DEFAULT_DOWNLOAD_UUID;
    }
    
    self.baseInfo.peripheral.delegate = self; // 设置代理
    [self.baseInfo.peripheral discoverServices:nil]; // 扫描服务
    NSLog(@"Connect to %@", self.baseInfo.product_info.default_name);
}

// 连接失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [self.centralManager cancelPeripheralConnection:self.baseInfo.peripheral]; // 取消连接
    [self updateDeviceState:SmartDeviceBLECononectFailed];
}

// 断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    dispatch_block_cancel(self.conTimeoutBlock); // 取消超时任务
    [self updateDeviceState:SmartDeviceBLEDisconnected];
    NSLog(@"Disconnect to %@", self.baseInfo.product_info.default_name);
}

// 已经发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    for (CBService *service in peripheral.services) {
        NSLog(@"Server: %@", service);
        if (service.UUID.UUIDString == self.service_uuid) { // 数据通讯服务
            self.write_char = nil;
            [peripheral discoverCharacteristics:nil forService:service];//扫描服务里面的特征
            return ;
        }
    }
    
    NSLog(@"No service is found");
    [self updateDeviceState:SmartDeviceBLEServiceError];
    [self.centralManager cancelPeripheralConnection:self.baseInfo.peripheral]; // 取消连接
}

// 发现特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    bool discover_upload_uuid = false;
    if (service.UUID.UUIDString != self.service_uuid) return ;
    
    for (CBCharacteristic *Characteristic in service.characteristics) { // 遍历所有特征
        
        if (Characteristic.UUID.UUIDString == self.upload_uuid) { // 如果是上报的特征
            if (Characteristic.properties & CBCharacteristicPropertyNotify) { // 如果特征支持通知
                NSLog(@"Discover the upload characteristic, will enable the notify in the characteristic %@", Characteristic.UUID.UUIDString);
                [peripheral setNotifyValue:YES forCharacteristic:Characteristic]; // 打开通知功能
                discover_upload_uuid = true;
            } else { // 错误：上报的特征不支持通知功能
                NSLog(@"Upload Characteristic %@ no support notify", Characteristic.UUID.UUIDString);
            }
        }
        
        if (Characteristic.UUID.UUIDString == self.download_uuid) { // 如果是下发特征
            if (Characteristic.properties == CBCharacteristicPropertyWriteWithoutResponse)
                self.write_char = Characteristic; // 保存该特征 用于下发数据
        }
    }
    
    if (self.write_char == nil || discover_upload_uuid == false) {// 如果没发现写入特征或者上报特征
        NSLog(@"No write feature or report feature is found");
        [self updateDeviceState:SmartDeviceBLECharacteristicError];
        [self.centralManager cancelPeripheralConnection:self.baseInfo.peripheral]; // 取消连接
        
    } else {
        [self updateDeviceState:SmartDeviceBLEDiscoverCharacteristic];
    }
}

// 发现特征描述
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"Discover the characteristic descriptors");
}

// 更新特征描述值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    NSLog(@"Update the value in the characteristic descriptor");
}

// 已经更新特征值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic.UUID.UUIDString == self.upload_uuid) {
        [self.smart_protocol receive_data_handle:characteristic.value]; // 处理协议数据
    }
}

// 已经更新通知状态
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    NSLog(@"Did enable the notification state in the characteristic %@", characteristic.UUID.UUIDString);
    [self updateDeviceState:SmartDeviceBLENotifyEnable];
    NSLog(@"BLE Device maximum write value length: %ld", [self.baseInfo.peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse]);
    
    NSData *aes_key_tail = [NSData dataWithBytes:self.baseInfo.manufacture_data->aes_key_tail length:8];
    [self.smart_protocol aes_tail_key_set:aes_key_tail]; // 设置AES(ECB)密钥
    [self.smart_protocol send_connect]; // 发送握手连接
}

// 写入无应答数据已完成
- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    if (self.send_queue && self.send_queue.count) { // 队列中还有数据未发送
        NSData *send_data;
        send_data = [self.send_queue objectAtIndex:0]; // 获取一帧数据
        [self.baseInfo.peripheral writeValue:send_data forCharacteristic:self.write_char type:CBCharacteristicWriteWithoutResponse]; // 发送数据
        [self.send_queue removeObject:send_data]; // 删除已发送到数据
    }
}

@end
