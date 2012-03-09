//
//  GSUnrecognisedFileTypeViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 09/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSUnrecognisedFileTypeViewController.h"

@interface GSUnrecognisedFileTypeViewController ()

- (void)handleActionButton;

@end

@implementation GSUnrecognisedFileTypeViewController

@synthesize fileWrapper=_fileWrapper;
@synthesize filenameLabel=_filenameLabel;

- (id)initWithFileWrapper:(GSFileWrapper*)fileWrapper
{
    self = [super initWithNibName:@"GSUnrecognisedFileTypeViewController" bundle:nil];
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
        NSLog(@"Showed options menu");
    } else {
        NSLog(@"Didn't show options menu");
    }
    
}

@end
