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


#pragma pack(push)
#pragma pack(1)     // 字节对齐

typedef struct
{
    uint16_t    company_id;             // 公司ID
    uint8_t     uuid_flag;              // uuid 标志
    uint16_t    server_uiud;            // 服务 uuid
    uint16_t    download_uuid;          // 下发特征 uuid
    uint16_t    upload_uuid;            // 上报特征 uuid
    uint8_t     device_id[2];           // 设备 id
    uint8_t     product_id[4];          // 产品 id
    uint8_t     aes_key_tail[8];        // aes密钥后8字节
    uint8_t     firmware_version[3];    // 固件版本
    uint8_t     capacity_value;         // 电池包容量值
} manufacture_data_t;

#pragma pack(pop)

@interface ProductInfo : NSObject

@property (nonatomic, strong) NSString *default_name;   // 产品默认名称
@property (nonatomic, strong) NSString *image;          // 产品图片

@end

@interface Device : NSObject

@property (nonatomic, strong) ProductInfo *product_info;            // 产品信息
@property (nonatomic, strong) CBPeripheral *peripheral;             // 蓝牙外围设备
@property (nonatomic, assign) manufacture_data_t *manufacture_data; // 厂商自定义数据

@end

@interface FirmwareUpgrade : NSObject

@property (nonatomic, strong) NSMutableArray    *firmware;          // 固件文件信息数组
@property (nonatomic, strong) NSData            *pid;               // 升级文件的产品ID
@property (nonatomic, assign) NSInteger         fileOffset;         // 文件偏移
@property (nonatomic, strong) NSString          *currentVersiion;   // 当前固件版本
@property (nonatomic, assign) NSInteger         dataTransLength;    // 数据传输长度

@end

@interface SmartDevice : NSObject

@property (nonatomic, strong) Device *device;
@property (assign) id<SmartDeviceDelegate> delegate;

- (SmartDevice *)initWithCentralManager:(CBCentralManager *)centralManager;

// 连接智能设备
- (void)connectDevice:(Device *)device;

// 断开设备连接
- (void)disconnectDevice;

// 开始固件升级
- (bool)startFirmwareUpgrade:(NSString *)filePath;

@end

#endif /* SmartDevice_h */
