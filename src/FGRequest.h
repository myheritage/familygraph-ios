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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol FGRequestDelegate;

enum {
  kFGRequestStateReady,
  kFGRequestStateLoading,
  kFGRequestStateComplete,
  kFGRequestStateError
};
typedef NSUInteger FGRequestState;

/**
 * Do not use this interface directly, instead, use method in FamilyGraph.h
 */
@interface FGRequest : NSObject {
  id<FGRequestDelegate> _delegate;
  NSString*             _url;
  NSString*             _httpMethod;
  NSMutableDictionary*  _params;
  NSURLConnection*      _connection;
  NSMutableData*        _responseText;
  FGRequestState        _state;
  NSError*              _error;
}


@property(nonatomic,assign) id<FGRequestDelegate> delegate;

/**
 * The URL which will be contacted to execute the request.
 */
@property(nonatomic,copy) NSString* url;

/**
 * The API method which will be called.
 */
@property(nonatomic,copy) NSString* httpMethod;

/**
 * The dictionary of parameters to pass to the method.
 *
 * These values in the dictionary will be converted to strings using the
 * standard Objective-C object-to-string conversion facilities.
 */
@property(nonatomic,retain) NSMutableDictionary* params;
@property(nonatomic,retain) NSURLConnection*  connection;
@property(nonatomic,retain) NSMutableData* responseText;
@property(nonatomic,readonly) FGRequestState state;

/**
 * Error returned by the server in case of request's failure (or nil otherwise).
 */
@property(nonatomic,retain) NSError* error;


+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params;

+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod;

+ (FGRequest*)getRequestWithParams:(NSMutableDictionary *) params
                        httpMethod:(NSString *) httpMethod
                          delegate:(id<FGRequestDelegate>)delegate
                        requestURL:(NSString *) url;
- (BOOL) loading;

- (void) connect;

@end

////////////////////////////////////////////////////////////////////////////////

/*
 *Your application should implement this delegate
 */
@protocol FGRequestDelegate <NSObject>

@optional

/**
 * Called just before the request is sent to the server.
 */
- (void)requestLoading:(FGRequest *)request;

/**
 * Called when the server responds and begins to send back data.
 */
- (void)request:(FGRequest *)request didReceiveResponse:(NSURLResponse *)response;

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FGRequest *)request didFailWithError:(NSError *)error;

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array, a string, or a number,
 * depending on thee format of the API response.
 */
- (void)request:(FGRequest *)request didLoad:(id)result;

/**
 * Called when a request returns a response.
 *
 * The result object is the raw response from the server of type NSData
 */
- (void)request:(FGRequest *)request didLoadRawResponse:(NSData *)data;

@end

