/*
 * Copyright 2012 MyHeritage, Ltd.
 *
 * The Family Graph SDK is based on the Facebook iOS SDK:
 * Copyright 2011 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#import "RootViewController.h"
#import "FGSampleAppDelegate.h"
#import "FamilyGraphHeaders.h"
#import "APICallsViewController.h"

@implementation RootViewController

@synthesize permissions;
@synthesize backgroundImageView;
@synthesize menuTableView;
@synthesize mainMenuItems;
@synthesize headerView;
@synthesize nameLabel;
@synthesize profilePhotoImageView;

- (void)dealloc {
    [permissions release];
    [backgroundImageView release];
    [loginButton release];
    [menuTableView release];
    [mainMenuItems release];
    [headerView release];
    [nameLabel release];
    [profilePhotoImageView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - FamilyGraph API Calls

- (void)apiGraphUserPermissions {
    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate familyGraph] requestWithGraphPath:@"me/permissions" andDelegate:self];
}


#pragma - Private Helper Methods

/**
 * Show the logged in menu
 */

- (void)showLoggedIn {
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    self.backgroundImageView.hidden = YES;
    loginButton.hidden = YES;
    self.menuTableView.hidden = NO;
}

/**
 * Show the logged in menu
 */

- (void)showLoggedOut {
    [self.navigationController setNavigationBarHidden:YES animated:NO];

    self.menuTableView.hidden = YES;
    self.backgroundImageView.hidden = NO;
    loginButton.hidden = NO;

    // Clear personal info
    nameLabel.text = @"";
    // Get the profile image
    [profilePhotoImageView setImage:nil];
    
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

/**
 * Show the authorization dialog.
 */
- (void)login {
    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![[delegate familyGraph] isSessionValid]) {
        [[delegate familyGraph] authorize:permissions];
    } else {
        [self showLoggedIn];
    }
}

/**
 * Invalidate the access token and clear the cookie.
 */
- (void)logout {
    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate familyGraph] logout];
}

/**
 * Helper method called when a menu button is clicked
 */
- (void)menuButtonClicked:(id)sender {
    // Each menu button in the UITableViewController is initialized
    // with a tag representing the table cell row. When the button
    // is clicked the button is passed along in the sender object.
    // From this object we can then read the tag property to determine
    // which menu button was clicked.
    APICallsViewController *controller = [[APICallsViewController alloc]
                                       initWithIndex:[sender tag]];
    pendingApiCallsController = controller;
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

#pragma mark - View lifecycle
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen
                                                  mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;
    [view release];

    // Initialize permissions
    permissions = [[NSArray alloc] initWithObjects:@"offline_access", nil];

    // Main menu items
    mainMenuItems = [[NSMutableArray alloc] initWithCapacity:1];
    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *apiInfo = [[delegate apiData] apiConfigData];
    for (NSUInteger i=0; i < [apiInfo count]; i++) {
        [mainMenuItems addObject:[[apiInfo objectAtIndex:i] objectForKey:@"title"]];
    }

    // Set up the view programmatically
    self.view.backgroundColor = [UIColor whiteColor];

    self.navigationItem.title = @"FamilyGraph for iOS";

    self.navigationItem.backBarButtonItem =
    [[[UIBarButtonItem alloc] initWithTitle:@"Back"
                                      style:UIBarButtonItemStyleBordered
                                     target:nil
                                     action:nil] autorelease];

    // Background Image
    backgroundImageView = [[UIImageView alloc]
                          initWithFrame:CGRectMake(0,0,
                                                   self.view.bounds.size.width,
                                                   self.view.bounds.size.height)];
    //[backgroundImageView setImage:[UIImage imageNamed:@"Default.png"]];
    //[backgroundImageView setAlpha:0.25];
    [self.view addSubview:backgroundImageView];

    // Login Button
    loginButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    CGFloat xLoginButtonOffset = self.view.bounds.size.width/2 - (180/2);
    CGFloat yLoginButtonOffset = 13;
    loginButton.frame = CGRectMake(xLoginButtonOffset,yLoginButtonOffset,180,58);
    [loginButton addTarget:self
                    action:@selector(login)
          forControlEvents:UIControlEventTouchUpInside];
    [loginButton setTitle:@"Login to FamilyGraph" 
                 forState:UIControlStateNormal];
    [loginButton sizeToFit];
    
    [self.view addSubview:loginButton];

    // Main Menu Table
    menuTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                 style:UITableViewStylePlain];
    [menuTableView setBackgroundColor:[UIColor whiteColor]];
    menuTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    menuTableView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    menuTableView.dataSource = self;
    menuTableView.delegate = self;
    menuTableView.hidden = YES;
    
    // Table header
    headerView = [[UIView alloc]
                  initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    headerView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    headerView.backgroundColor = [UIColor whiteColor];
    CGFloat xProfilePhotoOffset = self.view.center.x - 25.0;
    profilePhotoImageView = [[UIImageView alloc]
                             initWithFrame:CGRectMake(xProfilePhotoOffset, 20, 50, 50)];
    profilePhotoImageView.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [headerView addSubview:profilePhotoImageView];
    nameLabel = [[UILabel alloc]
                 initWithFrame:CGRectMake(0, 75, self.view.bounds.size.width, 20.0)];
    nameLabel.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    nameLabel.textAlignment = UITextAlignmentCenter;
    nameLabel.text = @"";
    [headerView addSubview:nameLabel];
    menuTableView.tableHeaderView = headerView;

    [self.view addSubview:menuTableView];

    pendingApiCallsController = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];

    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    // Check and retrieve authorization information
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FGAccessTokenKey"]
        && [defaults objectForKey:@"FGExpirationDateKey"]) {
        [delegate familyGraph].accessToken = [defaults objectForKey:@"FGAccessTokenKey"];
        [delegate familyGraph].expirationDate = [defaults objectForKey:@"FGExpirationDateKey"];
    }
    if (![[delegate familyGraph] isSessionValid]) {
        [self showLoggedOut];
    } else {
        [self showLoggedIn];
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - UITableViewDatasource and UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [mainMenuItems count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    //create the button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(20, 20, (cell.contentView.frame.size.width-40), 44);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    [button setBackgroundImage:[[UIImage imageNamed:@"MenuButton.png"]
                                stretchableImageWithLeftCapWidth:9 topCapHeight:9]
                      forState:UIControlStateNormal];
    [button setTitle:[mainMenuItems objectAtIndex:indexPath.row]
            forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(menuButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = indexPath.row;
    [cell.contentView addSubview:button];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - FGSessionDelegate Methods
/**
 * Called when the user has logged in successfully.
 */
- (void)fgDidLogin {
    [self showLoggedIn];

    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

    // Save authorization information
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[[delegate familyGraph] accessToken] forKey:@"FGAccessTokenKey"];
    [defaults setObject:[[delegate familyGraph] expirationDate] forKey:@"FGExpirationDateKey"];
    [defaults synchronize];
    
    //[pendingApiCallsController userDidGrantPermission];
}

/**
 * Called when the user canceled the authorization dialog.
 */
-(void)fgDidNotLogin:(BOOL)cancelled {
    //[pendingApiCallsController userDidNotGrantPermission];
}

/**
 * Called when the request logout has succeeded.
 */
- (void)fgDidLogout {
    pendingApiCallsController = nil;

    // Remove saved authorization information if it exists and it is
    // ok to clear it (logout, session invalid, app unauthorized)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"FGAccessTokenKey"];
    [defaults removeObjectForKey:@"FGExpirationDateKey"];
    [defaults synchronize];

    [self showLoggedOut];
}

/**
 * Called when the session has expired.
 */
- (void)fgSessionInvalidated {   
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Auth Exception" 
                              message:@"Your session has expired." 
                              delegate:nil 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil, 
                              nil];
    [alertView show];
    [alertView release];
    [self fgDidLogout];
}

