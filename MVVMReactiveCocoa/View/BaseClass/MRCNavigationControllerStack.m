//
//  MRCNavigationControllerStack.m
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 15/1/10.
//  Copyright (c) 2015年 leichunfeng. All rights reserved.
//

#import "MRCNavigationControllerStack.h"
#import "MRCRouter.h"
#import "MRCNavigationController.h"
#import "MRCTabBarController.h"

@interface MRCNavigationControllerStack ()

@property (nonatomic, strong) id<MRCViewModelServices> services;
@property (nonatomic, strong) NSMutableArray *navigationControllers;

@end

@implementation MRCNavigationControllerStack

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    MRCNavigationControllerStack *navigationControllerStack = [super allocWithZone:zone];

	@weakify(navigationControllerStack)
    [[navigationControllerStack
    	rac_signalForSelector:@selector(initWithServices:)]
    	subscribeNext:^(id x) {
            @strongify(navigationControllerStack)
        	[navigationControllerStack registerNavigationHooks];
     	}];

    return navigationControllerStack;
}

- (instancetype)initWithServices:(id<MRCViewModelServices>)services {
    self = [super init];
    if (self) {
        _services = services;
        _navigationControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

//如果数组里面没有navigationController 则加进来
- (void)pushNavigationController:(UINavigationController *)navigationController {
    if ([self.navigationControllers containsObject:navigationController]) return;
    [self.navigationControllers addObject:navigationController];
}

//移除数组的lastObject
- (UINavigationController *)popNavigationController {
    UINavigationController *navigationController = self.navigationControllers.lastObject;
    [self.navigationControllers removeLastObject];
    return navigationController;
}

- (void)registerNavigationHooks {
    @weakify(self)
    [[(NSObject *)self.services
        rac_signalForSelector:@selector(pushViewModel:animated:)]
        subscribeNext:^(RACTuple *tuple) {
            @strongify(self)
            UIViewController *viewController = (UIViewController *)[MRCRouter.sharedInstance viewControllerForViewModel:tuple.first];
            viewController.hidesBottomBarWhenPushed = YES;
            [self.navigationControllers.lastObject pushViewController:viewController animated:[tuple.second boolValue]];
        }];

    [[(NSObject *)self.services
        rac_signalForSelector:@selector(popViewModelAnimated:)]
        subscribeNext:^(RACTuple *tuple) {
        	@strongify(self)
            [self.navigationControllers.lastObject popViewControllerAnimated:[tuple.first boolValue]];
        }];

    [[(NSObject *)self.services
        rac_signalForSelector:@selector(popToRootViewModelAnimated:)]
        subscribeNext:^(RACTuple *tuple) {
            @strongify(self)
            [self.navigationControllers.lastObject popToRootViewControllerAnimated:[tuple.first boolValue]];
        }];

    [[(NSObject *)self.services
        rac_signalForSelector:@selector(presentViewModel:animated:completion:)]
        subscribeNext:^(RACTuple *tuple) {
        	@strongify(self)
            UIViewController *viewController = (UIViewController *)[MRCRouter.sharedInstance viewControllerForViewModel:tuple.first];

            UINavigationController *presentingViewController = self.navigationControllers.lastObject;
            if (![viewController isKindOfClass:UINavigationController.class]) {
                viewController = [[MRCNavigationController alloc] initWithRootViewController:viewController];
            }
            
            //我们可以理解为presentViewController是把要显示的页面加到当前的页面之上
            [self pushNavigationController:(UINavigationController *)viewController];

            [presentingViewController presentViewController:viewController animated:[tuple.second boolValue] completion:tuple.third];
        }];

    [[(NSObject *)self.services
        rac_signalForSelector:@selector(dismissViewModelAnimated:completion:)]
        subscribeNext:^(RACTuple *tuple) {
            @strongify(self)
            
            ////我们可以理解为dismissViewControllerAnimated是把要显示的页面从当前的页面移除
            [self popNavigationController];
            [self.navigationControllers.lastObject dismissViewControllerAnimated:[tuple.first boolValue] completion:tuple.second];
        }];

    [[(NSObject *)self.services
        rac_signalForSelector:@selector(resetRootViewModel:)]
        subscribeNext:^(RACTuple *tuple) {
            @strongify(self)
            [self.navigationControllers removeAllObjects];

            UIViewController *viewController = (UIViewController *)[MRCRouter.sharedInstance viewControllerForViewModel:tuple.first];

            if (![viewController isKindOfClass:[UINavigationController class]] && ![viewController isKindOfClass:[MRCTabBarController class]]) {
                //登录页面
                viewController = [[MRCNavigationController alloc] initWithRootViewController:viewController];
                [self pushNavigationController:(UINavigationController *)viewController];
            }

            MRCSharedAppDelegate.window.rootViewController = viewController;
        }];
}

@end
