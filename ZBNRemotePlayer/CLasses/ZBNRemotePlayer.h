//
//  ZBNRemotePlayer.h
//  ZBNRemotePlayer
//
//  Created by 周芳圆 on 2019/11/15.
//  Copyright © 2019 周芳圆. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 播放器的状态, 用于UI界面的状态显示
 - ZBNRemotePlayerStateUnknown: 未知(还没有开始播放等..)
 - ZBNRemotePlayerStateLoading: 正在加载
 - ZBNRemotePlayerStatePlaying: 正在播放
 - ZBNRemotePlayerStateStopped: 停止
 - ZBNRemotePlayerStatePause  : 暂停
 - ZBNRemotePlayerStateFailed : 失败(没网,缓存失败,地址错误..)
 */
typedef enum : NSUInteger {
    ZBNRemotePlayerStateUnknown = 0,
    ZBNRemotePlayerStateLoading = 1,
    ZBNRemotePlayerStatePlaying = 2,
    ZBNRemotePlayerStateStopped = 3,
    ZBNRemotePlayerStatePause   = 4,
    ZBNRemotePlayerStateFailed  = 5
} ZBNRemotePlayerState;

@interface ZBNRemotePlayer : NSObject

/**
 根据URL地址进行播放音频
 
 @param url url
 */
- (void)zbn_playWithURL:(NSURL *)url;

/**
 暂停当前音频
 */
- (void)zbn_pause;

/**
 继续播放
 */
- (void)zbn_resume;

/**
 停止播放
 */
- (void)zbn_stop;

/**
 快速播放到某个时间点
 
 @param time 时间
 */
- (void)zbn_seekToTime: (NSTimeInterval)time;

/** 速率 */
@property (nonatomic, assign) float rate;

/** 声音 */
@property (nonatomic, assign) float volume;
/**静音*/
@property (nonatomic, assign) BOOL mute;
/** 进度 */
@property (nonatomic, assign) float progress;
/** 总时长 */
@property (nonatomic, assign, readonly) double duration;
/** 当前时长 */
@property (nonatomic, assign, readonly) double currentTime;
/** 播放地址url */
@property (nonatomic, strong, readonly) NSURL *url;
/** 加载进度 */
@property (nonatomic, assign, readonly) float loadProgress;
/** 状态 */
@property (nonatomic, assign, readonly) ZBNRemotePlayerState state;
/** 状态改变block */
@property (nonatomic, copy) void(^stateChange)(ZBNRemotePlayerState state);
/** 播放结束block */
@property (nonatomic, copy) void(^playEndBlock)();

@end

NS_ASSUME_NONNULL_END
