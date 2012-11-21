//
//  DasTableViewController.m
//  dasvokalen
//
//  Created by Benjamin McGrath on 11/20/12.
//  Copyright (c) 2012 Veno Designs. All rights reserved.
//

#import "DasTableViewController.h"
#import "DKAppDelegate.h"
#import "UIImageView+AFNetworking.h"
#import "Contact.h"
#import "APIClient.h"
#import "ContactViewController.h"

@implementation DasTableViewController

#pragma mark - Alchemy
@synthesize isUpdatingFromCoreData = _isUpdatingFromCoreData;
@synthesize dasTableView = _dasTableView;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize pull = _pull;
@synthesize hasSynced = _hasSynced;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Main useful methods
- (id)init
{
    self = [super init];
    if(self) {
		_isUpdatingFromCoreData = NO;
        _hasSynced = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Some People", nil);
	_dasTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _dasTableView.dataSource = self;
    _dasTableView.delegate = self;
    _dasTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _dasTableView.backgroundColor = [UIColor clearColor];

    _pull = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *)_dasTableView];
	_pull.delegate = self;
    [_dasTableView addSubview:_pull];
    [self.view addSubview:_dasTableView];
        
    [[NSNotificationCenter defaultCenter] addObserver:self 
    	selector:@selector(managedObjectContextDidSave:)
        name:NSManagedObjectContextDidSaveNotification 
        object:nil
    ];
    
    [[NSNotificationCenter defaultCenter]
		addObserver:self 
        selector:@selector(foregroundRefresh:) 
        name:UIApplicationWillEnterForegroundNotification
        object:nil
    ];
    
    [[APIClient sharedClient] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if(status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
            if(!_hasSynced) {
        		[self pullToRefreshViewShouldRefresh:_pull];
            }
        }
    }];
        
    NSError *error;
	if(![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Something done screwed up in Core Data: %@ | %@", error, [error userInfo]);
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self performSelectorInBackground:@selector(pullToRefreshViewShouldRefresh:) withObject:_pull];
    [self pullToRefreshViewShouldRefresh:_pull];
	if(_dasTableView.frame.size.height == 0.0f) {
        _dasTableView.frame = [self.view bounds];
    }
}

/**
 *	Could possible refresh everything when the app comes alive,
 *	but seeing as this feels like a contacts list/address book I'm
 *	not entirely sure that's prudent...?
 */
-(void)foregroundRefresh:(NSNotification *)notification { 
    _dasTableView.contentOffset = CGPointMake(0, -65); 
    [_pull setState:PullToRefreshViewStateLoading];
    [self performSelectorInBackground:@selector(pullToRefreshViewShouldRefresh:) withObject:_pull]; 
}

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view
{    
    [[APIClient sharedClient] getPath:@"api/members" parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSManagedObjectContext *context = [self createNewManagedObjectContext];
        NSArray *currentData = [_fetchedResultsController fetchedObjects];
        	
        // I'm not a huge fan of this, but it works for now
        NSString *name;
        BOOL isExistingContact = NO;
        for(NSDictionary *person in JSON) {
            name = [person objectForKey:@"name"];
            
            /**
             *	Yes, this would be a problem if a user's name was typo'd/changed/etc.
             *	Ordinarily I would tie this to a user ID or something, but the returned JSON
             *	does not have that, so... we get this inaccurate-ish routine.
             */
            for(Contact *contact in currentData) {
                if([contact.name isEqualToString:name]) {
                    contact.name = [person objectForKey:@"name"];
                    contact.email = [person objectForKey:@"email"];
                    contact.avatar_url = [person objectForKey:@"avatar_url"];
                    isExistingContact = YES;
                    break;
                }
            }
            
            if(!isExistingContact) {
                Contact *newContact = [NSEntityDescription 
                                       insertNewObjectForEntityForName:@"Contact" 
                                       inManagedObjectContext:context
                                       ];
                newContact.name = [person objectForKey:@"name"];
                newContact.email = [person objectForKey:@"email"];
                newContact.avatar_url = [person objectForKey:@"avatar_url"];
            }
            
            isExistingContact = NO;
        }
        
        NSError *error;
        if(![context save:&error]) {
            NSLog(@"Contacts could not be saved and/or updated: %@", [error localizedDescription]);
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
			_hasSynced = YES;
            [_pull finishedLoading];
        });        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_pull finishedLoading];
            
            NSString *msg = NSLocalizedString(@"There was an unknown error.", nil);
			if([APIClient sharedClient].networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable) {
                msg = NSLocalizedString(@"Please check to make sure you have a network connection.", nil);
            }
            
            UIAlertView *alert = [[UIAlertView alloc] 
                initWithTitle:@"Sorry!" 
                message:msg
                delegate:self 
                cancelButtonTitle:@"Okay" 
                otherButtonTitles:nil, 
                nil
            ];
            [alert show];
        });

    }];	
}

