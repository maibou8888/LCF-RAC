//
//  MRCOwnedReposViewModel.h
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 15/1/18.
//  Copyright (c) 2015年 leichunfeng. All rights reserved.
//

#import "MRCTableViewModel.h"

typedef NS_ENUM(NSUInteger, MRCReposViewModelType) {
    MRCReposViewModelTypeOwned,
    MRCReposViewModelTypeStarred,
    MRCReposViewModelTypeSearch,
    MRCReposViewModelTypePublic,
    MRCReposViewModelTypeTrending,
};

typedef NS_OPTIONS(NSUInteger, MRCReposViewModelOptions) {
    MRCReposViewModelOptionsObserveStarredReposChange = 1 << 0,     //监听star关系变化
    MRCReposViewModelOptionsSaveOrUpdateRepos         = 1 << 1,     //是否入库实体 是否缓存
    MRCReposViewModelOptionsSaveOrUpdateStarredStatus = 1 << 2,     //是否更新关系表
    MRCReposViewModelOptionsPagination                = 1 << 3,     //是否分页 上拉加载
    MRCReposViewModelOptionsSectionIndex              = 1 << 4,     //是否有索引
    MRCReposViewModelOptionsShowOwnerLogin            = 1 << 5,     //显示OwnerLogin
    MRCReposViewModelOptionsMarkStarredStatus         = 1 << 6,     //标记StarredStatus
};

@interface MRCOwnedReposViewModel : MRCTableViewModel

@property (nonatomic, strong, readonly) OCTUser *user;
@property (nonatomic, assign, readonly) BOOL isCurrentUser;
@property (nonatomic, copy, readonly) NSArray *repositories;

@property (nonatomic, assign, readonly) MRCReposViewModelType type;
@property (nonatomic, assign, readonly) MRCReposViewModelOptions options;

@end
