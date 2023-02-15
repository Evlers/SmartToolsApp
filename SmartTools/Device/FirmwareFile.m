//
//  FirmwareFile.m
//  SmartTools
//
//  Created by Evler on 2023/2/13.
//

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCrypto.h>
#import <zlib.h>
#import "FirmwareFile.h"
#import "SSZipArchive.h"
#import "Utility.h"

@implementation FirmwareFile

@end

@implementation Firmware

- (Firmware *)initWithLoadFirmware:(NSString *)filePath {
    
    if (self != [super init]) return nil;
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject]; // caches路径
    NSString *folderPath = [cachesPath stringByAppendingPathComponent:@"FirmwareFilePath"]; // 解压目标路径
    NSData *manifest_data = nil;
    NSError *error;
    FirmwareFile *file;
    NSDictionary *root, *manifest;
    
    if (![SSZipArchive unzipFileAtPath:filePath toDestination:folderPath]) { // 解压该文件到caches中的firmwareFile目录
        NSLog(@"Zip file decompress failed !");
        return nil;
    }
    
    NSMutableArray *upgradeFile = [NSMutableArray array];
    [Utility readAllFileInfo:upgradeFile folderPath:folderPath]; // 读取所有文件信息
    
    // 读取升级文件中的Json文件
    for (FileInfo *info in upgradeFile) { // 读取压缩文件中的文件
        if ([info.name isEqualToString:@"manifest.json"]) { // 检查清单(Json文件)
            NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:info.path]; // 打开Json文件
            manifest_data = [file readDataToEndOfFile]; // 读取文件数据
            if (manifest_data == nil) {
                NSLog(@"The manifest object does not exist");
                return nil;
            }
            break;
        }
    }
    
    // JSON 数据解析
    root = [NSJSONSerialization JSONObjectWithData:manifest_data options:NSJSONReadingMutableContainers error:&error];
    if (error != nil) {
        NSLog(@"Json format error: %@", error);
        return nil;
    }
    
    if ((manifest = root[@"manifest"]) == nil) {
        NSLog(@"The manifest object does not exist");
        return nil;
    }
    
    if ((self.ota_version = manifest[@"ota_version"]) == nil || ![self.ota_version isEqualToString:@"1.0.0"]) {
        NSLog(@"The manifest version did not match!");
        return nil;
    }
    
    NSString *pid_str;
    if ((pid_str = manifest[@"pid"]) == nil) {
        NSLog(@"Product ID not found in upgrade file!");
        return nil;
    }
    self.product_id = [Utility HexStringToData:pid_str];
    
    if ((self.hardware_version = manifest[@"hardware_version"]) == nil) {
        NSLog(@"hardware version not found in upgrade file!");
    }
    
    if ((self.update_content = manifest[@"update_content"]) == nil) {
        NSLog(@"update content not found in upgrade file!");
    }
    
    if (manifest[@"bootloader"] == nil && manifest[@"application"] == nil) { // Bootloader 以及 application 固件都没识别到
        NSLog(@"No bootloader or appliction upgrade object found");
        return nil;
    }
    
    // 读取固件文件信息
    self.bin_file = [NSMutableArray array];
    if (manifest[@"bootloader"]) {
        if ((file = [self loadBinFile:manifest firmware:@"bootloader" fileFolder:upgradeFile]) != nil)
            [self.bin_file addObject:file];
    } else
        NSLog(@"The bootloader object does not exist");
    
    if (manifest[@"application"]) {
        FirmwareFile *file;
        if ((file = [self loadBinFile:manifest firmware:@"application" fileFolder:upgradeFile]) != nil)
            [self.bin_file addObject:file];
    } else
        NSLog(@"The application object does not exist");
    
    if (self.bin_file.count == 0) { // 如果未能找到一个固件
        return nil; // 错误
    }
    
    return self;
}

- (FirmwareFile *)loadBinFile:(NSDictionary *)manifest firmware:(NSString *)file fileFolder:(NSMutableArray *)upgradeFile {
    
    NSDictionary *firmware = manifest[file];
    NSString *fileName = firmware[@"file"];
    if (fileName == nil) {
        NSLog(@"File name object in the %@ does not exist !", file);
        return nil;
    }
    
    for (FileInfo *info in upgradeFile) { // 读取压缩文件中的文件
        if ([info.name isEqualToString:fileName]) {
            FirmwareFile *firmwareFile = [FirmwareFile alloc];
            
            firmwareFile.file = [NSFileHandle fileHandleForReadingAtPath:info.path]; // 打开固件准备读取
            if (firmwareFile.file == nil) {
                NSLog(@"Firmware file open failed: %@", fileName);
                return nil;
            }
            
            firmwareFile.version = firmware[@"version"]; // 读取版本号
            firmwareFile.crc32 = [((NSString *)firmware[@"crc32"]) integerValue]; // 读取CRC32校验值
            firmwareFile.md5 = [Utility HexStringToData:(NSString *)firmware[@"md5"]]; // 读取MD5校验值
            firmwareFile.file_data = [firmwareFile.file readDataToEndOfFile]; // 读取文件数据
            firmwareFile.type = ([file isEqualToString:@"bootloader"]) ? FirmwareFileTypeBootloader : FirmwareFileTypeAppliction; // 文件类型
            
            // 校验固件文件是否正确
            uint8_t md5[16];
            uint32_t crc32_value = (uint32_t)crc32(0, firmwareFile.file_data.bytes, (uint32_t)firmwareFile.file_data.length);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations" // 忽略MD5已被IOS 13.0以上版本弃用的警告
            CC_MD5(firmwareFile.file_data.bytes, (uint32_t)firmwareFile.file_data.length, md5);
#pragma clang diagnostic pop
            if (memcmp(md5, firmwareFile.md5.bytes, sizeof(md5)) != 0) { // 校验错误
                NSLog(@"The %@ firmware file verification in the upgrade file is incorrect!", file);
                NSData *md5_ns = [[NSData alloc]initWithBytes:md5 length:sizeof(md5)];
                NSLog(@"md5: %@ %@", md5_ns, firmwareFile.md5);
                NSLog(@"crc32: %u %lu", crc32_value, firmwareFile.crc32);
                return nil;
            }
            return firmwareFile;
        }
    }
    
    return nil;
}

@end