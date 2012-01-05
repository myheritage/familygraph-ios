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

#import "FGLoginDialog.h"
#import "FGRequest.h"

@protocol FGSessionDelegate;

/**
 * Main FamilyGraph interface for interacting with the FamilyGraph developer API.
 * Provides methods to log in and log out a user, make requests using the REST
 * and Graph APIs, and start user interface interactions (such as
 * pop-ups promoting for credentials, permissions, stream posts, etc.)
 */
@interface FamilyGraph : NSObject<FGLoginDialogDelegate>{
  NSString* _accessToken;
  NSDate* _expirationDate;
  id<FGSessionDelegate> _sessionDelegate;
  NSMutableSet* _requests;
  FGDialog* _loginDialog;
  FGDialog* _fgDialog;
  NSString* _clientId;
  NSString* _urlSchemeSuffix;
  NSArray* _permissions;
}

@property(nonatomic, copy) NSString* accessToken;
@property(nonatomic, copy) NSDate* expirationDate;
@property(nonatomic, assign) id<FGSessionDelegate> sessionDelegate;
@property(nonatomic, copy) NSString* urlSchemeSuffix;

- (id)initWithClientId:(NSString *)clientId
        andDelegate:(id<FGSessionDelegate>)delegate;

- (id)initWithClientId:(NSString *)clientId
    urlSchemeSuffix:(NSString *)urlSchemeSuffix
        andDelegate:(id<FGSessionDelegate>)delegate;

- (void)authorize:(NSArray *)permissions;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)logout;

- (FGRequest*)requestWithGraphPath:(NSString *)graphPath
                       andDelegate:(id <FGRequestDelegate>)delegate;

- (FGRequest*)requestWithGraphPath:(NSString *)graphPath
                         andParams:(NSMutableDictionary *)params
                       andDelegate:(id <FGRequestDelegate>)delegate;

- (FGRequest*)requestWithGraphPath:(NSString *)graphPath
                         andParams:(NSMutableDictionary *)params
                     andHttpMethod:(NSString *)httpMethod
                       andDelegate:(id <FGRequestDelegate>)delegate;

- (void)dialog:(NSString *)action
   andDelegate:(id<FGDialogDelegate>)delegate;

- (void)dialog:(NSString *)action
     andParams:(NSMutableDictionary *)params
   andDelegate:(id <FGDialogDelegate>)delegate;

- (BOOL)isSessionValid;

@end

////////////////////////////////////////////////////////////////////////////////

/**
 * Your application should implement this delegate to receive session callbacks.
 */
@protocol FGSessionDelegate <NSObject>

@optional

/**
 * Called when the user successfully logged in.
 */
- (void)fgDidLogin;

/**
 * Called when the user dismissed the dialog without logging in.
 */
- (void)fgDidNotLogin:(BOOL)cancelled;

/**
 * Called when the user logged out.
 */
- (void)fgDidLogout;

/**
 * Called when the current session has expired. This might happen when:
 *  - the access token expired 
 *  - the app has been disabled
 *  - the user revoked the app's permissions
 *  - the user changed his or her password
 */
- (void)fgSessionInvalidated;

@end
