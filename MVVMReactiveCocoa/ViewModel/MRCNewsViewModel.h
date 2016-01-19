//
//  MRCNewsViewModel.h
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 15/1/10.
//  Copyright (c) 2015年 leichunfeng. All rights reserved.
//

#import "MRCTableViewModel.h"

typedef NS_ENUM(NSUInteger, MRCNewsViewModelType) {
    MRCNewsViewModelTypeNews,
    MRCNewsViewModelTypePublicActivity
};

@interface MRCNewsViewModel : MRCTableViewModel

@property (nonatomic, copy, readonly) NSArray *events;
@property (nonatomic, assign, readonly) BOOL isCurrentUser;
@property (nonatomic, assign, readonly) MRCNewsViewModelType type;
@property (nonatomic, strong, readonly) RACCommand *didClickLinkCommand;

//遍历数组并用model填充
- (NSArray *)dataSourceWithEvents:(NSArray *)events;

@end
