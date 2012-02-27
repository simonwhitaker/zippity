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

@property (nonatomic) NSUInteger currentPage;
@property (nonatomic, retain) NSMutableDictionary * loadedPages;

- (void)loadPage:(NSUInteger)page;
- (void)unloadPage:(NSUInteger)page;

- (void)handleActionButton:(id)sender;
- (void)updateLayout;
- (CGRect)frameForPage:(NSUInteger)page;

@end

@implementation GSImagePreviewController

@synthesize imageFileWrappers=_imageFileWrappers;
@synthesize initialIndex=_initialIndex;
@synthesize scrollView=_scrollView;
@synthesize currentPage=_currentPage;
@synthesize loadedPages=_loadedPages;

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.wantsFullScreenLayout = YES;
        self.loadedPages = [NSMutableDictionary dictionary];
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
    
    [self loadPage:self.currentPage];
    if (self.currentPage > 0) [self loadPage:self.currentPage - 1];
    if (self.currentPage < self.imageFileWrappers.count - 1) [self loadPage:self.currentPage + 1];

    [self updateLayout];
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

- (CGRect)frameForPage:(NSUInteger)page
{
    CGRect f = self.view.bounds;
    f.origin.x = self.scrollView.bounds.size.width * page + kPagePaddingWidth;
    return f;
}

#pragma mark - Interface orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateLayout];
}

- (void)updateLayout {
    CGRect f = self.view.bounds;
    f.origin.x -= kPagePaddingWidth;
    f.size.width += kPagePaddingWidth * 2;
    self.scrollView.frame = f;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.imageFileWrappers.count, 
                                             self.scrollView.frame.size.height);
    for (NSNumber *pageKey in self.loadedPages) {
        GSImageScrollView *isv = [self.loadedPages objectForKey:pageKey];
        isv.frame = [self frameForPage:pageKey.unsignedIntegerValue];
    }
    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.currentPage, 0);
}

#pragma mark - Utility methods

- (void)loadPage:(NSUInteger)page
{
    NSNumber * pageKey = [NSNumber numberWithUnsignedInteger:page];
    if ([self.loadedPages objectForKey:pageKey]) {
        // We've already loaded this page
        NSLog(@"We've already loaded page %u", page);
        return;
    }
    
    NSLog(@"Loading page %u", page);
    GSFileWrapper *imageFileWrapper = [self.imageFileWrappers objectAtIndex:page];
    UIImage *image = [UIImage imageWithContentsOfFile:imageFileWrapper.url.path];
    UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    
    GSImageScrollView *isv = [[GSImageScrollView alloc] initWithFrame:[self frameForPage:page]];
    isv.imageView = iv;
    isv.delegate = self;
    
    [self.scrollView addSubview:isv];
    [self.loadedPages setObject:isv forKey:pageKey];
}

- (void)unloadPage:(NSUInteger)page
{
    NSNumber * pageKey = [NSNumber numberWithUnsignedInteger:page];
    GSImageScrollView *isv = [self.loadedPages objectForKey:pageKey];
    
    if (isv) {
        NSLog(@"Removing page %u", page);
        [isv removeFromSuperview];
        [self.loadedPages removeObjectForKey:pageKey];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        // Update the current page value
        NSUInteger previousPage = self.currentPage;
        self.currentPage = (NSUInteger)roundf(scrollView.contentOffset.x / scrollView.frame.size.width);
        
        // Check which way we've scrolled and pre-load the next image 
        // in that direction, if there is one
        if (self.currentPage < previousPage && self.currentPage > 0) {
            [self loadPage:self.currentPage - 1];
            [self unloadPage:self.currentPage + 2];
        } else if (self.currentPage > previousPage && self.currentPage < self.imageFileWrappers.count - 1) {
            [self loadPage:self.currentPage + 1];
            [self unloadPage:self.currentPage - 2];
        }
        
        // Reset the zoom factor for the previous page
        GSImageScrollView *isv = [self.loadedPages objectForKey:[NSNumber numberWithUnsignedInteger:previousPage]];
        [isv setZoomScale:1.0];
    }
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
        self.navigationController.toolbar.alpha = alpha;
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
