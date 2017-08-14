//
//  NSURLProtocol+WebKitSupport.m
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/10.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import "NSURLProtocol+WebKitSupport.h"
#import <WebKit/WebKit.h>

@implementation NSURLProtocol (WebKitSupport)

#pragma mark - Private
FOUNDATION_STATIC_INLINE Class ContextControllerClass() {
    static Class cls;
    if (!cls) {
        cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector() {
    return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}

FOUNDATION_STATIC_INLINE SEL UnregisterSchemeSelector() {
    return NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
}


#pragma mark - Public
+ (void)wk_registerScheme:(NSString*)scheme {
    Class cls = ContextControllerClass();
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
    }
#pragma clang diagnostic pop
}

+ (void)wk_unregisterScheme:(NSString*)scheme {
    Class cls = ContextControllerClass();
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

@end
