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

// 读取文件夹中的所有文件信息(不创建数组)
+ (BOOL)readAllFile:(NSMutableArray<FileInfo *> *)fileInfo inFolder:(NSString *)folderPath {

    NSFileManager *manager = [NSFileManager defaultManager]; // 文件管理器
    if (![manager fileExistsAtPath:folderPath]) return false; // 检查目录是否存在
    
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
    return true;
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


@implementation UIColor (HexColor)

+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha
{
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6)
    {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"])
    {
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"])
    {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6)
    {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

//默认alpha值为1
+ (UIColor *)colorWithHexString:(NSString *)color
{
    return [self colorWithHexString:color alpha:1.0f];
}

@end

