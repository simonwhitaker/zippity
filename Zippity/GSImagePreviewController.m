//
//  GSImagePreviewController.m
//  Zippity
//
//  Created by Simon Whitaker on 25/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSImagePreviewController.h"

@interface GSImagePreviewController ()

@property (nonatomic) NSUInteger currentPage;
@property (nonatomic) NSRange loadedPagesRange;

- (void)loadImageForPage:(NSUInteger)page;
- (void)handleActionButton:(id)sender;

@end

@implementation GSImagePreviewController

@synthesize imageFileWrappers=_imageFileWrappers;
@synthesize initialIndex=_initialIndex;
@synthesize scrollView=_scrollView;
@synthesize currentPage=_currentPage;
@synthesize loadedPagesRange=_loadedPagesRange;

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.wantsFullScreenLayout = YES;
        self.loadedPagesRange = NSMakeRange(NSNotFound, 0);
        _currentPage = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad
{
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleChromeVisibility)];
    [self.scrollView addGestureRecognizer:gr];
    
    self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                               target:self
                                                                                               action:@selector(handleActionButton:)]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController setToolbarHidden:NO animated:animated];
    
    self.currentPage = self.initialIndex;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.imageFileWrappers.count, self.scrollView.frame.size.height);
    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.currentPage, 0);
    
    [self loadImageForPage:self.currentPage];
    if (self.currentPage > 0) [self loadImageForPage:self.currentPage - 1];
    if (self.currentPage < self.imageFileWrappers.count - 1) [self loadImageForPage:self.currentPage + 1];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark - Interface orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.imageFileWrappers.count, 
                                             self.scrollView.frame.size.height);
    for (UIView *v in self.scrollView.subviews) {
        NSUInteger thisPage = v.tag;
        v.frame = CGRectMake(self.scrollView.frame.size.width * thisPage,
                             0,
                             self.scrollView.frame.size.width,
                             self.scrollView.frame.size.height);
    }
    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.currentPage, 0);
}

#pragma mark - Utility methods

- (void)loadImageForPage:(NSUInteger)page
{
    if (NSLocationInRange(page, self.loadedPagesRange)) {
        // We've already loaded this image
        return;
    }
    GSFileWrapper *imageFileWrapper = [self.imageFileWrappers objectAtIndex:page];
    UIImage *image = [UIImage imageWithContentsOfFile:imageFileWrapper.url.path];
    UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    iv.tag = page;
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = frame.size.width * page;
    iv.frame = frame;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:iv];
    
    if (self.loadedPagesRange.location == NSNotFound) {
        self.loadedPagesRange = NSMakeRange(page, 1);
    } else if (page < self.loadedPagesRange.location) {
        NSRange temp = self.loadedPagesRange;
        NSUInteger diff = temp.location - page;
        temp.location = page;
        temp.length += diff;
        self.loadedPagesRange = temp;
    } else if (page >= NSMaxRange(self.loadedPagesRange)) {
        NSRange temp = self.loadedPagesRange;
        temp.length = page - temp.location + 1;
        self.loadedPagesRange = temp;
    }
}

#pragma mark - Custom accessors

- (void)setCurrentPage:(NSUInteger)currentPage
{
    if (currentPage != _currentPage) {
        _currentPage = currentPage;
        self.title = [NSString stringWithFormat:@"%u of %u", _currentPage + 1, self.imageFileWrappers.count];
    }
}

#pragma mark - UIScrollView delegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Update the current page value
    NSUInteger previousPage = self.currentPage;
    self.currentPage = (NSUInteger)roundf(scrollView.contentOffset.x / scrollView.frame.size.width);
    
    // Check which way we've scrolled and pre-load the next image 
    // in that direction, if there is one
    if (self.currentPage < previousPage && self.currentPage > 0) {
        [self loadImageForPage:self.currentPage - 1];
    } else if (self.currentPage > previousPage && self.currentPage < self.imageFileWrappers.count - 1) {
        [self loadImageForPage:self.currentPage + 1];
    }
}

#pragma mark - UIActionSheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Save image"]) {
        GSFileWrapper *currentPhoto = [self.imageFileWrappers objectAtIndex:self.currentPage];
        UIImage *image = [UIImage imageWithContentsOfFile:currentPhoto.url.path];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
}

#pragma mark - UI event handlers

- (void)toggleChromeVisibility {
    CGFloat alpha;
    if (self.navigationController.navigationBar.alpha < 0.05) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        alpha = 1.0;
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        alpha = 0.0;
    }
    
    [UIView animateWithDuration:0.35 animations:^{
        self.navigationController.navigationBar.alpha = alpha;
    }];
}

- (void)handleActionButton:(id)sender
{
    GSFileWrapper *currentPhoto = [self.imageFileWrappers objectAtIndex:self.currentPage];
    NSString *actionSheetTitle = [NSString stringWithFormat:@"Share %@", currentPhoto.name];
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:actionSheetTitle
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Save image", nil];
    [as showFromToolbar:self.navigationController.toolbar];
}

@end
