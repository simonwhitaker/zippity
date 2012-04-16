//
//  GSImagePreviewController.m
//  Zippity
//
//  Created by Simon Whitaker on 25/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSSmokedInfoView.h"
#import "ZPImagePreviewController.h"
#import "ZPImageScrollView.h"

static NSString * ActionMenuSaveToPhotosButtonTitle; // = @"Save To Photos";
static NSString * ActionMenuOpenInButtonTitle; // = @"Open In...";
static NSString * ActionMenuCancelButtonTitle; // = @"Cancel";

#define kPagePaddingWidth 10.0

@interface ZPImagePreviewController ()

@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, retain) NSMutableSet * visiblePages;
@property (nonatomic, retain) NSMutableSet * reusablePages;

- (void)handleActionButton:(id)sender;

- (void)updatePageLayout;
- (void)updatePageOrientation;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (BOOL)isDisplayingPageAtIndex:(NSUInteger)index;
- (void)configurePage:(ZPImageScrollView*)page ForIndex:(NSUInteger)index;
- (void)toggleChromeVisibility;
- (void)handleSingleTap:(UIGestureRecognizer*)gestureRecognizer;
- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecognizer;

@end

@implementation ZPImagePreviewController

@synthesize imageFileWrappers = _imageFileWrappers;
@synthesize initialIndex = _initialIndex;
@synthesize scrollView = _scrollView;
@synthesize currentIndex = _currentIndex;
@synthesize visiblePages = _visiblePages;
@synthesize reusablePages = _reusablePages;
@synthesize delegate = _delegate;
@synthesize actionSheet = _actionSheet;

