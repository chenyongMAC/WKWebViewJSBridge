//
//  NSURLProtocol+WebKitSupport.h
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/10.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  用于WKWebView请求拦截
 */

@interface NSURLProtocol (WebKitSupport)

+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString*)scheme;

@end
