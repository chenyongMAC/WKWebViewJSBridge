//
//  URWKWebViewController.h
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/7.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, URWKWebViewType) {
    URWKWebViewType_URL,
    URWKWebViewType_HTML,
};

@interface URWKWebViewController : UIViewController

@property (nonatomic, assign) BOOL isNavHidden;

- (void)loadWebViewWithString:(NSString *)string type:(URWKWebViewType)type;

@end
