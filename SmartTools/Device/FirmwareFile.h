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


+ (bool)decodeUpgrqadeFile:(NSString *)filePath pid:(NSData **)pid firmware:(NSMutableArray<FirmwareFile *> *)firmware;

@end

#endif /* FirmwareFile_h */
