//
//  SmartDeviceStandard.h
//  SmartTools
//
//  Created by Evler on 2023/1/10.
//

#ifndef SmartDeviceStandard_h
#define SmartDeviceStandard_h

typedef NS_ENUM(NSInteger, SmartDeviceProductType) {
    SmartDeviceProductTypeBattery = 0,
};

typedef NS_ENUM(NSInteger, SmartDeviceState) {
    SmartDeviceBLEServiceError = 0,
    SmartDeviceBLECharacteristicError,
    SmartDeviceBLEDiscoverServer,
    SmartDeviceBLEDiscoverCharacteristic,
    SmartDeviceBLENotifyEnable,
    SmartDeviceBLEConnected,
    SmartDeviceBLEDisconnected,
    SmartDeviceConnectTimeout,
    SmartDeviceConnectSuccess,
};

typedef NS_ENUM(NSInteger, SmartDeviceUpgradeState) {
    SmartDeviceUpgradeStateResponseRequest = 0,
    SmartDeviceUpgradeStateSentFileInfo,
    SmartDeviceUpgradeStateSentOffset,
    SmartDeviceUpgradeStateTransData,
    SmartDeviceUpgradeStateEnd,
    SmartDeviceUpgradeStateTimeout
};

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

@class SmartDevice;

@protocol SmartDeviceDelegate <NSObject>

@required
- (void)smartDevice:(SmartDevice *)device didUpdateState:(SmartDeviceState)state;

@optional
- (void)smartDevice:(SmartDevice *)device dataUpdate:(NSDictionary <NSString *, id>*)data;
- (void)smartDevice:(SmartDevice *)device upgradeStateUpdate:(SmartDeviceUpgradeState) state withResult:(uint8_t)result;
- (void)smartDevice:(SmartDevice *)device upgradeProgress:(float)progress;

@end


#endif /* SmartDeviceStandard_h */
