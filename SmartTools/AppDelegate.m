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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 创建底部导航栏
    UITabBarController *tb = [[UITabBarController alloc]init];
    tb.tabBar.translucent = NO;
    tb.tabBar.tintColor = [UIColor colorWithHexString:@"FF9040"];
    
    // 添加视图控制器到导航栏
    NSArray *arrayVC = [NSArray arrayWithObjects:[[SelectDevice alloc] init], nil];
    tb.viewControllers = arrayVC;
    tb.title = @"Home";
    
    // 创建导航控制器
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:tb];
    
    self.window.rootViewController = nav; // 设置好根视图控制器
    [self.window makeKeyAndVisible]; // 设置这个window为主(key)窗口并设置成为可见
    return YES;
}

#pragma mark - ApplicationDelegate
- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<NSString *,id> *)options {
    if (options) {
        NSString *str = [NSString stringWithFormat:@"\n发送请求的应用程序的 Bundle ID：%@\n\n文件的NSURL：%@", options[UIApplicationOpenURLOptionsSourceApplicationKey], url];
        NSLog(@"%@", str);
        
        if (self.window && url) {
            // 根据“其他应用” 用“本应用”打开，通过url，进入列表页
            [self pushDocListViewControllerWithUrl:url];
        }
    }
    return YES;
}

#pragma mark ApplicationDelegate Method
/** 根据“其他应用” 用“本应用”打开，通过url，进入列表页 */
- (void)pushDocListViewControllerWithUrl:(NSURL *)url {

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
}

// 即将进入前台
- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    NSLog(@"App will enter foregroud");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
