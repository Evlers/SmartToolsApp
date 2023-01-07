//
//  AppDelegate.m
//  SmartTools
//
//  Created by Evler on 2022/12/19.
//

#import "AppDelegate.h"
#import "SelectDevice.h"
#import "SmartProtocol.h"
#import "SmartDevice.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

// 已经进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"App enter backgroud");
//    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil]; // 获取XIB文件
//    SmartDevice *device_view = [mainStory instantiateViewControllerWithIdentifier:@"DeviceView"]; // 获取试图控制器
//    [device_view.navigationController popViewControllerAnimated:YES];
//    [self.window.rootViewController.navigationController popViewControllerAnimated:YES];
}

// 即将进入前台
- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    NSLog(@"App will enter foregroud");
//    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"Main" bundle:nil]; // 获取XIB文件
//    SmartDevice *device_view = [mainStory instantiateViewControllerWithIdentifier:@"DeviceView"]; // 获取试图控制器
//    NSLog(@"Device View:%@", device_view);
//    [device_view.smart_protocol send_connect]; // 重新发送连接握手
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end