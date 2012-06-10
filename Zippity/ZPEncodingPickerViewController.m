//
//  ZPEncodingPickerViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 09/06/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPEncodingPickerViewController.h"

@interface ZPEncodingPickerViewController () {
    NSArray * _encodings;
}

@property (nonatomic, readonly) NSArray * encodings;

@end

@implementation ZPEncodingPickerViewController

@synthesize sampleFilenameCString=_sampleFilenameCString;
@synthesize delegate=_delegate;

static NSArray * allEncodings = nil;

+ (void)initialize
{
    NSString * encodingsFilePath = [[NSBundle mainBundle] pathForResource:@"character-encodings.plist" ofType:nil];
    allEncodings = [NSArray arrayWithContentsOfFile:encodingsFilePath];
}

- (NSArray*)encodings
{
    if (_encodings == nil) {
        const char * cPath = [self.sampleFilenameCString bytes];
        NSMutableArray * possibleEncodings = [NSMutableArray arrayWithCapacity:[allEncodings count]];
        for (NSDictionary *dict in allEncodings) {
            NSStringEncoding encoding = [[dict objectForKey:@"encoding"] unsignedIntegerValue];
            NSString * decodedString = [NSString stringWithCString:cPath encoding:encoding];
            if (decodedString) {
                [possibleEncodings addObject:dict];
            }
        }
        _encodings = [NSArray arrayWithArray:possibleEncodings];
    }
    return _encodings;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Choose the encoding used to encode filenames in this archive";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger result = [[self encodings] count];
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSString * filenameInEncoding = [NSString stringWithCString:[self.sampleFilenameCString bytes]
                                                       encoding:[[[self.encodings objectAtIndex:indexPath.row] valueForKey:@"encoding"] unsignedIntegerValue]];
    cell.textLabel.text = [[self.encodings objectAtIndex:indexPath.row] valueForKey:@"name"];
    cell.detailTextLabel.text = [@"Example: " stringByAppendingString:filenameInEncoding];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * dict = [self.encodings objectAtIndex:indexPath.row];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"encoding"] 
                                              forKey:kZPDefaultsLastChosenCharacterEncoding];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([self.delegate respondsToSelector:@selector(viewControllerShouldDismiss:wasCancelled:)]) {
        [self.delegate viewControllerShouldDismiss:self wasCancelled:NO];
    }
}

@end
