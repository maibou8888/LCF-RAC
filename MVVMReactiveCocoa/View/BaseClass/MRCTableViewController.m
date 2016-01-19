//
//  MRCTableViewController.m
//  MVVMReactiveCocoa
//
//  Created by leichunfeng on 14/12/27.
//  Copyright (c) 2014年 leichunfeng. All rights reserved.
//

#import "MRCTableViewController.h"
#import "MRCTableViewModel.h"
#import "MRCTableViewCellStyleValue1.h"

@interface MRCTableViewController ()

//MRCOwnedReposViewController
@property (nonatomic, weak, readwrite) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak, readwrite) IBOutlet UITableView *tableView;

@property (nonatomic, strong, readonly) MRCTableViewModel *viewModel;
@property (nonatomic, strong) CBStoreHouseRefreshControl *refreshControl;

@end

@implementation MRCTableViewController

@dynamic viewModel;

- (instancetype)initWithViewModel:(id<MRCViewModelProtocol>)viewModel {
    self = [super initWithViewModel:viewModel];
    if (self) {
        //如果shouldRequestRemoteDataOnViewDidLoad为1 则请求网络数据（在mrcViewModel里面已经置为1）
        if ([viewModel shouldRequestRemoteDataOnViewDidLoad]) {
            @weakify(self)
            [[self rac_signalForSelector:@selector(viewDidLoad)] subscribeNext:^(id x) {
                @strongify(self)
                [self.viewModel.requestRemoteDataCommand execute:@1];
            }];
        }
    }
    return self;
}

- (void)setView:(UIView *)view {
    [super setView:view];
    if ([view isKindOfClass:UITableView.class]) self.tableView = (UITableView *)view;
}

