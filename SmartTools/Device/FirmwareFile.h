//
//  FirmwareFile.h
//  SmartTools
//
//  Created by Evler on 2023/2/13.
//

#ifndef FirmwareFile_h
#define FirmwareFile_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FirmwareFileType) {
    FirmwareFileTypeBootloader = 0,
    FirmwareFileTypeAppliction,
    FirmwareFileTypeSubDev,
};

@interface FirmwareFile : NSObject

@property (nonatomic, strong) NSFileHandle      *file;              // 固件文件
@property (nonatomic, strong) NSData            *file_data;         // 文件数据
@property (nonatomic, assign) FirmwareFileType  type;               // 固件文件类型
@property (nonatomic, assign) NSInteger         crc32;              // 文件CRC32校验值
@property (nonatomic, strong) NSData            *md5;               // 文件MD5校验值
@property (nonatomic, strong) NSString          *version;           // 固件文件版本

@end


@interface Firmware : NSObject

@property (nonatomic, strong) NSMutableArray<FirmwareFile *>    *bin_file;          // 固件文件 (该升级文件中包含的所有固件可执行文件)
@property (nonatomic, strong) NSData                            *product_id;        // 产品ID (该升级文件适用的产品ID)
@property (nonatomic, strong) NSString                          *hardware_version;  // 硬件版本 (该升级文件适用的设备硬件版本)
@property (nonatomic, strong) NSString                          *update_content;    // 更新内容 (包含本次更新的内容描述)
@property (nonatomic, strong) NSString                          *ota_version;       // 升级文件的版本号

- (Firmware *)initWithLoadFirmware:(NSString *)filePath;

@end

#endif /* FirmwareFile_h */
