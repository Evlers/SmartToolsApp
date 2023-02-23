//
//  SmartDevice.h
//  SmartTools
//
//  Created by Evler on 2023/1/10.
//

#ifndef SmartDevice_h
#define SmartDevice_h

#import <Foundation/Foundation.h>
#import "CoreBluetooth/CoreBluetooth.h"
#import "SmartDeviceStandard.h"
#import "FirmwareFile.h"


@interface ProductInfo : NSObject

@property (nonatomic, strong) NSString *default_name;       // 产品默认名称
@property (nonatomic, strong) NSString *image;              // 产品图片
@property (nonatomic, assign) SmartDeviceProductType type;  // 产品类型

@end

@interface SmartBattery : NSObject

@property (nonatomic, strong) NSString *state;                      // 电池包当前状态
@property (nonatomic, strong) NSString *temperature;                // 电池包当前温度 单位：摄氏度
@property (nonatomic, strong) NSString *percent;                    // 电池当前电量 单位：%

@end

@interface DeviceBaseInfo : NSObject

@property (nonatomic, assign) SmartDeviceState state;               // 设备状态
@property (nonatomic, strong) ProductInfo *product_info;            // 产品信息
@property (nonatomic, strong) CBPeripheral *peripheral;             // 蓝牙外围设备
@property (nonatomic, assign) manufacture_data_t *manufacture_data; // 厂商自定义数据
@property (nonatomic, strong) NSString *hardware_version;           // 设备硬件版本号
@property (nonatomic, strong) NSString *boot_firmware_version;      // 设备Bootloader固件版本号
@property (nonatomic, strong) NSString *app_firmware_version;       // 设备Application固件版本号
@property (nonatomic, strong) NSString *uuid;                       // 设备唯一标识(UUID)

@end

@interface FirmwareUpgrade : NSObject

@property (nonatomic, strong) Firmware          *firmware;          // 固件文件信息
@property (nonatomic, assign) NSInteger         fileOffset;         // 文件偏移
@property (nonatomic, assign) NSInteger         dataTransLength;    // 数据传输长度

@end

@interface SmartDevice : NSObject

@property (nonatomic, strong) DeviceBaseInfo *baseInfo;             // 设备基本信息
@property (nonatomic, strong) SmartBattery *battery;                // 智能电池包

@property (assign) id<SmartDeviceDelegate> delegate;

- (SmartDevice *)init;

// 已连接到设备蓝牙(中心管理器代理中调用)
- (void)BLEConnected;

// 已断开设备蓝牙(中心管理器代理中调用)
- (void)BLEdisconnected;

// 查询设备所有数据
- (void)getDeviceAllData;

// 查询设备基本信息
- (void)getDeviceBaseInfo;

// 查询电池包基本信息
- (void)getBattreyBaseInfo;

// 开始固件升级
- (bool)startFirmwareUpgrade:(NSString *)filePath;

@end

#endif /* SmartDevice_h */