#pragma mark - Das Table Viewen Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { 
	return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [_fetchedResultsController sections];
    id sectionInfo = [sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)layoutCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = [_fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = contact.name;
	cell.detailTextLabel.text = contact.email;
    
    NSString *avatar_url = [contact valueForKey:@"avatar_url"];
    [cell.imageView setImageWithURL:[NSURL URLWithString:avatar_url] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactTableViewCell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ContactTableViewCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
  
    [self layoutCell:cell atIndexPath:indexPath];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[_dasTableView deselectRowAtIndexPath:indexPath animated:YES];

    ContactViewController *vc = [[ContactViewController alloc] init];
    Contact *contact = [_fetchedResultsController objectAtIndexPath:indexPath];
    // Alternatively set a dictionary here I guess
	vc.name = [NSString stringWithFormat:@"%@", contact.name];
    vc.email = [NSString stringWithFormat:@"%@", contact.email];
    vc.avatar_url = [NSString stringWithFormat:@"%@", contact.avatar_url];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Those standard methods that everyone hates implementing
- (void)viewDidUnload
{
    [super viewDidUnload];
    self.fetchedResultsController = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.fetchedResultsController = nil;    
}

#pragma mark - NSFetchedResults Delegate And ObjectContext Methods
- (void)managedObjectContextDidSave:(NSNotification *)notification
{
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:); 
    [_managedObjectContext performSelectorOnMainThread:selector withObject:notification waitUntilDone:YES];
}

- (NSManagedObjectContext*)createNewManagedObjectContext
{
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init]; 
	[moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [moc setPersistentStoreCoordinator:_persistentStoreCoordinator];
//    [_managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
    [moc setUndoManager:nil];
    return moc;
}

- (NSFetchedResultsController *)fetchedResultsController 
{    
    if(_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    //[fetchRequest setFetchBatchSize:20000000000000000000000000000000000000000nope];

    _fetchedResultsController = [[NSFetchedResultsController alloc] 
        initWithFetchRequest:fetchRequest  
        managedObjectContext:_managedObjectContext 
        sectionNameKeyPath:nil
        cacheName:@"ContactsCache"
    ];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller 
{
    if(_isUpdatingFromCoreData) return;
    [_dasTableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
    if(_isUpdatingFromCoreData) return;    
    [_dasTableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller 
	didChangeObject:(id)anObject 
    atIndexPath:(NSIndexPath *)indexPath 
    forChangeType:(NSFetchedResultsChangeType)type 
    newIndexPath:(NSIndexPath *)newIndexPath 
{
    switch(type) {            
        case NSFetchedResultsChangeInsert:
            [_dasTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_dasTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self layoutCell:[_dasTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [_dasTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [_dasTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller 
  	didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
	atIndex:(NSUInteger)sectionIndex 
    forChangeType:(NSFetchedResultsChangeType)type 
{    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [_dasTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [_dasTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

@end
