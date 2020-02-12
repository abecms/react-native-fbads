//
//  EXRewardedVideoAdManager.m
//  ReactNativeAdsFacebook
//
//  Created by Yann Luccin on 03/12/2019.
//  Copyright © 2019 Suraj Tiwari . All rights reserved.
//
#import "EXRewardedVideoAdManager.h"
#import "EXUnversioned.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

@interface EXRewardedVideoAdManager () <FBRewardedVideoAdDelegate>

@property (nonatomic, strong) RCTPromiseResolveBlock loadedResolve;
@property (nonatomic, strong) RCTPromiseRejectBlock loadedReject;
@property (nonatomic, strong) RCTPromiseResolveBlock showResolve;
@property (nonatomic, strong) RCTPromiseRejectBlock showReject;
@property (nonatomic, strong) FBRewardedVideoAd *rewardedVideoAd;
@property (nonatomic, strong) UIViewController *adViewController;

@end

@implementation EXRewardedVideoAdManager

RCT_EXPORT_MODULE(CTKRewardedVideoAdManager);

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onRewarded",@"onClosed"];
}

RCT_EXPORT_METHOD(
  showAd:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
)
{
  dispatch_async(dispatch_get_main_queue(), ^{ 
    RCTAssert(_showResolve == nil && _showReject == nil, @"Only one `showAd` can be called at once");

    if (_rewardedVideoAd != nil && _rewardedVideoAd.isAdValid) {
      [self->_rewardedVideoAd showAdFromRootViewController:RCTPresentedViewController()];
      _showResolve = resolve;
      _showReject = reject;
    }
  });
}

RCT_EXPORT_METHOD(
  loadAd:(NSString *)placementId
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
)
{
  RCTAssert(_loadedResolve == nil && _loadedReject == nil, @"Only one `showAd` can be called at once");
  
  _loadedResolve = resolve;
  _loadedReject = reject;
    
  _rewardedVideoAd = [[FBRewardedVideoAd alloc] initWithPlacementID:placementId];
  _rewardedVideoAd.delegate = self;
  [self->_rewardedVideoAd loadAd];
}

#pragma mark - FBRewardedVideoAdDelegate

- (void)rewardedVideoAdDidLoad:(__unused FBRewardedVideoAd *)rewardedVideoAd
{
  RCTLogInfo(@"Rewarded video ad is loaded and ready to be displayed!");
  _loadedResolve(@(TRUE));
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error
{
  RCTLogInfo(@"Rewarded video ad failed to load");
  _loadedReject(@"E_FAILED_TO_LOAD", [error localizedDescription], error);
  
  [self cleanUpAd];
}

- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd
{
  
}

- (void) rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd
{
  RCTLogInfo(@"Rewarded video completed!");
  [self sendEventWithName:@"onRewarded" body:@{ @"rewarded": @(TRUE), @"closed": @(FALSE) }];
  _showResolve(@(TRUE));
  [self cleanUpAd];
}

- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd
{
  RCTLogInfo(@"Rewarded video ad closed!");
  [self sendEventWithName:@"onClosed" body:@{ @"rewarded": @(FALSE), @"closed": @(TRUE) }];
  [self cleanUpAd];
}

- (void)cleanUpAd
{
  _loadedResolve = nil;
  _loadedReject = nil;
  _showResolve = nil;
  _showReject = nil;
  _rewardedVideoAd = nil;
  _adViewController = nil;
}

@end
