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

#pragma mark -- Product info

@interface ProductInfo : NSObject

@property (nonatomic, strong) NSString *default_name;       // 产品默认名称
@property (nonatomic, strong) NSString *image;              // 产品图片
@property (nonatomic, assign) SmartDeviceProductType type;  // 产品类型

@end

#pragma mark -- Smart battery device

#define SmartBatCellNumber                  7               // 电池包电池数量

// 电池包功能开关位
#define SmartBatFunSwHighTempAlarm          0x00000001      // 高温告警开关
#define SmartBatFunSwLedBlink               0x00000002      // 指示灯闪烁开关
#define SmaerBatFunSwSuspendCharging        0x00000004      // 暂停充电

// 电池包各参数就绪状态位
#define SmartBatReadyOfState                0x00000001
#define SmartBatReadyOfTemp                 0x00000002
#define SmartBatReadyOfPercent              0x00000004
#define SmartBatReadyOfCurCur               0x00000008
#define SmartBatReadyOfDateofManu           0x00000010
#define SmartBatReadyOfProtectVolt          0x00000020
#define SmartBatReadyOfMaxDischargingCur    0x00000040
#define SmartBatReadyOfFunSw                0x00000080
#define SmartBatReadyOfWorkMode             0x00000100
#define SmartBatReadyOfNumberOfCharging     0x00000200
#define SmartBatReadyOfNumberOfDischarging  0x00000400
#define SmartBatReadyOfNumberOfShortCircuit 0x00000800
#define SmartBatReadyOfNumberOfOverCurrent  0x00001000
#define SmartBatReadyOfAccumulatedWorkTime  0x00002000
#define SmartBatReadyOfEvents               0x00004000
#define SmartBatReadyOfTotalVolt            0x00008000
#define SmartBatReadyOfCellVolt             0x00010000
#define SmartBatReadyOfWorkTime             0x00020000
#define SmartBatReadyOfAllParams            0x0003FFFF

typedef NS_ENUM(uint8_t, SmartBatteryWorkMode)
{
    SmartBatteryWorkModePerformance = 0,        // 性能模式
    SmartBatteryWorkModeBalance,                // 平衡模式
    SmartBatteryWorkModeECO,                    // 省电模式
    SmartBatteryWorkModeExpert,                 // 专业模式
};

typedef NS_ENUM(uint8_t, SmartBatteryState)
{
    SmartBatteryStateStandby = 0,               // 待机中
    SmartBatteryStateCharging,                  // 充电中
    SmartBatteryStateDischarging,               // 放电中
    SmartBatteryStateChargeComplete,            // 充电完成
};

@interface SmartBattery : NSObject

@property (nonatomic, assign) uint32_t paramIsReady;                // 以下各参数就绪状态位
@property (nonatomic, assign) SmartBatteryState state;              // 电池包当前状态
@property (nonatomic, assign) bool isLock;                          // 电池包锁定状态
@property (nonatomic, assign) int16_t temperature;                  // 电池包当前温度 单位：摄氏度
@property (nonatomic, assign) uint8_t percent;                      // 电池当前电量 单位：%
@property (nonatomic, assign) float currentCurrent;                 // 当前电流 单位：A
@property (nonatomic, strong) NSDate *dateOfManufacture;            // 生产日期
@property (nonatomic, assign) float protectVoltage;                 // 保护电压 单位:V
@property (nonatomic, assign) float maxDischargingCurrent;          // 最大放电电流 单位：A
@property (nonatomic, assign) uint32_t functioon_switch;            // 功能开关
@property (nonatomic, assign) SmartBatteryWorkMode workMode;        // 工作模式
@property (nonatomic, assign) uint32_t numberOfCharging;            // 充电次数
@property (nonatomic, assign) uint32_t numberOfDischarging;         // 放电次数
@property (nonatomic, assign) uint32_t numberOfShortCircuit;        // 短路次数
@property (nonatomic, assign) uint32_t numberOfOverCurrent;         // 过流次数
@property (nonatomic, assign) uint32_t accumulatedWorkTime;         // 累计工作时间 单位：分钟
@property (nonatomic, assign) uint32_t events;                      // 电池包事件
@property (nonatomic, assign) float totalVoltage;                   // 总电压
@property (nonatomic, assign) float *cellVoltage;                   // 每节电池电压(最多7节)

@end

#pragma mark -- Smart device

@interface DeviceBaseInfo : NSObject

@property (nonatomic, assign) SmartDeviceState state;               // 设备状态
@property (nonatomic, strong) ProductInfo *product_info;            // 产品信息
@property (nonatomic, strong) CBPeripheral *peripheral;             // 蓝牙外围设备
@property (nonatomic, assign) manufacture_data_t *manufacture_data; // 厂商自定义数据
@property (nonatomic, strong) NSString *hardware_version;           // 设备硬件版本号
@property (nonatomic, strong) NSString *boot_firmware_version;      // 设备Bootloader固件版本号
@property (nonatomic, strong) NSString *app_firmware_version;       // 设备Application固件版本号
@property (nonatomic, strong) NSString *uuid;                       // 设备唯一标识(UUID)
@property (nonatomic, strong) NSString *chipID;                     // 芯片ID

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

// 连接到设备
- (void)connectToDevice;

// 断开与设备的连接
- (void)disconnectToDevice;

// 查询设备所有数据
- (void)getDeviceAllData;

// 设置功能开关
- (void)setFunctionSwitch:(uint32_t)sw isOn:(bool)on;

// 开始固件升级
- (bool)startFirmwareUpgrade:(NSString *)filePath;

@end

#endif /* SmartDevice_h */
