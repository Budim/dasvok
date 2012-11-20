//
//  DKAppDelegate.h
//  dasvokalen
//
//  Created by Benjamin McGrath on 11/20/12.
//  Copyright (c) 2012 Veno Designs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
