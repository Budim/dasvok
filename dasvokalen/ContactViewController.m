//
//  ContactViewController.m
//  dasvokalen
//
//  Created by Benjamin McGrath on 11/21/12.
//  Copyright (c) 2012 Veno Designs. All rights reserved.
//

#import "ContactViewController.h"
#import "UIImageView+AFNetworking.h"

@implementation ContactViewController

@synthesize name = _name;
@synthesize email = _email;
@synthesize avatar_url = _avatar_url;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/**
 *	Real quick
 */
- (void)viewDidAppear:(BOOL)animated
{
    /**
     *	Rotation not here
     */
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 300.0f, 40.0f)];
	nameLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    nameLabel.text = _name;
    [self.view addSubview:nameLabel];
    
    UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 60.0f, 300.0f, 40.0f)];
	emailLabel.font = [UIFont systemFontOfSize:12.0f];
    emailLabel.text = _email;
    [self.view addSubview:emailLabel];
    
    UIImageView *photo = [[UIImageView alloc] initWithFrame:CGRectMake(120.0f, 300.0f, 44.0f, 44.0f)];
    [photo setImageWithURL:[NSURL URLWithString:_avatar_url] placeholderImage:[UIImage imageNamed:@"placeholder"]];
    [self.view addSubview:photo];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
