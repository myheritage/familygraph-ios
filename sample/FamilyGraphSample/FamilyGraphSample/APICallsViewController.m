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

#import "APICallsViewController.h"
#import "FGSampleAppDelegate.h"
#import "FamilyGraphHeaders.h"
#import "DataSet.h"
#import "APIResultsViewController.h"
#import "RootViewController.h"

// For re-using table cells
#define TITLE_TAG 1001
#define DESCRIPTION_TAG 1002

@implementation APICallsViewController

@synthesize apiTableView;
@synthesize apiMenuItems;
@synthesize apiHeader;
@synthesize savedAPIResult;
@synthesize locationManager;
@synthesize mostRecentLocation;
@synthesize activityIndicator;
@synthesize messageLabel;
@synthesize messageView;

- (id)initWithIndex:(NSUInteger)index {
    self = [super init];
    if (self) {
        childIndex = index;
        savedAPIResult = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

- (void)dealloc {
    [apiTableView release];
    [apiMenuItems release];
    [apiHeader release];
    [savedAPIResult release];

    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
    [locationManager release];

    [mostRecentLocation release];
    [activityIndicator release];
    [messageLabel release];
    [messageView release];

    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen
                                                  mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;
    [view release];

    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *apiData = [[[delegate apiData] apiConfigData] objectAtIndex:childIndex];
    self.navigationItem.title = [apiData objectForKey:@"title"];
    apiMenuItems = [[NSArray arrayWithArray:[apiData objectForKey:@"menu"]] retain];
    apiHeader = [[apiData objectForKey:@"description"] retain];

    self.navigationItem.backBarButtonItem =
    [[[UIBarButtonItem alloc] initWithTitle:@"Back"
                                      style:UIBarButtonItemStyleBordered
                                     target:nil
                                     action:nil] autorelease];

    // Main Menu Table
    apiTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                            style:UITableViewStylePlain];
    [apiTableView setBackgroundColor:[UIColor whiteColor]];
    apiTableView.dataSource = self;
    apiTableView.delegate = self;
    apiTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:apiTableView];

    // Activity Indicator
    int xPosition = (self.view.bounds.size.width / 2.0) - 15.0;
    int yPosition = (self.view.bounds.size.height / 2.0) - 15.0;
    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(xPosition, yPosition, 30, 30)];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [self.view addSubview:activityIndicator];

    // Message Label for showing confirmation and status messages
    CGFloat yLabelViewOffset = self.view.bounds.size.height-self.navigationController.navigationBar.frame.size.height-30;
    messageView = [[UIView alloc]
                    initWithFrame:CGRectMake(0, yLabelViewOffset, self.view.bounds.size.width, 30)];
    messageView.backgroundColor = [UIColor lightGrayColor];

    UIView *messageInsetView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, self.view.bounds.size.width-1, 28)];
    messageInsetView.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                   green:248.0/255.0
                                                    blue:228.0/255.0
                                                   alpha:1];
    messageLabel = [[UILabel alloc]
                             initWithFrame:CGRectMake(4, 1, self.view.bounds.size.width-10, 26)];
    messageLabel.text = @"";
    messageLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
    messageLabel.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                  green:248.0/255.0
                                                   blue:228.0/255.0
                                                  alpha:0.6];
    [messageInsetView addSubview:messageLabel];
    [messageView addSubview:messageInsetView];
    [messageInsetView release];
    messageView.hidden = YES;
    [self.view addSubview:messageView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Private Helper Methods
/*
 * This method is called to store the check-in permissions
 * in the app session after the permissions have been updated.
 */
- (void)updateCheckinPermissions {
    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate userPermissions] setObject:@"1" forKey:@"user_checkins"];
    [[delegate userPermissions] setObject:@"1" forKey:@"publish_checkins"];
}

/*
 * This method shows the activity indicator and
 * deactivates the table to avoid user input.
 */
