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

#import "FamilyGraph.h"
#import "FGLoginDialog.h"
#import "FGRequest.h"

static NSString* kDialogBaseURL = @"https://accounts.myheritage.com/oauth2/";
static NSString* kGraphBaseURL = @"https://familygraph.myheritage.com/";

static NSString* kFGAppAuthURLScheme = @"fgauth";
static NSString* kFGAppAuthURLPath = @"authorize";
static NSString* kRedirectURL = @"fgconnect://success";

static NSString* kLogin = @"authorize";
static NSString* kSDK = @"ios";
static NSString* kSDKVersion = @"1";

static NSString *requestFinishedKeyPath = @"state";
static void *finishedContext = @"finishedContext";

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface FamilyGraph ()

// private properties
@property(nonatomic, retain) NSArray* permissions;
@property(nonatomic, copy) NSString* clientId;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FamilyGraph

@synthesize accessToken = _accessToken,
         expirationDate = _expirationDate,
        sessionDelegate = _sessionDelegate,
            permissions = _permissions,
        urlSchemeSuffix = _urlSchemeSuffix,
               clientId = _clientId;


///////////////////////////////////////////////////////////////////////////////////////////////////
// private


- (id)initWithClientId:(NSString *)clientId
        andDelegate:(id<FGSessionDelegate>)delegate {
  self = [self initWithClientId:clientId urlSchemeSuffix:nil andDelegate:delegate];
  return self;
}

/**
 * Initialize the FamilyGraph object with client id.
 *
 * @param clientId the familygraph client id
 * @param urlSchemeSuffix
 *   urlSchemeSuffix is a string of lowercase letters that is
 *   appended to the base URL scheme used for SSO. For example,
 *   if your FamilyGraph client id is "1560ca2f381591b83696f947d174a99b" and you set urlSchemeSuffix to
 *   "abcd", the FamilyGraph app will expect your application to bind to
 *   the following URL scheme: "fg1560ca2f381591b83696f947d174a99babcd".
 *   This is useful if your have multiple iOS applications that
 *   share a single FamilyGraph application id (for example, if you
 *   have a free and a paid version on the same app) and you want
 *   to use SSO with both apps. Giving both apps different
 *   urlSchemeSuffix values will allow the FamilyGraph app to disambiguate
 *   their URL schemes and always redirect the user back to the
 *   correct app, even if both the free and the app is installed
 *   on the device.
 * @param delegate the FGSessionDelegate
 */
- (id)initWithClientId:(NSString *)clientId
    urlSchemeSuffix:(NSString *)urlSchemeSuffix
        andDelegate:(id<FGSessionDelegate>)delegate {
  
  self = [super init];
  if (self) {
    _requests = [[NSMutableSet alloc] init];
    self.clientId = clientId;
    self.sessionDelegate = delegate;
    self.urlSchemeSuffix = urlSchemeSuffix;
  }
  return self;
}

/**
 * Override NSObject : free the space
 */
- (void)dealloc {
  for (FGRequest* _request in _requests) {
    [_request removeObserver:self forKeyPath:requestFinishedKeyPath];
  }
  [_accessToken release];
  [_expirationDate release];
  [_requests release];
  [_loginDialog release];
  [_fgDialog release];
  [_clientId release];
  [_permissions release];
  [_urlSchemeSuffix release];
  [super dealloc];
}

- (void)invalidateSession {
  self.accessToken = nil;
  self.expirationDate = nil;
    
  NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSArray* familygraphCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:@"http://accounts.myheritage.com"]];
    
  for (NSHTTPCookie* cookie in familygraphCookies) {
    [cookies deleteCookie:cookie];
  }
}

/**
 * A private helper function for sending HTTP requests.
 *
 * @param url
 *            url to send http request
 * @param params
 *            parameters to append to the url
 * @param httpMethod
 *            http method @"GET" or @"POST"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 */
