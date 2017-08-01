//
//  WKWebViewJSBridge+InteractFunction.h
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/1.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import "WKWebViewJSBridge.h"

@interface WKWebViewJSBridge (InteractFunction)

- (void)sendInfoToNative:(id)params;
- (void)getInfoFromNative:(id)params :(void(^)(id response))callBack;

@end