- (void)showActivityIndicator {
    if (![activityIndicator isAnimating]) {
        apiTableView.userInteractionEnabled = NO;
        [activityIndicator startAnimating];
    }
}

/*
 * This method hides the activity indicator
 * and enables user interaction once more.
 */
- (void)hideActivityIndicator {
    if ([activityIndicator isAnimating]) {
        [activityIndicator stopAnimating];
        apiTableView.userInteractionEnabled = YES;
    }
}

/*
 * This method is used to display API confirmation and
 * error messages to the user.
 */
- (void)showMessage:(NSString *)message {
    CGRect labelFrame = messageView.frame;
    labelFrame.origin.y = [UIScreen mainScreen].bounds.size.height - self.navigationController.navigationBar.frame.size.height - 20;
    messageView.frame = labelFrame;
    messageLabel.text = message;
    messageView.hidden = NO;

    // Use animation to show the message from the bottom then
    // hide it.
    [UIView animateWithDuration:0.5
                          delay:1.0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         CGRect labelFrame = messageView.frame;
                         labelFrame.origin.y -= labelFrame.size.height;
                         messageView.frame = labelFrame;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             [UIView animateWithDuration:0.5
                                                   delay:3.0
                                                 options: UIViewAnimationCurveEaseOut
                                              animations:^{
                                                  CGRect labelFrame = messageView.frame;
                                                  labelFrame.origin.y += messageView.frame.size.height;
                                                  messageView.frame = labelFrame;
                                              }
                                              completion:^(BOOL finished){
                                                  if (finished) {
                                                      messageView.hidden = YES;
                                                      messageLabel.text = @"";
                                                  }
                                              }];
                         }
                     }];
}

/*
 * This method hides the message, only needed if view closed
 * and animation still going on.
 */
- (void)hideMessage {
    messageView.hidden = YES;
    messageLabel.text = @"";
}

/*
 * This method handles any clean up needed if the view
 * is about to disappear.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Hide the activitiy indicator
    [self hideActivityIndicator];
    // Hide the message.
    [self hideMessage];
}

/**
 * Helper method called when a button is clicked
 */
- (void)apiButtonClicked:(id)sender {
    // Each menu button in the UITableViewController is initialized
    // with a tag representing the table cell row. When the button
    // is clicked the button is passed along in the sender object.
    // From this object we can then read the tag property to determine
    // which menu button was clicked.
    SEL selector = NSSelectorFromString([[apiMenuItems objectAtIndex:[sender tag]] objectForKey:@"method"]);
    if ([self respondsToSelector:selector]) {
        [self performSelector:selector];
    }
}

/**
 * Helper method to parse URL query parameters
 */
- (NSDictionary *)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}

#pragma mark - FamilyGraph API Calls
/*
 * --------------------------------------------------------------------------
 * Login and Logout
 * --------------------------------------------------------------------------
 */

/*
 * iOS SDK method that handles the logout API call and flow.
 */
- (void)apiLogout {
    currentAPICall = kAPILogout;
    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate familyGraph] logout];
}

/*
 * Graph API: App unauthorize
 */
//- (void)apiGraphUserPermissionsDelete {
//    [self showActivityIndicator];
//    currentAPICall = kAPIGraphUserPermissionsDelete;
//    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
//    // Passing empty (no) parameters unauthorizes the entire app. To revoke individual permissions
//    // add a permission parameter with the name of the permission to revoke.
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
//    [[delegate familyGraph] requestWithGraphPath:@"me/permissions"
//                                    andParams:params
//                                andHttpMethod:@"DELETE"
//                                  andDelegate:self];
//}



/*
 * --------------------------------------------------------------------------
 * Graph API
 * --------------------------------------------------------------------------
 */

/*
 * Graph API: Get the user's basic information, picking the name and picture fields.
 */