- (FGRequest*)openUrl:(NSString *)url
               params:(NSMutableDictionary *)params
           httpMethod:(NSString *)httpMethod
             delegate:(id<FGRequestDelegate>)delegate {

  [params setValue:@"json" forKey:@"format"];
  [params setValue:kSDK forKey:@"sdk"];
  [params setValue:kSDKVersion forKey:@"sdk_version"];
  if ([self isSessionValid]) {
    [params setValue:self.accessToken forKey:@"bearer_token"];
  }

  FGRequest* _request = [FGRequest getRequestWithParams:params
                                             httpMethod:httpMethod
                                               delegate:delegate
                                             requestURL:url];
  [_requests addObject:_request];
  [_request addObserver:self forKeyPath:requestFinishedKeyPath options:0 context:finishedContext];
  [_request connect];
  return _request;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (context == finishedContext) {
    FGRequest* _request = (FGRequest*)object;
    FGRequestState requestState = [_request state];
    if (requestState == kFGRequestStateError) {
      [self invalidateSession];
      if ([self.sessionDelegate respondsToSelector:@selector(fgSessionInvalidated)]) {
        [self.sessionDelegate fgSessionInvalidated];
      }
    }
    if (requestState == kFGRequestStateComplete || requestState == kFGRequestStateError) {
      [_request removeObserver:self forKeyPath:requestFinishedKeyPath];
      [_requests removeObject:_request];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

/**
 * A private function for getting the app's base url.
 */
- (NSString *)getOwnBaseUrl {
  return [NSString stringWithFormat:@"fg%@%@://authorize",
          _clientId,
          _urlSchemeSuffix ? _urlSchemeSuffix : @""];
}

/**
 * A private function for opening the authorization dialog.
 */
- (void)authorizeWithFGAppAuth:(BOOL)tryFGAppAuth
                    safariAuth:(BOOL)trySafariAuth {
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 _clientId, @"client_id",
                                 @"user_agent", @"type",
                                 kRedirectURL, @"redirect_uri",
                                 @"touch", @"display",
								 @"token", @"response_type",
                                 kSDK, @"sdk",
                                 nil];

  NSString *loginDialogURL = [kDialogBaseURL stringByAppendingString:kLogin];

  if (_permissions != nil) {
    NSString* scope = [_permissions componentsJoinedByString:@","];
    [params setValue:scope forKey:@"scope"];
  }

  if (_urlSchemeSuffix) {
    [params setValue:_urlSchemeSuffix forKey:@"local_client_id"];
  }
  
  // If the device is running a version of iOS that supports multitasking,
  // try to obtain the access token from the FamilyGraph app installed
  // on the device.
  // If the FamilyGraph app isn't installed or it doesn't support
  // the fgauth:// URL scheme, fall back on Safari for obtaining the access token.
  // This minimizes the chance that the user will have to enter his or
  // her credentials in order to authorize the application.
  BOOL didOpenOtherApp = NO;
  UIDevice *device = [UIDevice currentDevice];
  if ([device respondsToSelector:@selector(isMultitaskingSupported)] && [device isMultitaskingSupported]) {
    if (tryFGAppAuth) {
      NSString *scheme = kFGAppAuthURLScheme;
      if (_urlSchemeSuffix) {
        scheme = [scheme stringByAppendingString:@"2"];
      }
      NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", scheme, kFGAppAuthURLPath];
      NSString *fgAppUrl = [FGRequest serializeURL:urlPrefix params:params];
      didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fgAppUrl]];
    }

    if (trySafariAuth && !didOpenOtherApp) {
      NSString *nextUrl = [self getOwnBaseUrl];
      [params setValue:nextUrl forKey:@"redirect_uri"];

      NSString *fgAppUrl = [FGRequest serializeURL:loginDialogURL params:params];
      didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fgAppUrl]];
    }
  }

  // If single sign-on failed, open an inline login dialog. This will require the user to
  // enter his or her credentials.
  if (!didOpenOtherApp) {
    [_loginDialog release];
    _loginDialog = [[FGLoginDialog alloc] initWithURL:loginDialogURL
                                          loginParams:params
                                             delegate:self];
    [_loginDialog show];
  }
}

/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
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


///////////////////////////////////////////////////////////////////////////////////////////////////
//public

/**
 * Starts a dialog which prompts the user to log in to FamilyGraph and grant
 * the requested permissions to the application.
 *
 * If the device supports multitasking, we use fast app switching to show
 * the dialog in the FamilyGraph app or, if the FamilyGraph app isn't installed,
 * in Safari (this enables single sign-on by allowing multiple apps on
 * the device to share the same user session).
 * When the user grants or denies the permissions, the app that
 * showed the dialog (the FamilyGraph app or Safari) redirects back to
 * the calling application, passing in the URL the access token
 * and/or any other parameters the FamilyGraph backend includes in
 * the result (such as an error code if an error occurs).
 *
 *
 * Also note that requests may be made to the API without calling
 * authorize() first, in which case only public information is returned.
 *
 * @param permissions
 *            A list of permission required for this application: e.g.
 *            "offline_access". see
 *            This parameter should not be null -- if you do not require any
 *            permissions, then pass in an empty String array.
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the user has logged in.
 */
