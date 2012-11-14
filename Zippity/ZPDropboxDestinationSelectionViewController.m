//
//  ZPDropboxDestinationSelectionViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 06/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPDropboxDestinationSelectionViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface ZPDropboxDestinationSelectionViewController () <DBRestClientDelegate>
@property (nonatomic) BOOL isLoading;
@property (nonatomic, strong) NSArray *subdirectories;
@property (nonatomic, strong) DBRestClient *dropboxClient;

- (void)handleCancel;
- (void)handleSelectDestination;

@end

@implementation ZPDropboxDestinationSelectionViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _isLoading = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(handleCancel)];
    
    self.toolbarItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:@"Choose" style:UIBarButtonItemStyleDone target:self action:@selector(handleSelectDestination)]
    ];
    
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.rootPath isEqualToString:@"/"]) {
        self.title = @"Dropbox";
    } else {
        self.title = [self.rootPath lastPathComponent];
    }
    self.navigationItem.prompt = @"Choose a directory";
    self.isLoading = YES;
    [self.dropboxClient loadMetadata:self.rootPath];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (DBRestClient *)dropboxClient
{
    if (_dropboxClient == nil && [DBSession sharedSession] != nil) {
        _dropboxClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _dropboxClient.delegate = self;
    }
    return _dropboxClient;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isLoading || self.subdirectories == nil || [self.subdirectories count] == 0) {
        return 1;
    }
    return [self.subdirectories count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (self.isLoading) {
        /* TODO: internationalise */
        cell.textLabel.text = @"Loading...";
    } else if (self.subdirectories == nil) {
        cell.textLabel.text = @"Error loading subdirectories";
    } else if ([self.subdirectories count] == 0) {
        cell.textLabel.text = @"No subdirectories";
    } else {
        cell.textLabel.text = [[self.subdirectories objectAtIndex:indexPath.row] lastPathComponent];
        cell.imageView.image = [UIImage imageNamed:@"folder-icon.png"];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.subdirectories count] > indexPath.row) {
        ZPDropboxDestinationSelectionViewController *vc = [[ZPDropboxDestinationSelectionViewController alloc] init];
        vc.delegate = self.delegate;
        vc.rootPath = [self.rootPath stringByAppendingPathComponent:[self.subdirectories objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Dropbox client delegate methods

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    NSMutableArray *array = [NSMutableArray array];
    for (DBMetadata *file in metadata.contents) {
        if (file.isDirectory && [file.filename length] > 0 && [file.filename characterAtIndex:0] != '.') {
            [array addObject:file.filename];
        }
    }
    self.subdirectories = [array sortedArrayUsingSelector:@selector(compare:)];
    self.isLoading = NO;
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    self.isLoading = NO;
}

- (void)setIsLoading:(BOOL)isLoading
{
    if (_isLoading != isLoading) {
        _isLoading = isLoading;
        [self.tableView reloadData];
    }
}

- (void)handleCancel
{
    if ([self.delegate respondsToSelector:@selector(dropboxDestinationSelectionViewControllerDidCancel:)]) {
        [self.delegate dropboxDestinationSelectionViewControllerDidCancel:self];
    }
}

- (void)handleSelectDestination
{
    if ([self.delegate respondsToSelector:@selector(dropboxDestinationSelectionViewController:didSelectDestinationPath:)]) {
        [self.delegate dropboxDestinationSelectionViewController:self
                                        didSelectDestinationPath:self.rootPath];
    }
}

@end