- (void)apiGraphMe {
    [self showActivityIndicator];
    currentAPICall = kAPIGraphMe;
    FGSampleAppDelegate *delegate = (FGSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"name,picture",  @"fields",
                                   nil];
    [[delegate familyGraph] requestWithGraphPath:@"me" andParams:params andDelegate:self];
}

///*
// * Method called when user location found. Calls the search API with the most
// * recent location reading.
// */
- (void)processLocationData {
    // Stop updating location information
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
}


#pragma mark - UITableViewDatasource and UITableViewDelegate Methods
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UITextView *headerTextView = [[[UITextView alloc]
                     initWithFrame:CGRectMake(10, 10, tableView.bounds.size.width, 60.0)] autorelease];
        headerTextView.textAlignment = UITextAlignmentLeft;
        headerTextView.backgroundColor = [UIColor colorWithRed:0.9
                                                         green:0.9
                                                          blue:0.9 alpha:1];
        headerTextView.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        headerTextView.text = self.apiHeader;
        return headerTextView;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        // Automatically size the header for this API section
        CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);

        UIFont *titleFont = [UIFont fontWithName:@"Helvetica" size:14.0];
        CGSize labelSize = [self.apiHeader sizeWithFont:titleFont
                                constrainedToSize:constraintSize
                                    lineBreakMode:UILineBreakModeWordWrap];
        return labelSize.height + 20;
    } else {
        return 0.0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return  0.0;
    } else {
        // Automatically size the table row based on the content
        CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);

        NSString *cellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"title"];
        UIFont *cellFont = [UIFont boldSystemFontOfSize:14.0];
        CGSize labelSize = [cellText sizeWithFont:cellFont
                                constrainedToSize:constraintSize
                                    lineBreakMode:UILineBreakModeWordWrap];

        NSString *detailCellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"description"];
        UIFont *detailCellFont = [UIFont fontWithName:@"Helvetica" size:12.0];;
        CGSize detailLabelSize = [detailCellText sizeWithFont:detailCellFont
                                constrainedToSize:constraintSize
                                    lineBreakMode:UILineBreakModeWordWrap];

        return labelSize.height + detailLabelSize.height + 74;
    }
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return [apiMenuItems count];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *textLabel;
    UILabel *detailTextLabel;
    UIButton *button;

    UIFont *cellFont = [UIFont boldSystemFontOfSize:14.0];
    UIFont *detailCellFont = [UIFont fontWithName:@"Helvetica" size:12.0];

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        // Initialize API title UILabel
        textLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        textLabel.tag = TITLE_TAG;
        textLabel.font = cellFont;
        [cell.contentView addSubview:textLabel];

        // Initialize API description UILabel
        detailTextLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        detailTextLabel.tag = DESCRIPTION_TAG;
        detailTextLabel.font = detailCellFont;
        detailTextLabel.textColor = [UIColor darkGrayColor];
        detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        detailTextLabel.numberOfLines = 0;
        [cell.contentView addSubview:detailTextLabel];

        // Initialize API button UIButton
        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [button setBackgroundImage:[[UIImage imageNamed:@"MenuButton.png"]
                                    stretchableImageWithLeftCapWidth:9 topCapHeight:9]
                          forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(apiButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:button];
    } else {
        textLabel = (UILabel *)[cell.contentView viewWithTag:TITLE_TAG];
        detailTextLabel = (UILabel *)[cell.contentView viewWithTag:DESCRIPTION_TAG];
        // For the button cannot search by tag since it is not constant
        // and is dynamically used figure out which button is clicked.
        // So instead we loop through subviews of the cell to find the button.
        for (UIView *subview in cell.contentView.subviews) {
            if([subview isKindOfClass:[UIButton class]]) {
                button = (UIButton *)subview;
            }
        }
    }

    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);

    // The API title
    NSString *cellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"title"];
    CGSize labelSize = [cellText sizeWithFont:cellFont
                            constrainedToSize:constraintSize
                                lineBreakMode:UILineBreakModeWordWrap];
    textLabel.frame = CGRectMake(20, 2,
                                  (cell.contentView.frame.size.width-40),
                                  labelSize.height);
    textLabel.text = cellText;

    // The API description
    NSString *detailCellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"description"];
    CGSize detailLabelSize = [detailCellText sizeWithFont:detailCellFont
                                        constrainedToSize:constraintSize
                                            lineBreakMode:UILineBreakModeWordWrap];
    detailTextLabel.frame = CGRectMake(20, (labelSize.height + 4),
                                       (cell.contentView.frame.size.width-40),
                                       detailLabelSize.height);
    detailTextLabel.text = detailCellText;


    // The API button
    CGFloat yButtonOffset = labelSize.height + detailLabelSize.height + 15;
    button.frame = CGRectMake(20, yButtonOffset, (cell.contentView.frame.size.width-40), 44);
    [button setTitle:[[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"button"]
            forState:UIControlStateNormal];
    // Set the tag that will later identify the button that is clicked.
    button.tag = indexPath.row;


    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - CLLocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // We will care about horizontal accuracy for this example

    // Try and avoid cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    // test the measurement to see if it is more accurate than the previous measurement
    if (mostRecentLocation == nil || mostRecentLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // Store current location
        self.mostRecentLocation = newLocation;
        if (newLocation.horizontalAccuracy <= locationManager.desiredAccuracy) {
            // Measurement is good
            [self processLocationData];
            // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
            [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                     selector:@selector(processLocationData)
                                                       object:nil];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error code] != kCLErrorLocationUnknown) {
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
    }
    [self hideActivityIndicator];
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
    [self hideActivityIndicator];
    if ([result isKindOfClass:[NSArray class]] && ([result count] > 0)) {
        result = [result objectAtIndex:0];
    }
    switch (currentAPICall) {
        case kAPIGraphMe:
        {
            NSString *nameID = [[NSString alloc] initWithFormat:@"%@ (%@)", [result objectForKey:@"name"], [result objectForKey:@"id"]];
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:@"FamilyGraph Me" 
									  message:nameID
									  delegate:nil 
									  cancelButtonTitle:@"OK" 
									  otherButtonTitles:nil, 
									  nil];
			[alertView show];
			[alertView release];
            
            [nameID release];
            break;
        }
        default:
            break;
    }
}