- (void)authorize:(NSArray *)permissions {
  self.permissions = permissions;

  [self authorizeWithFGAppAuth:YES safariAuth:YES];
}

/**
 * This function processes the URL the FamilyGraph application or Safari used to
 * open your application during a single sign-on flow.
 *
 * You MUST call this function in your UIApplicationDelegate's handleOpenURL
 * method (see
 * http://developer.apple.com/library/ios/#documentation/uikit/reference/UIApplicationDelegate_Protocol/Reference/Reference.html
 * for more info).
 *
 * This will ensure that the authorization process will proceed smoothly once the
 * FamilyGraph application or Safari redirects back to your application.
 *
 * @param URL the URL that was passed to the application delegate's handleOpenURL method.
 *
 * @return YES if the URL starts with 'fg[app_id]://authorize and hence was handled
 *   by SDK, NO otherwise.
 */
- (BOOL)handleOpenURL:(NSURL *)url {
  // If the URL's structure doesn't match the structure used for FamilyGraph authorization, abort.
  if (![[url absoluteString] hasPrefix:[self getOwnBaseUrl]]) {
    return NO;
  }

  NSString *query = [url fragment];

  // Version 3.2.3 of the FamilyGraph app encodes the parameters in the query but
  // version 3.3 and above encode the parameters in the fragment. To support
  // both versions of the FamilyGraph app, we try to parse the query if
  // the fragment is missing.
  if (!query) {
    query = [url query];
  }

  NSDictionary *params = [self parseURLParams:query];
  NSString *accessToken = [params valueForKey:@"access_token"];

  // If the URL doesn't contain the access token, an error has occurred.
  if (!accessToken) {
    NSString *errorReason = [params valueForKey:@"error"];

    // If the error response indicates that we should try again using Safari, open
    // the authorization dialog in Safari.
    if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
      [self authorizeWithFGAppAuth:NO safariAuth:YES];
      return YES;
    }

    // If the error response indicates that we should try the authorization flow
    // in an inline dialog, do that.
    if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
      [self authorizeWithFGAppAuth:NO safariAuth:NO];
      return YES;
    }

    // The familygraph app may return an error_code parameter in case it
    // encounters a UIWebViewDelegate error. This should not be treated
    // as a cancel.
    NSString *errorCode = [params valueForKey:@"error_code"];

    BOOL userDidCancel =
      !errorCode && (!errorReason || [errorReason isEqualToString:@"access_denied"]);
    [self fgDialogNotLogin:userDidCancel];
    return YES;
  }

  // We have an access token, so parse the expiration date.
  NSString *expTime = [params valueForKey:@"expires_in"];
  NSDate *expirationDate = [NSDate distantFuture];
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal != 0) {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    }
  }

  [self fgDialogLogin:accessToken expirationDate:expirationDate];
  return YES;
}

/**
 * Invalidate the current user session by removing the access token in
 * memory and clearing the browser cookie.
 *
 * Note that this method dosen't unauthorize the application --
 * it just removes the access token. To unauthorize the application,
 * the user must remove the app in the app settings page under the privacy
 * settings screen on familygraph.com.
 */
- (void)logout {
  [self invalidateSession];
    
  if ([self.sessionDelegate respondsToSelector:@selector(fgDidLogout)]) {
    [self.sessionDelegate fgDidLogout];
  }
}

/**
 * Make a request to the FamilyGraph Graph API without any parameters.
 *
 *
 * @param graphPath
 *            Path to resource in the FamilyGraph graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://www.familygraph.com/me
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FGRequest*
 *            Returns a pointer to the FGRequest object.
 */
- (FGRequest*)requestWithGraphPath:(NSString *)graphPath
                 andDelegate:(id <FGRequestDelegate>)delegate {

  return [self requestWithGraphPath:graphPath
                          andParams:[NSMutableDictionary dictionary]
                      andHttpMethod:@"GET"
                        andDelegate:delegate];
}

/**
 * Make a request to the FamilyGraph Graph API with the given string
 * parameters using an HTTP GET (default method).
 *
 *
 *
 * @param graphPath
 *            Path to resource in the FamilyGraph graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://www.familygraph.com/me
 * @param parameters
 *            key-value string parameters
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FGRequest*
 *            Returns a pointer to the FGRequest object.
 */
