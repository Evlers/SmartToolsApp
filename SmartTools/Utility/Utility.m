//
//  Utility.m
//  SmartTools
//
//  Created by Evler on 2023/2/10.
//

#import "Utility.h"


@implementation FileInfo

// 读取文件夹中的所有文件信息
+ (NSMutableArray<FileInfo *> *)readAllFileInfoInFolder:(NSString *)folderPath {
    
    NSMutableArray *fileInfo = [NSMutableArray array];
    NSFileManager *manager = [NSFileManager defaultManager]; // 文件管理器
    if (![manager fileExistsAtPath:folderPath]) return nil; // 检查目录是否存在
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator]; // 从前向后枚举器
    
    NSString *fileName = nil;
    while ((fileName = [childFilesEnumerator nextObject]) != nil) { // 使用枚举器,遍历所有文件
        NSDictionary *fileAttributes = [manager attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        
        FileInfo *file_info = [FileInfo alloc];
        file_info.name = fileName; // 文件名
        file_info.date = [fileAttributes objectForKey:@"NSFileCreationDate"]; // 文件创建日期
        file_info.size = [[fileAttributes objectForKey:@"NSFileSize"] integerValue]; // 文件大小
        file_info.owner = [fileAttributes objectForKey:@"NSFileGroupOwnerAccountName"]; // 所有权用户
        file_info.path = [folderPath stringByAppendingPathComponent:fileName]; // 文件完整路径
        
        [fileInfo addObject:file_info]; // 添加到所有文件可变数组中
    }
    return fileInfo;
}

@end


@implementation Utility

// 十六进制NSStrinig转NSData
+ (NSData *)HexStringToData:(NSString *)hexStr {
    hexStr = [hexStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    hexStr = [hexStr lowercaseString];
    NSUInteger len = hexStr.length;
    if (!len) return nil;
    unichar *buf = malloc(sizeof(unichar) * len);
    if (!buf) return nil;
    [hexStr getCharacters:buf range:NSMakeRange(0, len)];
    
    NSMutableData *result = [NSMutableData data];
    unsigned char bytes;
    char str[3] = { '\0', '\0', '\0' };
    int i;
    for (i = 0; i < len / 2; i++) {
        str[0] = buf[i * 2];
        str[1] = buf[i * 2 + 1];
        bytes = strtol(str, NULL, 16);
        [result appendBytes:&bytes length:1];
    }
    free(buf);
    return result;
}

@end

