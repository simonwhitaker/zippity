//
//  GSFileListViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFileContainerListViewController.h"
#import "GSZipFile.h"
#import "GSAppDelegate.h"
#import <QuickLook/QuickLook.h>

@interface GSFileContainerListViewController()

- (void)handleZipFileArrivedNotification:(NSNotification*)notification;

@end

@implementation GSFileContainerListViewController

@synthesize container=_container;
@synthesize sortOrder=_sortOrder;

- (id)initWithContainer:(id<GSFileContainer>)container
{
    return [self initWithContainer:container andSortOrder:GSFileContainerSortOrderDefault];
}

- (id)initWithContainer:(id<GSFileContainer>)container andSortOrder:(GSFileContainerSortOrder)sortOrder
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.container = container;
        self.sortOrder = sortOrder;
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
- (void)setSortOrder:(GSFileContainerSortOrder)sortOrder
{
    self.container.sortOrder = sortOrder;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleZipFileArrivedNotification:) 
                                                 name:GSAppReceivedZipFileNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:GSAppReceivedZipFileNotification
                                                  object:nil];
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
    return self.container.contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    GSFileSystemEntity *file = [self.container.contents objectAtIndex:indexPath.row];
    cell.textLabel.text = file.name;
    cell.detailTextLabel.text = file.subtitle;
    cell.imageView.image = file.icon;
    
    GSAppDelegate *appDelegate = (GSAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (self == [appDelegate.navigationController.viewControllers objectAtIndex:0] && !file.isVisited) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new-file-marker.png"]];
    } else {
        cell.accessoryView = nil;
    }

    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        GSFileSystemEntity *fse = [self.container.contents objectAtIndex:indexPath.row];
        NSError *error = nil;
        [fse remove:&error];
        if (error) {
            NSLog(@"Error on deleting file system entity (%@): %@, %@", fse.path, error, error.userInfo);
        }
        [self.container invalidateContents];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    GSFileSystemEntity *file = [self.container.contents objectAtIndex:indexPath.row];

    if (file.isVisited) {
        cell.accessoryView = nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GSFileSystemEntity *fse = [self.container.contents objectAtIndex:indexPath.row];
    [fse markVisited];
    
    if ([fse respondsToSelector:@selector(contents)]) {
        GSFileContainerListViewController *vc = [[GSFileContainerListViewController alloc] initWithContainer:(id<GSFileContainer>)fse];
        vc.tableView.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (fse.documentInteractionController && [QLPreviewController canPreviewItem:fse.documentInteractionController.URL]) {
        fse.documentInteractionController.delegate = self;
        [fse.documentInteractionController presentPreviewAnimated:YES];
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Not yet!"
                                                      message:@"Zippity doesn't recognise this file type yet. Please try again after the next release."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
        [av show];
    }
}

- (void)setContainer:(id<GSFileContainer>)container
{
    if (_container != container) {
        _container = container;
        self.title = [(GSFileSystemEntity*)_container name];
    }
}

#pragma mark - UIDocumentInteractionController delegate

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.navigationController;
}

#pragma mark - notification handlers

- (void)handleZipFileArrivedNotification:(NSNotification *)notification
{
    NSString *zipFileDirectory = [[notification.userInfo objectForKey:kGSZipFilePathKey] stringByDeletingLastPathComponent];
    if ([zipFileDirectory isEqualToString:[(GSFileSystemEntity*)self.container path]]) {
        id<GSFileContainer> container = (id<GSFileContainer>)self.container;
        [container invalidateContents];
        [self.tableView reloadData];
    }
}

@end