/**
 * Called when an error prevents the FamilyGraph API request from completing
 * successfully.
 */
- (void)request:(FGRequest *)request didFailWithError:(NSError *)error {
    [self hideActivityIndicator];
    NSLog(@"Error message: %@", [[error userInfo] objectForKey:@"error_msg"]);
    [self showMessage:@"Oops, something went haywire."];
}

#pragma mark - FGDialogDelegate Methods

/**
 * Called when a UIServer Dialog successfully return. Using this callback
 * instead of dialogDidComplete: to properly handle successful shares/sends
 * that return ID data back.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url {
    if (![url query]) {
        NSLog(@"User canceled dialog or there was an error");
        return;
    }

//    NSDictionary *params = [self parseURLParams:[url query]];
    switch (currentAPICall) {
        default:
            break;
    }
}

- (void)dialogDidNotComplete:(FGDialog *)dialog {
    NSLog(@"Dialog dismissed.");
}

- (void)dialog:(FGDialog*)dialog didFailWithError:(NSError *)error {
    NSLog(@"Error message: %@", [[error userInfo] objectForKey:@"error_msg"]);
    [self showMessage:@"Oops, something went haywire."];
}

/**
 * Called when the user granted additional permissions.
 */
- (void)userDidGrantPermission {
    // After permissions granted follow up with next API call
    switch (currentAPICall) {
        default:
            break;
    }
}

/**
 * Called when the user canceled the authorization dialog.
 */
- (void)userDidNotGrantPermission {
    [self showMessage:@"Extended permissions not granted."];
}

@end
