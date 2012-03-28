//
//  ZPUnrecognisedFileTypeViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 09/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPUnrecognisedFileTypeViewController.h"

@interface ZPUnrecognisedFileTypeViewController ()

- (void)handleActionButton;

@end

@implementation ZPUnrecognisedFileTypeViewController

@synthesize fileWrapper=_fileWrapper;
@synthesize filenameLabel=_filenameLabel;

- (id)initWithFileWrapper:(ZPFileWrapper*)fileWrapper
{
    self = [super initWithNibName:@"ZPUnrecognisedFileTypeViewController" bundle:nil];
    if (self) {
        self.fileWrapper = fileWrapper;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = self.fileWrapper.displayName;
    self.filenameLabel.text = self.fileWrapper.name;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(handleActionButton)];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)handleActionButton
{
    if ([self.fileWrapper.documentInteractionController presentOptionsMenuFromRect:CGRectZero
                                                                            inView:self.view
                                                                          animated:YES]) {
    }
    
}

@end
