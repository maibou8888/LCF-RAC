//
//  MRCTableViewModel.h
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 14/12/27.
//  Copyright (c) 2014年 leichunfeng. All rights reserved.
//

#import "MRCViewModel.h"

@interface MRCTableViewModel : MRCViewModel

// The data source of table view.
@property (nonatomic, copy) NSArray *dataSource;

// The list of section titles to display in section index view.
@property (nonatomic, copy) NSArray *sectionIndexTitles;

//一共多少页
@property (nonatomic, assign) NSUInteger page;

//每页显示多少条数据
@property (nonatomic, assign) NSUInteger perPage;

//下拉刷新
@property (nonatomic, assign) BOOL shouldPullToRefresh;

//无限滚动
@property (nonatomic, assign) BOOL shouldInfiniteScrolling;

//searchBar搜索文本
@property (nonatomic, copy) NSString *keyword;

//选中当前行响应的信号
@property (nonatomic, strong) RACCommand *didSelectCommand;

//请求远程数据的信号
@property (nonatomic, strong, readonly) RACCommand *requestRemoteDataCommand;

//获取本地数据
- (id)fetchLocalData;

//error过滤器
- (BOOL (^)(NSError *error))requestRemoteDataErrorsFilter;

//计算offset
- (NSUInteger)offsetForPage:(NSUInteger)page;

//根据页数请求远程数据
- (RACSignal *)requestRemoteDataSignalWithPage:(NSUInteger)page;

@end
