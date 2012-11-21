//
//  DasTableViewController.h
//  dasvokalen
//
//  Created by Benjamin McGrath on 11/20/12.
//  Copyright (c) 2012 Veno Designs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PullToRefreshView.h"

@interface DasTableViewController : UIViewController <
	UITableViewDelegate,
	UITableViewDataSource,
	NSFetchedResultsControllerDelegate,
	PullToRefreshViewDelegate
> {}

@property (nonatomic, retain) PullToRefreshView *pull;
@property (nonatomic, retain) UITableView *dasTableView;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) BOOL isUpdatingFromCoreData;
@property (nonatomic) BOOL hasSynced;

-(void)foregroundRefresh:(NSNotification *)notification;
- (void)managedObjectContextDidSave:(NSNotification *)notification;
- (NSManagedObjectContext*)createNewManagedObjectContext;
- (void)layoutCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end
