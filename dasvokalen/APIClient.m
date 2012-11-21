//
//  APIClient.m
//  dasvokalen
//
//  Created by Benjamin McGrath on 11/21/12.
//  Copyright (c) 2012 Veno Designs. All rights reserved.
//

#import "APIClient.h"

@implementation APIClient

NSString *const kAPIBaseURLString = @"http://vokal-dev-test.herokuapp.com/";

+ (APIClient *)sharedClient {
    static APIClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:kAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if(!self) return nil;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    //[self setParameterEncoding:AFJSONParameterEncoding];
    
    return self;
}

@end