- (FGRequest*)requestWithGraphPath:(NSString *)graphPath
                   andParams:(NSMutableDictionary *)params
                 andDelegate:(id <FGRequestDelegate>)delegate {

  return [self requestWithGraphPath:graphPath
                          andParams:params
                      andHttpMethod:@"GET"
                        andDelegate:delegate];
}

/**
 * Make a request to the FamilyGraph Graph API with the given
 * HTTP method and string parameters. Note that binary data parameters
 * (e.g. pictures) are not yet supported by this helper function.
 *
 *
 *
 * @param graphPath
 *            Path to resource in the FamilyGraph graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://www.familygraph.com/me
 * @param parameters
 *            key-value string parameters,
 *            To upload a file, you should specify the httpMethod to be
 *            "POST" and the “params” you passed in should contain a value
 *            of the type (UIImage *) or (NSData *) which contains the
 *            content that you want to upload
 * @param httpMethod
 *            http verb, e.g. "GET", "POST", "DELETE"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FGRequest*
 *            Returns a pointer to the FGRequest object.
 */
- (FGRequest*)requestWithGraphPath:(NSString *)graphPath
                   andParams:(NSMutableDictionary *)params
               andHttpMethod:(NSString *)httpMethod
                 andDelegate:(id <FGRequestDelegate>)delegate {

  NSString * fullURL = [kGraphBaseURL stringByAppendingString:graphPath];
  return [self openUrl:fullURL
                params:params
            httpMethod:httpMethod
              delegate:delegate];
}

/**
 * Generate a UI dialog for the request action.
 *
 * @param action
 *            String representation of the desired method: e.g. "login",
 *            "feed", ...
 * @param delegate
 *            Callback interface to notify the calling application when the
 *            dialog has completed.
 */
- (void)dialog:(NSString *)action
   andDelegate:(id<FGDialogDelegate>)delegate {
  NSMutableDictionary * params = [NSMutableDictionary dictionary];
  [self dialog:action andParams:params andDelegate:delegate];
}

/**
 * Generate a UI dialog for the request action with the provided parameters.
 *
 * @param action
 *            String representation of the desired method: e.g. "login",
 *            "feed", ...
 * @param parameters
 *            key-value string parameters
 * @param delegate
 *            Callback interface to notify the calling application when the
 *            dialog has completed.
 */
- (void)dialog:(NSString *)action
     andParams:(NSMutableDictionary *)params
   andDelegate:(id <FGDialogDelegate>)delegate {

  [_fgDialog release];

  NSString *dialogURL = [kDialogBaseURL stringByAppendingString:action];
  [params setObject:@"touch" forKey:@"display"];
  [params setObject:kSDKVersion forKey:@"sdk"];
  [params setObject:kRedirectURL forKey:@"redirect_uri"];

  if (action == kLogin) {
    [params setObject:@"user_agent" forKey:@"type"];
    _fgDialog = [[FGLoginDialog alloc] initWithURL:dialogURL loginParams:params delegate:self];
  } else {
    [params setObject:_clientId forKey:@"client_id"];
    if ([self isSessionValid]) {
      [params setValue:[self.accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                forKey:@"access_token"];
    }
    _fgDialog = [[FGDialog alloc] initWithURL:dialogURL params:params delegate:delegate];
  }

  [_fgDialog show];
}

/**
 * @return boolean - whether this object has an non-expired session token
 */
- (BOOL)isSessionValid {
  return (self.accessToken != nil && self.expirationDate != nil
           && NSOrderedDescending == [self.expirationDate compare:[NSDate date]]);

}

///////////////////////////////////////////////////////////////////////////////////////////////////
//FGLoginDialogDelegate

/**
 * Set the authToken and expirationDate after login succeed
 */
- (void)fgDialogLogin:(NSString *)token expirationDate:(NSDate *)expirationDate {
  self.accessToken = token;
  self.expirationDate = expirationDate;
  if ([self.sessionDelegate respondsToSelector:@selector(fgDidLogin)]) {
    [self.sessionDelegate fgDidLogin];
  }

}

/**
 * Did not login call the not login delegate
 */
- (void)fgDialogNotLogin:(BOOL)cancelled {
  if ([self.sessionDelegate respondsToSelector:@selector(fgDidNotLogin:)]) {
    [self.sessionDelegate fgDidNotLogin:cancelled];
  }
}

@end
