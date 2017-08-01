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

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) NSString *injectJS;

+ (instancetype)shareInstance;

+ (void)bridgeWebView:(WKWebView *)webView;

- (WKWebViewConfiguration *)defaultConfiguration;

@end
