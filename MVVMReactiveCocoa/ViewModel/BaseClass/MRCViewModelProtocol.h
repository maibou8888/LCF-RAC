//
//  MRCViewModelProtocol.h
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 14/12/27.
//  Copyright (c) 2014年 leichunfeng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MRCTitleViewType) {
    MRCTitleViewTypeDefault,
    MRCTitleViewTypeDoubleTitle,
    MRCTitleViewTypeLoadingTitle
};

@protocol MRCViewModelServices;

// The Protocol for viewModel.
@protocol MRCViewModelProtocol <NSObject>

@required

// Initialization method. This is the preferred way to create a new viewModel.
//
// services - The service bus of Model layer.
// params   - The parameters to be passed to view model.
//
// Returns a new view model.
- (instancetype)initWithServices:(id<MRCViewModelServices>)services params:(id)params;

// The `services` parameter in `-initWithServices:params:` method.
@property (nonatomic, strong, readonly) id<MRCViewModelServices> services;

// The `params` parameter in `-initWithServices:params:` method.
@property (nonatomic, strong, readonly) id params;

@optional

@property (nonatomic, assign) MRCTitleViewType titleViewType;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

// The callback block.
@property (nonatomic, copy) VoidBlock_id callback;

// A RACSubject object, which representing all errors occurred in view model.
@property (nonatomic, strong, readonly) RACSubject *errors;

@property (nonatomic, assign) BOOL shouldFetchLocalDataOnViewModelInitialize;
@property (nonatomic, assign) BOOL shouldRequestRemoteDataOnViewDidLoad;

@property (nonatomic, strong, readonly) RACSubject *willDisappearSignal;

// An additional method, in which you can initialize data, RACCommand etc.
//
// This method will be execute after the execution of `-initWithServices:params:` method. But
// the premise is that you need to inherit `MRCViewModel`.

// 因为在MRCViewModel的allocWithZone里面实现了initialize方法
- (void)initialize;

@end
