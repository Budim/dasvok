//
//  Contact.h
//  dasvokalen
//
//  Created by Benjamin McGrath on 11/20/12.
//  Copyright (c) 2012 Veno Designs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Contact : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *avatar_url;

@end
