//
//  WKWebViewJSBridge.h
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/1.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WKWebViewJSBridge : NSObject <WKScriptMessageHandler>

@property (nonatomic, strong, readonly) NSString *injectJS;

+ (instancetype)shareInstance;
- (WKWebViewConfiguration *)defaultConfiguration;

+ (void)bridgeWebView:(WKWebView *)webView;
+ (void)bridgeWebView:(WKWebView *)webView webVC:(UIViewController *)controller;

@end
