//
//  SmartDeviceStandard.h
//  SmartTools
//
//  Created by Evler on 2023/1/10.
//

#ifndef SmartDeviceStandard_h
#define SmartDeviceStandard_h


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
} NS_ENUM_AVAILABLE(10_13, 10_0);

typedef NS_ENUM(NSInteger, SmartDeviceUpgradeState) {
    SmartDeviceUpgradeStateResponseRequest = 0,
    SmartDeviceUpgradeStateSentFileInfo,
    SmartDeviceUpgradeStateSentOffset,
    SmartDeviceUpgradeStateTransData,
    SmartDeviceUpgradeStateEnd,
    SmartDeviceUpgradeStateTimeout
} NS_ENUM_AVAILABLE(10_13, 10_0);

@protocol SmartDeviceDelegate <NSObject>

@required
- (void)smartDeviceDidUpdateState:(SmartDeviceState)state;

@optional
- (void)smartDeviceDataUpdate:(NSDictionary <NSString *, id>*)data;
- (void)smartDeviceUpgradeStateUpdate:(SmartDeviceUpgradeState) state withResult:(uint8_t)result;
- (void)smartDeviceUpgradeProgress:(float)progress;

@end


#endif /* SmartDeviceStandard_h */
