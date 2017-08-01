//
//  WKWebViewJSBridge+InteractFunction.m
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/1.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import "WKWebViewJSBridge+InteractFunction.h"

@implementation WKWebViewJSBridge (InteractFunction)

- (void)sendInfoToNative:(id)params {
    NSLog(@"sendInfoToNative :%@",params);
}

- (void)getInfoFromNative:(id)params :(void(^)(id response))callBack {
    NSLog(@"params %@",params);
    NSString *str = @"'Hi Jack!'";
    callBack(str);
    
}

@end
