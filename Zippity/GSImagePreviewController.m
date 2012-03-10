//
//  GSImagePreviewController.m
//  Zippity
//
//  Created by Simon Whitaker on 25/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSImagePreviewController.h"
#import "GSImageScrollView.h"

#define kPagePaddingWidth 10.0

@interface GSImagePreviewController ()

@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, retain) NSMutableSet * visiblePages;
@property (nonatomic, retain) NSMutableSet * reusablePages;

- (void)handleActionButton:(id)sender;

- (void)updatePageLayout;
- (void)updatePageOrientation;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (BOOL)isDisplayingPageAtIndex:(NSUInteger)index;
- (void)configurePage:(GSImageScrollView*)page ForIndex:(NSUInteger)index;
- (void)toggleChromeVisibility;
- (void)handleSingleTap:(UIGestureRecognizer*)gestureRecognizer;
- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecognizer;

@end

@implementation GSImagePreviewController

@synthesize imageFileWrappers=_imageFileWrappers;
@synthesize initialIndex=_initialIndex;
@synthesize scrollView=_scrollView;
@synthesize currentIndex=_currentIndex;
@synthesize visiblePages=_visiblePages;
@synthesize reusablePages=_reusablePages;

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.wantsFullScreenLayout = YES;
        _currentIndex = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad
{    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    
    [self.scrollView addGestureRecognizer:singleTapGestureRecognizer];
    [self.scrollView addGestureRecognizer:doubleTapGestureRecognizer];
    
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    
    UIBarButtonItem *actionBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                     target:self
                                                                                     action:@selector(handleActionButton:)];
    self.navigationItem.rightBarButtonItem = actionBarButton;
    
    self.visiblePages = [NSMutableSet set];
    self.reusablePages = [NSMutableSet set];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.tintColor = nil;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    self.currentIndex = self.initialIndex;
    
    [self updatePageOrientation];
    [self updatePageLayout];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    GSFileWrapper * container = [(GSFileWrapper*)[self.imageFileWrappers objectAtIndex:0] parent];
    NSLog(@"Viewing a set of %u image(s) from a total container size of %u file(s)", self.imageFileWrappers.count, container.fileWrappers.count);
    [TestFlight passCheckpoint:@"Opened an image preview view"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (CGRect)frameForPageAtIndex:(NSUInteger)page
{
    CGRect f = self.view.bounds;
    f.origin.x = self.scrollView.bounds.size.width * page + kPagePaddingWidth;
    return f;
}

- (BOOL)isDisplayingPageAtIndex:(NSUInteger)index
{
    for (GSImageScrollView *page in self.visiblePages) {
        if (page.index == index) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Interface orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updatePageOrientation];
}

- (void)configurePage:(GSImageScrollView*)page ForIndex:(NSUInteger)index
{
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    GSFileWrapper *imageFileWrapper = [self.imageFileWrappers objectAtIndex:index];
    UIImage *image = [UIImage imageWithContentsOfFile:imageFileWrapper.url.path];
    [page displayImage:image];
}

- (void)updatePageLayout
{
    // Updates the layout of current pages based on which 
    // pages are visible right now
    CGRect visibleBounds = self.scrollView.bounds;
    NSInteger firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds)) - 1;
    NSInteger lastNeededPageIndex = floorf((CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds)) + 1;
    
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex = MIN(lastNeededPageIndex, self.imageFileWrappers.count - 1);
    
    // Recycle no-longer-needed pages
    for (GSImageScrollView* page in self.visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            NSLog(@"Recycling page at index %u", page.index);
            [self.reusablePages addObject:page];
            [page removeFromSuperview];
        }
    }
    // Remove all contents of self.reusablePages from self.visiblePages
    // Can't do this in the for loop or we'd be mutating the visiblePages
    // set as we enumerated over it.
    [self.visiblePages minusSet:self.reusablePages];
    
    // Add any missing pages
    for (NSInteger index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageAtIndex:index]) {
            NSLog(@"Populating page at index %u", index);
            GSImageScrollView *page = [self dequeueReusablePage];
            if (page == nil) {
                page = [[GSImageScrollView alloc] initWithFrame:[self frameForPageAtIndex:index]];
                page.delegate = self;
            }
            [self configurePage:page ForIndex:index];
            
            [self.scrollView addSubview:page];
            [self.visiblePages addObject:page];
        }
    }
}

