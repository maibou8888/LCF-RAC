//
//  MRCAppDelegate.m
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 14/12/27.
//  Copyright (c) 2014年 leichunfeng. All rights reserved.
//

#import "MRCAppDelegate.h"
#import "MRCViewModelServicesImpl.h"
#import "MRCLoginViewModel.h"
#import "MRCLoginViewController.h"
#import "MRCHomepageViewModel.h"
#import "MRCHomepageViewController.h"
#import "MRCNavigationControllerStack.h"
#import "MRCNavigationController.h"
#import <Appirater/Appirater.h>
#import <Bugtags/Bugtags.h>
#import <JSPatch/JSPatch.h>

@interface MRCAppDelegate ()

@property (nonatomic, strong) MRCViewModelServicesImpl *services;
@property (nonatomic, strong) id<MRCViewModelProtocol> viewModel;
@property (nonatomic, strong) Reachability *reachability;

@property (nonatomic, strong, readwrite) MRCNavigationControllerStack *navigationControllerStack;
@property (nonatomic, assign, readwrite) NetworkStatus networkStatus;
@property (nonatomic, copy, readwrite) NSString *adURL;

@end

@implementation MRCAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self configureFMDB];
    [self configureAppearance];
    [self configureKeyboardManager];
    [self configureReachability];
    [self configureUMengSocial];
    [self configureAppirater];
    [self configureBugtags];
    [self configureJSPatch];

    //显示网络活动指示器
    AFNetworkActivityIndicatorManager.sharedManager.enabled = YES;
    
    self.services = [[MRCViewModelServicesImpl alloc] init];
    self.navigationControllerStack = [[MRCNavigationControllerStack alloc] initWithServices:self.services];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.services resetRootViewModel:[self createInitialViewModel]];
    [self.window makeKeyAndVisible];
    
    // Save the application version info.
    [[NSUserDefaults standardUserDefaults] setValue:MRC_APP_VERSION forKey:MRCApplicationVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.scheme isEqual:MRC_URL_SCHEME]) {
        [OCTClient completeSignInWithCallbackURL:url];
        return YES;
    }
    return [UMSocialSnsService handleOpenURL:url];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [Appirater appEnteredForeground:YES];
}

- (id<MRCViewModelProtocol>)createInitialViewModel {
    // The user has logged-in.
    if ([SSKeychain rawLogin].isExist && [SSKeychain accessToken].isExist) {
		// Some OctoKit APIs will use the `login` property of `OCTUser`.
        OCTUser *user = [OCTUser mrc_userWithRawLogin:[SSKeychain rawLogin] server:OCTServer.dotComServer];

        OCTClient *authenticatedClient = [OCTClient authenticatedClientWithUser:user token:[SSKeychain accessToken]];
        self.services.client = authenticatedClient;
        
        return [[MRCHomepageViewModel alloc] initWithServices:self.services params:nil];
    } else {
        return [[MRCLoginViewModel alloc] initWithServices:self.services params:nil];
    }
}

#pragma mark - Application configuration

- (void)configureFMDB {
    [[FMDatabaseQueue sharedInstance] inDatabase:^(FMDatabase *db) {
        NSString *version = [[NSUserDefaults standardUserDefaults] valueForKey:MRCApplicationVersionKey];
        if (![version isEqualToString:MRC_APP_VERSION]) {
            if (version == nil) {
                [SSKeychain deleteAccessToken];
                
                NSString *path = [[NSBundle mainBundle] pathForResource:@"update_v1_2_0" ofType:@"sql"];
                NSString *sql  = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                
                //executeStatements->执行多条sql语句
                if (![db executeStatements:sql]) {
                    MRCLogLastError(db);
                }
            }
        }
    }];
}

- (void)configureAppearance {
    self.window.backgroundColor = UIColor.whiteColor;
    
    //背景色
    [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:(48 - 40) / 215.0 green:(67 - 40) / 215.0 blue:(78 - 40) / 215.0 alpha:1];
    //黑色背景 白色文字
    [UINavigationBar appearance].barStyle  = UIBarStyleBlack;
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];

    [UISegmentedControl appearance].tintColor = [UIColor whiteColor];

    [UITabBar appearance].tintColor = HexRGB(colorI2);
}

- (void)configureKeyboardManager {
    IQKeyboardManager.sharedManager.enableAutoToolbar = NO;
    IQKeyboardManager.sharedManager.shouldResignOnTouchOutside = YES;
}

- (void)configureReachability {
    self.reachability = Reachability.reachabilityForInternetConnection;
    
    RAC(self, networkStatus) = [[[[[NSNotificationCenter defaultCenter]
    	rac_addObserverForName:kReachabilityChangedNotification object:nil]
        map:^(NSNotification *notification) {
            return @([notification.object currentReachabilityStatus]);
        }]
    	startWith:@(self.reachability.currentReachabilityStatus)]
        distinctUntilChanged];
    
    @weakify(self)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @strongify(self)
        [self.reachability startNotifier];
    });
}

- (void)configureUMengSocial {
    [UMSocialData setAppKey:MRC_UM_APP_KEY];
    
    [UMSocialWechatHandler setWXAppId:MRC_WX_APP_ID appSecret:MRC_WX_APP_SECRET url:MRC_UM_SHARE_URL];
    [UMSocialSinaHandler openSSOWithRedirectURL:MRC_WEIBO_REDIRECT_URL];
    [UMSocialQQHandler setQQWithAppId:MRC_QQ_APP_ID appKey:MRC_QQ_APP_KEY url:MRC_UM_SHARE_URL];

    [UMSocialConfig hiddenNotInstallPlatforms:@[ UMShareToQQ, UMShareToQzone, UMShareToWechatSession, UMShareToWechatTimeline ]];
}

/*Appirater是一个可以直接使用到任何iPhone应用（iOS4.0及以上）中的开源类，用于提醒用户在打开App时，对应用进行评论或打分。*/
- (void)configureAppirater {
    [Appirater setAppId:MRC_APP_ID];
    [Appirater setDaysUntilPrompt:7];
    [Appirater setUsesUntilPrompt:5];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES];
}

/*
 *Bugtags是国内首款为改善移动产品质量而专门打造的测试平台产品。
 *使用Bugtags平台可以随时随地对移动产品提出准确的改善意见，使得测试更简单，修复问题更轻松，产品用户满意度更高。
 */
- (void)configureBugtags {
    [Bugtags startWithAppKey:MRC_BUGTAGS_APP_KEY invocationEvent:BTGInvocationEventNone];
}

//JS <-> OC
- (void)configureJSPatch {
    [JSPatch startWithAppKey:MRC_JSPATCH_APP_KEY];
}

@end
