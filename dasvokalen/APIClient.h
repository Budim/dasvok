//
//  APIClient.h
//  dasvokalen
//
//  Created by Benjamin McGrath on 11/21/12.
//  Copyright (c) 2012 Veno Designs. All rights reserved.
//

#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

@interface APIClient : AFHTTPClient

+ (APIClient *)sharedClient;

@end
