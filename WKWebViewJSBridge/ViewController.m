//
//  ViewController.m
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/1.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import "ViewController.h"
#import "WKWebViewJSBridge.h"
#import "URWKWebViewController.h"

extern NSString * const RbJSBridgeEvent;

@interface ViewController () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation ViewController

- (void)dealloc {
    [_webView.configuration.userContentController removeScriptMessageHandlerForName:RbJSBridgeEvent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 50, 30)];
    [btn setTitle:@"hello" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
//    [self initWebView];
}

- (void)clickAction {
    URWKWebViewController *wkcontroller = [[URWKWebViewController alloc] init];
    NSString *urlStr = [NSString stringWithFormat:@"file://%@",[[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"]];
    [wkcontroller loadWebViewWithString:urlStr type:URWKWebViewType_URL];
    [self.navigationController pushViewController:wkcontroller animated:YES];
}

- (void)initWebView {
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:[WKWebViewJSBridge shareInstance].defaultConfiguration];
    NSString *urlStr = [NSString stringWithFormat:@"file://%@",[[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"]];
    NSURL *url = [NSURL URLWithString:urlStr];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    
    [self.view addSubview:_webView];
    
    [WKWebViewJSBridge bridgeWebView:_webView];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"66===%s", __FUNCTION__);
    
    [webView evaluateJavaScript:[WKWebViewJSBridge shareInstance].injectJS completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
    
}

@end