#pragma mark - FGRequestDelegate Methods
/**
 * Called when the FamilyGraph API request has returned a response. This callback
 * gives you access to the raw response. It's called before
 * (void)request:(FGRequest *)request didLoad:(id)result,
 * which is passed the parsed response object.
 */
- (void)request:(FGRequest *)request didReceiveResponse:(NSURLResponse *)response {
    //NSLog(@"received response");
}

/**
 * Called when a request returns and its response has been parsed into
 * an object. The resulting object may be a dictionary, an array, a string,
 * or a number, depending on the format of the API response. If you need access
 * to the raw response, use:
 *
 * (void)request:(FGRequest *)request
 *      didReceiveResponse:(NSURLResponse *)response
 */
- (void)request:(FGRequest *)request didLoad:(id)result {
    if ([result isKindOfClass:[NSArray class]]) {
        result = [result objectAtIndex:0];
    }
    // This callback can be a result of getting the user's basic
    // information or getting the user's permissions.
    if ([result objectForKey:@"name"]) {
        // If basic information callback, set the UI objects to
        // display this.
        nameLabel.text = [result objectForKey:@"name"];
        // Get the profile image
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[result objectForKey:@"pic"]]]];

        // Resize, crop the image to make sure it is square and renders
        // well on Retina display
        float ratio;
        float delta;
        float px = 100; // Double the pixels of the UIImageView (to render on Retina)
        CGPoint offset;
        CGSize size = image.size;
        if (size.width > size.height) {
            ratio = px / size.width;
            delta = (ratio*size.width - ratio*size.height);
            offset = CGPointMake(delta/2, 0);
        } else {
            ratio = px / size.height;
            delta = (ratio*size.height - ratio*size.width);
            offset = CGPointMake(0, delta/2);
        }
        CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                     (ratio * size.width) + delta,
                                     (ratio * size.height) + delta);
        UIGraphicsBeginImageContext(CGSizeMake(px, px));
        UIRectClip(clipRect);
        [image drawInRect:clipRect];
        UIImage *imgThumb =   UIGraphicsGetImageFromCurrentImageContext();
        [imgThumb retain];

        [profilePhotoImageView setImage:imgThumb];
        [self apiGraphUserPermissions];
    } else {
        // Processing permissions information
        FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
        [delegate setUserPermissions:[[result objectForKey:@"data"] objectAtIndex:0]];
    }
}

/**
 * Called when an error prevents the FamilyGraph API request from completing
 * successfully.
 */
- (void)request:(FGRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Err message: %@", [[error userInfo] objectForKey:@"error_msg"]);
    NSLog(@"Err code: %d", [error code]);
}

@end
