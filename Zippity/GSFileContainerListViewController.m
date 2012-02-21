//
//  GSFileListViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFileContainerListViewController.h"
#import "GSAppDelegate.h"
#import <QuickLook/QuickLook.h>

@interface GSFileContainerListViewController()

- (void)handleContentsReloaded:(NSNotification*)notification;
- (void)handleContentsFailedToReload:(NSNotification*)notification;

@end

@implementation GSFileContainerListViewController

@synthesize container=_container;
//@synthesize sortOrder=_sortOrder;

- (id)initWithContainer:(GSFileWrapper*)container
{
    return [self initWithContainer:container andSortOrder:0];
}

- (id)initWithContainer:(GSFileWrapper*)container andSortOrder:(NSInteger)sortOrder
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.container = container;
//        self.sortOrder = sortOrder;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Custom accessors
//- (void)setSortOrder:(GSFileContainerSortOrder)sortOrder
//{
//    self.container.sortOrder = sortOrder;
//}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleZipFileArrivedNotification:) 
//                                                 name:GSAppReceivedZipFileNotification
//                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:GSAppReceivedZipFileNotification
//                                                  object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.container.fileWrappers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
    cell.textLabel.text = wrapper.name;
    cell.detailTextLabel.text = wrapper.subtitle;
    cell.imageView.image = wrapper.icon;
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}



#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
    // [wrapper markVisited];
    
    if (wrapper.isContainer) {
        GSFileContainerListViewController *vc = [[GSFileContainerListViewController alloc] initWithContainer:wrapper];
        vc.tableView.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (wrapper.documentInteractionController && [QLPreviewController canPreviewItem:wrapper.url]) {
        wrapper.documentInteractionController.delegate = self;
        [wrapper.documentInteractionController presentPreviewAnimated:YES];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Not yet!"
                                                      message:@"Zippity doesn't recognise this file type yet. Please try again after the next release."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
        [av show];
    }
}

- (void)setContainer:(GSFileWrapper*)container
{
    if (_container != container) {
        // Remove old notification observers
        if (_container) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:GSFileWrapperContainerDidReloadContents
                                                          object:_container];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:GSFileWrapperContainerDidFailToReloadContents
                                                          object:_container];
        }
        
        // Switch container ivar to new container
        _container = container;

        // Set up new notification observers
        if (_container) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleContentsReloaded:)
                                                         name:GSFileWrapperContainerDidReloadContents
                                                       object:_container];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleContentsFailedToReload:)
                                                         name:GSFileWrapperContainerDidFailToReloadContents
                                                       object:_container];
            self.title = container.name;
        }
    }
}

#pragma mark - UIDocumentInteractionController delegate

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.navigationController;
}

#pragma mark - notification handlers

- (void)handleContentsReloaded:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)handleContentsFailedToReload:(NSNotification *)notification
{
    NSLog(@"Contents failed to reload");
    // TODO: show error to user
}

@end