+ (void)initialize
{
    // Cancel is already translated in ZPFileContainerListViewController, so
    // we'll just use NSBundle's -localizedStringForKey:value:table: here
    ActionMenuCancelButtonTitle = [[NSBundle mainBundle] localizedStringForKey:@"Cancel" value:nil table:nil];
    ActionMenuOpenInButtonTitle = NSLocalizedString(@"Open In...", @"Label for the Open In button in the image gallery action sheet");
    ActionMenuSaveToPhotosButtonTitle = NSLocalizedString(@"Save To Photos", @"Label for the Save To Photos button in the image gallery action sheet");
}

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
    self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
    self.currentIndex = self.initialIndex;
    
    // Hiding the navigation bar and toolbar will result in the
    // view's subviews being re-laid out. We'll populate them in
    // viewDidLayoutSubviews so here we'll call setNeedsLayout
    // just to make sure that the subviews definitely get laid out
    // (in case some unexpected change to this behaviour in a
    // future app version or iOS release otherwise catches us out).
    [self.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews
{
    [self updatePageOrientation];
    [self updatePageLayout];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    for (ZPImageScrollView *page in self.visiblePages) {
        if (page.index == index) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Interface orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (isIpad) {
        return YES;
    }
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updatePageOrientation];
}

- (void)configurePage:(ZPImageScrollView*)page ForIndex:(NSUInteger)index
{
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    page.imageFileWrapper = [self.imageFileWrappers objectAtIndex:index];
}

- (void)updatePageLayout
{
    // Updates the layout of current pages based on which 
    // pages are visible right now
    CGRect visibleBounds = self.scrollView.bounds;
    NSInteger firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    NSInteger lastNeededPageIndex = floorf((CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds));
    
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex = MIN(lastNeededPageIndex, self.imageFileWrappers.count - 1);
    
    // Recycle no-longer-needed pages
    for (ZPImageScrollView* page in self.visiblePages) {
        if (page.index < firstNeededPageIndex || page.index > lastNeededPageIndex) {
            page.imageFileWrapper = nil;
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
            ZPImageScrollView *page = [self dequeueReusablePage];
            if (page == nil) {
                page = [[ZPImageScrollView alloc] initWithFrame:[self frameForPageAtIndex:index]];
                page.delegate = self;
            }
            [self configurePage:page ForIndex:index];
            
            [self.scrollView addSubview:page];
            [self.visiblePages addObject:page];
        }
    }
}

- (ZPImageScrollView *)dequeueReusablePage
{
    ZPImageScrollView *page = [self.reusablePages anyObject];
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
    for (ZPImageScrollView *page in self.visiblePages) {
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
        NSString *formatString = NSLocalizedString(@"%u of %u", @"Label at the top of the image gallery showing the current page, e.g. if on the 2nd of 3 images this reads '2 of 3' in the English translation");
        self.title = [NSString stringWithFormat:formatString, _currentIndex + 1, self.imageFileWrappers.count];
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
    
    if ([self.delegate respondsToSelector:@selector(imagePreviewControllerDidShowImageForFileWrapper:)]) {
        [self.delegate imagePreviewControllerDidShowImageForFileWrapper:[self.imageFileWrappers objectAtIndex:self.currentIndex]];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if ([scrollView respondsToSelector:@selector(imageView)]) {
        return [(ZPImageScrollView*)scrollView imageView];
    }
    return nil;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    
}

#pragma mark - UIActionSheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (buttonTitle == ActionMenuSaveToPhotosButtonTitle) {
        ZPFileWrapper *currentPhoto = [self.imageFileWrappers objectAtIndex:self.currentIndex];
        UIImage *image = [UIImage imageWithContentsOfFile:currentPhoto.url.path];
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    } else if (buttonTitle == ActionMenuOpenInButtonTitle) {
        ZPFileWrapper *currentPhoto = [self.imageFileWrappers objectAtIndex:self.currentIndex];
        [[currentPhoto documentInteractionController] presentOpenInMenuFromRect:CGRectZero
                                                                         inView:self.view
                                                                       animated:YES];
    }
    
    self.actionSheet = nil;
}

- (void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    if (error) {
        NSLog(@"Error on saving image: %@, %@", error, [error userInfo]);
        NSString *message = NSLocalizedString(@"Error: couldn't save image to Photos",
                                              @"Error mesage shown in a temporary dialog if the app fails to save photos to the user's camera roll");
        GSSmokedInfoView *iv = [[GSSmokedInfoView alloc] initWithMessage:message andTimeout:2.0];
        [iv show];
    } else {
        NSString *message = NSLocalizedString(@"Image saved to Photos!",
                                              @"Message shown in a temporary dialog when the app has successfully saved photos to the user's camera roll");
        GSSmokedInfoView *iv = [[GSSmokedInfoView alloc] initWithMessage:message andTimeout:2.0];
        [iv show];
    }
}

#pragma mark - UI event handlers

- (void)toggleChromeVisibility {
    CGFloat alpha;
    BOOL shouldShow = self.navigationController.navigationBar.alpha < 0.05;
    BOOL statusBarWasHidden = [[UIApplication sharedApplication] isStatusBarHidden];
    
    if (!isIpad) {
        // Don't toggle status bar visibility on iPad
        [[UIApplication sharedApplication] setStatusBarHidden:!shouldShow withAnimation:UIStatusBarAnimationFade];
    }

    if (shouldShow) {
        // Make sure navigation bar is correctly placed - it will move to the top of 
        // the screen on rotation once the status bar is hidden and doesn't automatically
        // move back when the status bar reappears.
        CGSize s = [[UIApplication sharedApplication] statusBarFrame].size;
        CGFloat statusBarHeight = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? s.height : s.width;
        CGRect f = self.navigationController.navigationBar.frame;
        if (statusBarWasHidden) {
            f.origin.y = statusBarHeight;
            self.navigationController.navigationBar.frame = f;
        }
        
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
        ZPImageScrollView *currentPage = nil;
        for (ZPImageScrollView *page in self.visiblePages) {
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
    if (self.actionSheet) {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
        return;
    }
    
    ZPFileWrapper *currentPhoto = [self.imageFileWrappers objectAtIndex:self.currentIndex];
    
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self
                                           cancelButtonTitle:nil
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:ActionMenuSaveToPhotosButtonTitle, nil];


    // Determine whether we can show an Open In... menu for this image
    UIView *tempView = [[UIView alloc] init];
    CGRect frame = self.view.frame;
    frame.origin.x = frame.size.width; // draw the view off-screen
    [tempView setFrame:frame];
    BOOL hasOpenInMenu = [[currentPhoto documentInteractionController] presentOpenInMenuFromRect:CGRectZero 
                                                                                          inView:tempView
                                                                                        animated:NO];
    [[currentPhoto documentInteractionController] dismissMenuAnimated:NO];
    if (hasOpenInMenu) {
        [as addButtonWithTitle:ActionMenuOpenInButtonTitle];
    }
    
    // Add the cancel button and set its index
    [as addButtonWithTitle:ActionMenuCancelButtonTitle];
    [as setCancelButtonIndex:[as numberOfButtons] - 1];

    // Show the action sheet
    [as showFromBarButtonItem:sender animated:YES];

    self.actionSheet = as;
}

@end
