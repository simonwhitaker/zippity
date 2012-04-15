//
//  ZPEmptyViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 15/04/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPEmptyViewController.h"

@interface ZPEmptyViewController ()

@end

@implementation ZPEmptyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
