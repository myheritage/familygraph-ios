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

#import "FGDialog.h"
#import "FGLoginDialog.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FGLoginDialog

///////////////////////////////////////////////////////////////////////////////////////////////////
// public 

/*
 * initialize the FGLoginDialog with url and parameters
 */
- (id)initWithURL:(NSString*) loginURL 
      loginParams:(NSMutableDictionary*) params 
         delegate:(id <FGLoginDialogDelegate>) delegate{
  
  self = [super init];
  _serverURL = [loginURL retain];
  _params = [params retain];
  _loginDelegate = delegate;
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// FGDialog

/**
 * Override FGDialog : to call when the webView Dialog did succeed
 */
- (void) dialogDidSucceed:(NSURL*)url {
  NSString *q = [url absoluteString];
  NSString *token = [self getStringFromUrl:q needle:@"access_token="];
  NSString *expTime = [self getStringFromUrl:q needle:@"expires_in="];
  NSDate *expirationDate =nil;
  
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal == 0) {
      expirationDate = [NSDate distantFuture];
    } else {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    } 
  } 
  
  if ((token == (NSString *) [NSNull null]) || (token.length == 0)) {
    [self dialogDidCancel:url];
    [self dismissWithSuccess:NO animated:YES];
  } else {
    if ([_loginDelegate respondsToSelector:@selector(fgDialogLogin:expirationDate:)]) {
      [_loginDelegate fgDialogLogin:token expirationDate:expirationDate];
    }
    [self dismissWithSuccess:YES animated:YES];
  }
  
}

/**
 * Override FGDialog : to call with the login dialog get canceled 
 */
- (void)dialogDidCancel:(NSURL *)url {
  [self dismissWithSuccess:NO animated:YES];
  if ([_loginDelegate respondsToSelector:@selector(fgDialogNotLogin:)]) {
    [_loginDelegate fgDialogNotLogin:YES];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  if (!(([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -999) ||
        ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102))) {
    [super webView:webView didFailLoadWithError:error];
    if ([_loginDelegate respondsToSelector:@selector(fgDialogNotLogin:)]) {
      [_loginDelegate fgDialogNotLogin:NO];
    }
  }
}

@end
