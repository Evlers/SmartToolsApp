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

+ (NSMutableArray<FileInfo *> *)getAvaliableFirmwareInAllFile:(NSMutableArray<FileInfo *> *)allFile filtration:(NSDictionary *)filtration {

    NSData *product_id = filtration[@"product id"];
    NSString *hardware_version = filtration[@"hardware version"];
    NSString *boot_firmware_version = filtration[@"bootloader firmware version"];
    NSString *app_firmware_version = filtration[@"application firmware version"];
    
    NSMutableArray<FileInfo *> *avaliableFirmware = [NSMutableArray array];
    
    for (FileInfo *info in allFile) { // 遍历文件
        if ([info.path hasSuffix:@".zip"]) { // zip文件
            Firmware *firmware = [[Firmware alloc]initWithLoadFirmware:info.path]; // 装载升级文件
            
            if (firmware == nil) continue;
            if (product_id != nil && ![product_id isEqualToData:firmware.product_id]) continue; // 固件文件与设备PID是否一致
            
            if (hardware_version != nil) { // 如果需要筛选硬件版本号
                NSString *str_version = [firmware.hardware_version substringFromIndex:1]; // 除去前面的v字符
                NSArray *array_version = [str_version componentsSeparatedByString:@"."]; // 使用字符"."进行分割
                uint8_t firmware_major_version = [((NSString *)array_version[0]) intValue]; // 取主要的版本号
                str_version = [hardware_version substringFromIndex:1];
                array_version = [str_version componentsSeparatedByString:@"."];
                uint8_t needed_major_version = [((NSString *)array_version[0]) intValue];
                
                if (needed_major_version != firmware_major_version) continue; // 判断硬件版本是否匹配(只匹配主要的版本号,例如:v1.x.x)
            }
            
            for (FirmwareFile *file in firmware.bin_file) // 循环检查升级文件中的固件版本是否比设备当前版本高
            {
                NSString *version = (file.type == FirmwareFileTypeAppliction) ? app_firmware_version : boot_firmware_version;
                if (version == nil || [version compare:file.version options:NSNumericSearch] == NSOrderedAscending) { // 不筛选版本号，或者固件版本大于筛选的版本号
                    [avaliableFirmware addObject:info]; // 添加该升级文件
                    break; // 继续寻找其他可用的升级文件
                }
            }
        }
    }
    
    return avaliableFirmware;
}

- (Firmware *)initWithLoadFirmware:(NSString *)filePath {
    
    if (self != [super init]) return nil;
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject]; // caches路径
    NSString *folderPath = [cachesPath stringByAppendingPathComponent:@"FirmwareFileFoolder"]; // 解压目标路径
    NSData *manifest_data = nil;
    NSError *error;
    FirmwareFile *file;
    NSDictionary *root, *manifest;
    
    // 删除文件夹中解压前的文件
    NSFileManager *fileManage = [NSFileManager defaultManager];
    [fileManage removeItemAtPath:folderPath error:nil];
    
    if (![SSZipArchive unzipFileAtPath:filePath toDestination:folderPath]) { // 解压该文件到caches中的firmwareFile目录
        NSLog(@"Zip file decompress failed !");
        return nil;
    }
    
    NSMutableArray<FileInfo *> *upgradeFileFolder = [FileInfo readAllFileInfoInFolder:folderPath]; // 读取压缩文件中所有文件信息
    
    // 读取升级文件中的Json文件
    for (FileInfo *info in upgradeFileFolder) { // 读取压缩文件中的文件
        if ([info.name isEqualToString:@"manifest.json"]) { // 检查清单(Json文件)
            NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:info.path]; // 打开Json文件
            manifest_data = [file readDataToEndOfFile]; // 读取文件数据
            break;
        }
    }
    
    if (manifest_data == nil) {
        NSLog(@"The manifest object does not exist");
        return nil;
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
        if ((file = [self loadBinFile:manifest firmware:@"bootloader" fileFolder:upgradeFileFolder]) != nil)
            [self.bin_file addObject:file];
    }
    
    if (manifest[@"application"]) {
        FirmwareFile *file;
        if ((file = [self loadBinFile:manifest firmware:@"application" fileFolder:upgradeFileFolder]) != nil)
            [self.bin_file addObject:file];
    }
    
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
            if (memcmp(md5, firmwareFile.md5.bytes, sizeof(md5)) != 0  || crc32_value != firmwareFile.crc32) { // 校验错误
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
