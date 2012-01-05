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

#import "DataSet.h"


@implementation DataSet

@synthesize apiConfigData = _apiConfigData;

/*
 * This class that defines the UI data for the app. The main menu, sub menus, and
 methods each menu calls are defined here.
 */
- (id)init {
    self = [super init];
    if (self) {

        _apiConfigData = [[NSMutableArray alloc] initWithCapacity:1];

        // Initialize the menu items

        // Login and Permissions
        NSDictionary *authMenu1 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   @"Logging the user out", @"title",
                                   @"You should include a button to enable the user to log out.", @"description",
                                   @"Logout", @"button",
                                   @"apiLogout", @"method",
                                   nil];


        NSArray *authMenuItems = [[NSArray alloc] initWithObjects:
                                  authMenu1,
                                  nil];

        NSDictionary *authConfigData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        @"Login and Logout", @"title",
                                        @"FamilyGraph platform uses the OAuth 2.0 protocol for logging a user into your app. The Login button at the start of this app is a good example.", @"description",
                                        @"http://www.familygraph.com/", @"link",
                                        authMenuItems, @"menu",
                                        nil];

        [_apiConfigData addObject:authConfigData];

        [authMenu1 release];
        [authMenuItems release];
        [authConfigData release];


        // Graph API
        NSDictionary *graphMenu1 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      @"Get user's basic information", @"title",
                                      @"You can fetch the user's name in order to personalize the experience for them.", @"description",
                                      @"Get your information", @"button",
                                      @"apiGraphMe", @"method",
                                      nil];
        
        NSArray *graphMenuItems = [[NSArray alloc] initWithObjects:
                                   graphMenu1,
                                   nil];

        NSDictionary *graphConfigData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           @"FamilyGraph API", @"title",
                                           @"The FamilyGraph API enables you to read data from MyHeritage. You can utilize the user sites, family trees, individuals, families, media items and much more.", @"description",
                                           @"http://www.familygraph.com/", @"link",
                                           graphMenuItems, @"menu",
                                           nil];

        [_apiConfigData addObject:graphConfigData];

        [graphMenu1 release];
        [graphMenuItems release];
        [graphConfigData release];

    }
    return self;
}

- (void)dealloc {
    [_apiConfigData release];
    [super dealloc];
}

@end