- (UIEdgeInsets)contentInset {
    return UIEdgeInsetsMake(64, 0, 0, 0);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //contentOffset是scrollview当前显示区域顶点相对于frame顶点的偏移量，比如上个例子你拉到最下面，contentoffset就是(0 ,480)，也就是y偏移了480
    self.tableView.contentOffset = CGPointMake(0, self.searchBar.mrc_height - self.contentInset.top);
    
    //contentInset是scrollview的contentview的顶点相对于scrollview的位置，例如你的contentInset = (0 ,100)，那么你的contentview就是从scrollview的(0 ,100)开始显示
    self.tableView.contentInset  = self.contentInset;
    
    //滚动条在scrollView中得位置
    self.tableView.scrollIndicatorInsets = self.contentInset;
    
    self.tableView.sectionIndexColor = [UIColor darkGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    
    //当我们tableView中section有很多，数据量比较大的时候我们可以引入indexList，来方便完成section的定位，例如系统的通讯录程序。我们可以通过设置tableView的sectionIndexMinimumDisplayRowCount属性来指定当tableView中多少行的时候开始显示IndexList，默认的设置是NSIntegerMax，即默认是不显示indexList的。
    self.tableView.sectionIndexMinimumDisplayRowCount = 20;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    [self.tableView registerClass:[MRCTableViewCellStyleValue1 class] forCellReuseIdentifier:@"MRCTableViewCellStyleValue1"];
    
    @weakify(self)
    if (self.viewModel.shouldPullToRefresh) {
        self.refreshControl = [CBStoreHouseRefreshControl attachToScrollView:self.tableView
                                                                      target:self
                                                               refreshAction:@selector(refreshTriggered:)
                                                                       plist:@"storehouse"
                                                                       color:UIColor.blackColor
                                                                   lineWidth:1.5
                                                                  dropHeight:80
                                                                       scale:1
                                                        horizontalRandomness:150
                                                     reverseLoadingAnimation:YES
                                                     internalAnimationFactor:0.5];
    }
    
    if (self.viewModel.shouldInfiniteScrolling) {
        [self.tableView addInfiniteScrollingWithActionHandler:^{
            @strongify(self)
            [[[self.viewModel.requestRemoteDataCommand
				execute:@(self.viewModel.page + 1)]
        		deliverOnMainThread]
            	subscribeNext:^(NSArray *results) {
                    @strongify(self)
                    self.viewModel.page += 1;
                } error:^(NSError *error) {
                    @strongify(self)
                    [self.tableView.infiniteScrollingView stopAnimating];
                } completed:^{
                    @strongify(self)
                    [self.tableView.infiniteScrollingView stopAnimating];
                }];
        }];
        
        RAC(self.tableView, showsInfiniteScrolling) = [[RACObserve(self.viewModel, dataSource)
        	deliverOnMainThread]
            map:^(NSArray *dataSource) {
                @strongify(self)
                NSUInteger count = 0;
                for (NSArray *array in dataSource) {
                    count += array.count;
                }
                return @(count >= self.viewModel.perPage);
        }];
    }
    
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)dealloc {
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
}

- (void)bindViewModel {
    [super bindViewModel];
    
    @weakify(self)
    [RACObserve(self.viewModel, dataSource).distinctUntilChanged.deliverOnMainThread subscribeNext:^(id x) {
        @strongify(self)
        [self.tableView reloadData];
    }];

    [self.viewModel.requestRemoteDataCommand.executing subscribeNext:^(NSNumber *executing) {
        @strongify(self)
        UIView *emptyDataSetView = [self.tableView.subviews.rac_sequence objectPassingTest:^(UIView *view) {
            return [NSStringFromClass(view.class) isEqualToString:@"DZNEmptyDataSetView"];
        }];
        emptyDataSetView.alpha = 1.0 - executing.floatValue;
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView dequeueReusableCellWithIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withObject:(id)object {}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.dataSource ? self.viewModel.dataSource.count : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel.dataSource[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self tableView:tableView dequeueReusableCellWithIdentifier:@"MRCTableViewCellStyleValue1" forIndexPath:indexPath];
    
    id object = self.viewModel.dataSource[indexPath.section][indexPath.row];
    [self configureCell:cell atIndexPath:indexPath withObject:(id)object];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section >= self.viewModel.sectionIndexTitles.count) return nil;
    return self.viewModel.sectionIndexTitles[section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.searchBar != nil) {
        if (self.viewModel.sectionIndexTitles.count != 0) {
            //UITableViewIndexSearch 索引上方的放大镜
            return [self.viewModel.sectionIndexTitles.rac_sequence startWith:UITableViewIndexSearch].array;
        }
    }
    return self.viewModel.sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (self.searchBar != nil) {
        //index是索引条的序号。从0开始，所以第0 个是放大镜。如果是放大镜坐标就移动到搜索框处
        //因为返回的值是section的值。所以减1就是与section对应的值了
        if (index == 0) {
            [tableView scrollRectToVisible:self.searchBar.frame animated:NO];
        }
        return index - 1;
    }
    return index;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.viewModel.didSelectCommand execute:indexPath];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.refreshControl scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.refreshControl scrollViewDidEndDragging];
}

#pragma mark - Listening for the user to trigger a refresh

- (void)refreshTriggered:(id)sender {
    @weakify(self)
    [[[self.viewModel.requestRemoteDataCommand
     	execute:@1]
     	deliverOnMainThread]
    	subscribeNext:^(id x) {
            @strongify(self)
            self.viewModel.page = 1;
        } error:^(NSError *error) {
            @strongify(self)
            [self.refreshControl finishingLoading];
        } completed:^{
            @strongify(self)
            [self.refreshControl finishingLoading];
        }];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.viewModel.keyword = searchText;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];

    searchBar.text = nil;
    self.viewModel.keyword = nil;
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    return [[NSAttributedString alloc] initWithString:@"No Data"];
}

#pragma mark - DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return self.viewModel.dataSource == nil;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

- (CGPoint)offsetForEmptyDataSet:(UIScrollView *)scrollView {
    return CGPointMake(0, -(self.tableView.contentInset.top - self.tableView.contentInset.bottom) / 2);
}

@end
