//
//  GSRootListViewControllerViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 19/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSRootListViewController.h"
#import "GSAppDelegate.h"

@interface GSRootListViewController ()

@end

@implementation GSRootListViewController

- (id)initWithContainer:(id<GSFileContainer>)container
{
    self = [super initWithContainer:container andSortOrder:GSFileContainerSortOrderByModifiedDateNewestFirst];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

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

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    GSFileSystemEntity *fse = [self.container.contents objectAtIndex:indexPath.row];
    GSAppDelegate *appDelegate = (GSAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (self == [appDelegate.navigationController.viewControllers objectAtIndex:0] && !fse.isVisited) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new-file-marker.png"]];
    } else {
        cell.accessoryView = nil;
    }
    
    return cell;
}

@end
