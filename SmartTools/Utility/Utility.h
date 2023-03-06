//
//  Utility.h
//  SmartTools
//
//  Created by Evler on 2023/2/10.
//

#ifndef Utility_h
#define Utility_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define dataToU16(data)             data[0] | (((uint32_t)data[1]) << 8)
#define dataToU32(data)             data[0] | (((uint32_t)data[1]) << 8) | (((uint32_t)data[2]) << 16) | (((uint32_t)data[3]) << 24);

@interface FileInfo : NSObject

@property (nonatomic, strong) NSString  *name;
@property (nonatomic, strong) NSDate    *date;
@property (nonatomic, assign) NSInteger size;
@property (nonatomic, strong) NSString  *owner;
@property (nonatomic, strong) NSString  *path;

+ (NSMutableArray<FileInfo *> *)readAllFileInfoInFolder:(NSString *)folderPath;

@end

@interface Utility : NSObject

+ (NSData *)HexStringToData:(NSString *)hexStr;

@end

#define RGBA_COLOR(R, G, B, A) [UIColor colorWithRed:((R) / 255.0f) green:((G) / 255.0f) blue:((B) / 255.0f) alpha:A]
#define RGB_COLOR(R, G, B) [UIColor colorWithRed:((R) / 255.0f) green:((G) / 255.0f) blue:((B) / 255.0f) alpha:1.0f]

@interface UIColor (HexColor)

// 从十六进制字符串获取颜色，
// color:支持@“#123456”、 @“0X123456”、 @“123456”三种格式
+ (UIColor *)colorWithHexString:(NSString *)color;
+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;

@end
#endif /* Utility_h */
