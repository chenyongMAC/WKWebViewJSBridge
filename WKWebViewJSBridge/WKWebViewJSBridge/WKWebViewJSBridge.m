//
//  WKWebViewJSBridge.m
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/1.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import "WKWebViewJSBridge.h"
#import "URWKWebViewController.h"

NSString * const RbJSBridgeEvent = @"RbJSBridgeEvent";

static WKWebViewJSBridge *manager = nil;

@interface WKWebViewJSBridge ()

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) URWKWebViewController *webVC;
@property (nonatomic, strong, readwrite) NSString *injectJS;

@end

@implementation WKWebViewJSBridge

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WKWebViewJSBridge alloc] init];
        manager.injectJS = [manager getJsString];
    });
    return manager;
}

#pragma mark - public
+ (void)bridgeWebView:(WKWebView *)webView {
    [WKWebViewJSBridge shareInstance].webView = webView;
}

+ (void)bridgeWebView:(WKWebView *)webView webVC:(UIViewController *)controller {
    [WKWebViewJSBridge shareInstance].webView = webView;
    
    if ([controller isKindOfClass:[URWKWebViewController class]]) {
        [WKWebViewJSBridge shareInstance].webVC = (URWKWebViewController *)controller;
    }
}

- (WKWebViewConfiguration *)defaultConfiguration {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.allowsAirPlayForMediaPlayback = YES;  //视频播放
    configuration.allowsInlineMediaPlayback = YES;  //在线播放
    configuration.selectionGranularity = YES;   //与网页交互, 选择视图
    configuration.processPool = [[WKProcessPool alloc] init];
    configuration.suppressesIncrementalRendering = YES;
    
    configuration.preferences = [[WKPreferences alloc] init];
    configuration.preferences.minimumFontSize = 10;    // 默认为0
    configuration.preferences.javaScriptEnabled = YES;
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    
    configuration.userContentController = [[WKUserContentController alloc] init];
    WKUserScript *usrScript = [[WKUserScript alloc] initWithSource:[WKWebViewJSBridge shareInstance].injectJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:usrScript];
    [configuration.userContentController addScriptMessageHandler:[WKWebViewJSBridge shareInstance] name:RbJSBridgeEvent];
    
    return configuration;
}

#pragma mark - private
- (NSString *)getJsString {
    NSString *path =[[NSBundle mainBundle] pathForResource:@"RbJSBridge" ofType:@"js"];
    NSString *handlerJS = [NSString stringWithContentsOfFile:path encoding:kCFStringEncodingUTF8 error:nil];
    return handlerJS;
}

- (void)interactWitMethodName:(NSString *)methodName params:(NSDictionary *)params callback:(void(^)(id response))callBack{
    NSMutableArray *paramArray = [[NSMutableArray alloc] init];
    if (params != nil) {
        [paramArray addObject:params];
    }
    if (callBack != nil) {
        [paramArray addObject:callBack];
    }
    
    for (NSInteger i=0; i<paramArray.count; i++) {
        methodName = [NSString stringWithFormat:@"%@:",methodName];
    }
    SEL selector =NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        [self JKperformSelector:selector withObjects:paramArray];
    }
}

- (id)JKperformSelector:(SEL)aSelector withObjects:(NSArray *)objects {
    NSMethodSignature *signature = [self methodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    
    NSUInteger i = 1;
    
    for (id object in objects) {
        id tempObject = object;
        [invocation setArgument:&tempObject atIndex:++i];
    }
    [invocation invoke];
    
    if ([signature methodReturnLength]) {
        id data;
        [invocation getReturnValue:&data];
        return data;
    }
    return nil;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:RbJSBridgeEvent]) {
        if ([message.body hasPrefix:@"_QUEUE_SET_RESULT&"]) {
            NSString *string = (NSString *)message.body;
            NSString *dataStr = [string substringWithRange:NSMakeRange(18, string.length - 18)];
            NSData *data = [[NSData alloc] initWithBase64EncodedString:dataStr options:0];
            id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            if ([result isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)result;
                NSString *methodName = dict[@"func"];
                NSDictionary *params = dict[@"params"];
                NSString *callBackId = dict[@"__callback_id"];
                BOOL needCallback = [dict[@"needCallback"] boolValue];
                
                //把webView和webVC拼进params, 交互方法可能需要该参数
                NSMutableDictionary *sendParams = nil;
                if ([params isKindOfClass:[NSDictionary class]]) {
                    sendParams = [NSMutableDictionary dictionaryWithDictionary:params];
                    if (_webView != nil) {
                        [sendParams setObject:_webView forKey:@"webView"];
                    }
                    if (_webVC != nil) {
                        [sendParams setObject:_webVC forKey:@"webVC"];
                    }
                }
                
                if (needCallback) {
                    __weak  WKWebView *weakWebView = _webView;
                    [self interactWitMethodName:methodName params:sendParams callback:^(id response) {
                        NSString *js = [NSString stringWithFormat:@"RbJSBridge._handleMessageFromApp('%@','%@');", callBackId, response];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakWebView evaluateJavaScript:js completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                            }];
                        });
                    }];
                } else {
                    [self interactWitMethodName:methodName params:sendParams callback:nil];
                }
            }
        }
    }
}

@end
