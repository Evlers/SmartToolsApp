//
//  Utility.h
//  SmartTools
//
//  Created by Evler on 2023/2/10.
//

#ifndef Utility_h
#define Utility_h

#import <Foundation/Foundation.h>

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

#endif /* Utility_h */
