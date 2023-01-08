//
//  FirmwareUpgrade.m
//  SmartTools
//
//  Created by Evler on 2023/1/7.
//

#import "FirmwareUpgrade.h"

@interface FirmwareUpgrade ()

@property (strong, nonatomic) NSMutableArray *documentArr;

@end

@implementation FirmwareUpgrade

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Firmware upgrade";
}

// 即将进入视图
-(void)viewWillAppear:(BOOL)animated {
    
    NSFileManager *manager = [NSFileManager defaultManager]; // 文件管理器
    NSString *folderPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Inbox/"]]; // 总文件夹
    NSError *error = nil;

    self.documentArr = [[manager contentsOfDirectoryAtPath:folderPath error:&error] copy]; // 获取包含有该文件夹下所有文件的文件名及文件夹名的数组

    if (![manager fileExistsAtPath:folderPath]) return; // 检查改目录是否存在
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator]; // 从前向后枚举器
    
    NSString *fileName = nil;
    while ((fileName = [childFilesEnumerator nextObject]) != nil) { // 使用枚举器,遍历所有文件
        NSDictionary *fileAttributes = [manager attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        NSLog(@"***********************************************************");
        NSLog(@"File name: %@", fileName);
        NSLog(@"File create date: %@", [fileAttributes objectForKey:@"NSFileCreationDate"]); // 文件创建日期
        NSLog(@"File size: %lu", [[fileAttributes objectForKey:@"NSFileSize"] integerValue]); // 文件大小
        NSLog(@"File owner account name: %@", [fileAttributes objectForKey:@"NSFileGroupOwnerAccountName"]); // 所有权用户名
        NSLog(@"File absolute path: %@", [folderPath stringByAppendingPathComponent:fileName]); // 文件完整路径
    }
}

// 已经进入视图
-(void)viewDidAppear:(BOOL)animated {
    
}

@end