- (GSImageScrollView *)dequeueReusablePage
{
    GSImageScrollView *page = [self.reusablePages anyObject];
    if (page) {
        [self.reusablePages removeObject:page];
    }
    return page;
}

- (void)updatePageOrientation {
    CGRect f = self.view.bounds;
    f.origin.x -= kPagePaddingWidth;
    f.size.width += kPagePaddingWidth * 2;
    self.scrollView.frame = f;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.imageFileWrappers.count, 
                                             self.scrollView.frame.size.height);
    for (GSImageScrollView *page in self.visiblePages) {
        page.frame = [self frameForPageAtIndex:page.index];
        [page updateZoomScales];
    }
    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.currentIndex, 0);
}

#pragma mark - Custom accessors

- (void)setCurrentIndex:(NSUInteger)currentIndex
{
    if (currentIndex != _currentIndex) {
        _currentIndex = currentIndex;
        self.title = [NSString stringWithFormat:@"%u of %u", _currentIndex + 1, self.imageFileWrappers.count];
    }
}

#pragma mark - UIScrollView delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        [self updatePageLayout];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Don't call in scrollViewDidScroll; causes problems on rotation
    // when the delegate method gets called when the bounds change
    self.currentIndex = roundf(self.scrollView.contentOffset.x / self.scrollView.bounds.size.width);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if ([scrollView respondsToSelector:@selector(imageView)]) {
        return [(GSImageScrollView*)scrollView imageView];
    }
    return nil;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    
}

#pragma mark - UIActionSheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Save image"]) {
        GSFileWrapper *currentPhoto = [self.imageFileWrappers objectAtIndex:self.currentIndex];
        UIImage *image = [UIImage imageWithContentsOfFile:currentPhoto.url.path];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}

#pragma mark - UI event handlers

- (void)toggleChromeVisibility {
    CGFloat alpha;
    BOOL shouldShow = [[UIApplication sharedApplication] isStatusBarHidden];
    [[UIApplication sharedApplication] setStatusBarHidden:!shouldShow withAnimation:UIStatusBarAnimationFade];

    if (shouldShow) {
        // Make sure navigation bar is correctly placed - it will move to the top of 
        // the screen on rotation once the status bar is hidden and doesn't automatically
        // move back whent the status bar reappears.
        CGSize s = [[UIApplication sharedApplication] statusBarFrame].size;
        CGFloat statusBarHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? s.height : s.width;
        CGRect f = self.navigationController.navigationBar.frame;
        f.origin.y = statusBarHeight;
        self.navigationController.navigationBar.frame = f;
        
        alpha = 1.0;
    } else {
        alpha = 0.0;
    }

    [UIView animateWithDuration:0.35 animations:^{
        self.navigationController.navigationBar.alpha = alpha;
    }];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        GSImageScrollView *currentPage = nil;
        for (GSImageScrollView *page in self.visiblePages) {
            if (page.index == self.currentIndex) {
                currentPage = page;
                break;
            }
        }
        if (currentPage) {
            [currentPage handleDoubleTapAtPoint:[gestureRecognizer locationInView:currentPage.imageView]];
        }
    }
}

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    [self toggleChromeVisibility];
}

- (void)handleActionButton:(id)sender
{
    GSFileWrapper *currentPhoto = [self.imageFileWrappers objectAtIndex:self.currentIndex];
    NSString *actionSheetTitle = [NSString stringWithFormat:@"Share %@", currentPhoto.name];
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:actionSheetTitle
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Save image", nil];
    [as showFromRect:CGRectZero inView:self.view animated:YES];
}

@end
