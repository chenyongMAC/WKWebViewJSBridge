//
//  URWKWebViewController.m
//  WKWebViewJSBridge
//
//  Created by chenyong on 2017/8/7.
//  Copyright © 2017年 chenyong. All rights reserved.
//

#import "URWKWebViewController.h"
#import <WebKit/WebKit.h>
#import "WKWebViewJSBridge.h"
#import "NSURLProtocol+WebKitSupport.h"

static void *URWkWebViewContext = &URWkWebViewContext;

@interface URWKWebViewController () <WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, assign) URWKWebViewType loadType;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIBarButtonItem* customBackBarItem;
@property (nonatomic, strong) UIBarButtonItem* closeButtonItem;
@property (nonatomic, strong) NSMutableArray* snapShotsArray;

@end

@implementation URWKWebViewController

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _needIntercept = NO;
        _isNavHidden = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
    [self.view addSubview:self.progressView];
    
    [self loadWebView];
    [self addNaviBarItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_isNavHidden) {
        self.navigationController.navigationBarHidden = YES;
        //创建一个假状态栏
        UIView *statusBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
        statusBarView.backgroundColor = [UIColor redColor];
        [self.view addSubview:statusBarView];
    } else {
        self.navigationController.navigationBarHidden = NO;
    }
    
    if (_needIntercept) {
        for (NSString* scheme in @[@"http", @"https"]) {
            [NSURLProtocol wk_registerScheme:scheme];
        }
    } else {
        for (NSString* scheme in @[@"http", @"https"]) {
            [NSURLProtocol wk_unregisterScheme:scheme];
        }
    }
}

#pragma mark - Public
- (void)loadWebViewWithString:(NSString *)string type:(URWKWebViewType)type {
    self.urlString = string;
    self.loadType = type;
}

+ (void)updateUserAgent {
    //全局修改UserAgent
    NSString *nativeAgent = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"];
    if (![nativeAgent hasSuffix:@" MonkeyCenter/1.0.0 rubikui"]) {
    }
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString *oldAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    //add my info to the new agent
    NSString *newAgent = [oldAgent stringByAppendingString:@" MonkeyCenter/1.0.0 rubikui"];
    //regist the new agent
    NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:newAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Action
- (void)customBackItemClicked {
    if (self.webView.goBack) {
        [self.webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)closeItemClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.webView) {
        self.progressView.alpha = 1.0f;
        BOOL animated = self.webView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.webView.estimatedProgress animated:animated];
        
        if (self.webView.estimatedProgress > 0.999f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.progressView.alpha = 0.0f;
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKNavigationDelegate
//类比webView的shouldStartLoadWithRequest方法
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        //可增加域名判断, 对跨域手动跳转
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.title = self.webView.title;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
    
    [self evaluateJSInit];
    
}

- (void)evaluateJSInit {
    NSString *js = [NSString stringWithFormat:@"RbJSBridge._handleMessageFromApp('%@');", @"{\"__msg_type\":\"event\",\"__event_id\":\"sys:init\"}"];
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable i, NSError * _Nullable error) {
        NSLog(@"11");
    }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    //Failed
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.progressView.hidden = NO;
}

//HTTPS触发，若需要证书验证可处理，若不需要直接回调
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

#pragma mark - WKUIDelegate 
//alert
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:
                      UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                          completionHandler();
                      }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:
                                @"confirm" message:@"JS调用confirm"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
                                                  completionHandler(YES);
                                              }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                                  completionHandler(NO);
                                              }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:
                                prompt message:defaultText
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                  completionHandler([[alert.textFields lastObject] text]);
                                              }]];
    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - Private
- (void)loadWebView {
    switch (self.loadType) {
        case URWKWebViewType_URL: {
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
            [self.webView loadRequest:request];
            
            break;
        }
        case URWKWebViewType_RbUserAgent_URL: {
            __weak typeof(self) weakSelf = self;
            [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                NSString *userAgent = result;
                if (![result hasSuffix:@" MonkeyCenter/1.0.0 rubikui"]) {
                    NSString *newUserAgent = [userAgent stringByAppendingString:@" MonkeyCenter/1.0.0 rubikui"];
                    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent":newUserAgent}];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                [strongSelf.webView loadRequest:request];
            }];
            
            break;
        }
        case URWKWebViewType_HTML: {
            NSString *path = [[NSBundle mainBundle] pathForResource:self.urlString ofType:@"html"];
            NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            [self.webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
            
            break;
        }
        default:
            break;
    }
}

- (void)refreshBarItemClick {
    [self.webView reload];
}

- (void)addNaviBarItem {
    UIBarButtonItem *roadLoad = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBarItemClick)];
    self.navigationItem.rightBarButtonItem = roadLoad;
}

- (void)updateNavigationItems {
    if (self.webView.canGoBack) {
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        
        [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem,self.customBackBarItem,self.closeButtonItem] animated:NO];
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem]];
    }
}

#pragma mark - Lazy init
- (WKWebView *)webView {
    if (_webView == nil) {
        WKWebViewConfiguration *configuration = [WKWebViewJSBridge shareInstance].defaultConfiguration;
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
        [WKWebViewJSBridge bridgeWebView:_webView webVC:self];
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        _webView.allowsBackForwardNavigationGestures = YES;
        [_webView sizeToFit];
        [_webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:URWkWebViewContext];
    }
    return _webView;
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        if (_isNavHidden) {
            _progressView.frame = CGRectMake(0, 20, self.view.bounds.size.width, 3);
        } else {
            _progressView.frame = CGRectMake(0, 64, self.view.bounds.size.width, 3);
        }
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [UIColor redColor];
    }
    return _progressView;
}

- (UIBarButtonItem*)customBackBarItem {
    if (_customBackBarItem == nil) {
        UIImage* backItemImage = [[UIImage imageNamed:@"wkjsbridge_item_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage* backItemHlImage = [[UIImage imageNamed:@"wkjsbridge_item_back_hl"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIButton* backButton = [[UIButton alloc] init];
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
        [backButton setImage:backItemImage forState:UIControlStateNormal];
        [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
        [backButton sizeToFit];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return _customBackBarItem;
}

- (UIBarButtonItem*)closeButtonItem {
    if (_closeButtonItem == nil) {
        _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeItemClicked)];
    }
    return _closeButtonItem;
}

@end







