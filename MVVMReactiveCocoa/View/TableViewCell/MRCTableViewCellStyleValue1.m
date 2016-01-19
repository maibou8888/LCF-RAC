//
//  MRCTableViewCellStyleValue1.m
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 15/3/5.
//  Copyright (c) 2015年 leichunfeng. All rights reserved.
//

#import "MRCTableViewCellStyleValue1.h"

@implementation MRCTableViewCellStyleValue1

//Value1样式：左边一个显示图片的imageView，左边一个主标题textLabel，右边一个副标题detailTextLabel，主标题字体比较黑
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
}

@end
