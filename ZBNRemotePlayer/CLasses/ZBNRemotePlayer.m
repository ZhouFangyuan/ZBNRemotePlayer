//
//  ZBNRemotePlayer.m
//  ZBNRemotePlayer
//
//  Created by 周芳圆 on 2019/11/15.
//  Copyright © 2019 周芳圆. All rights reserved.
//

#import "ZBNRemotePlayer.h"
#import "ZBNResourceLoader.h"
#import <AVFoundation/AVFoundation.h>

@interface ZBNRemotePlayer ()
{
    BOOL _isUserPause;
}

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) ZBNResourceLoader *resourceloader;

@end


@implementation ZBNRemotePlayer

#pragma mark -- 懒加载

- (ZBNResourceLoader *)resourceloader
{
    if (!_resourceloader) {
        _resourceloader = [[ZBNResourceLoader alloc] init];
    }
    return _resourceloader;
}


#pragma mark -- 主要API:播放

- (void)zbn_playWithURL:(NSURL *)url
{
    if ([_url isEqual:url]) {
        if (self.state == ZBNRemotePlayerStatePlaying) { // 正在播放
            return;
        }else if (self.state == ZBNRemotePlayerStatePause) { // 暂停
            [self zbn_resume];
        }else if (self.state == ZBNRemotePlayerStateLoading) { // 正在加载
            return;
        }
    }
    
    _url = url;
    // 其实, 系统已经帮我们封装了三个步骤
    // [AVPlayer playerWithURL:url]
    // 1. 资源的请求
    // 2. 资源的组织 AVPlayerItem
    // 3. 资源的播放
    if (self.player.currentItem) {
        // 移除KVO
        [self clearObserver:self.player.currentItem];
    }
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    [asset.resourceLoader setDelegate:self.resourceloader queue:dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    // 监听资源的组织者, 有没有组织好数据
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    // 发通知监听状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playIntrupt) name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    self.player = [AVPlayer playerWithPlayerItem:item];
    
}


#pragma mark -- 播放状态
/** 暂停 */
- (void)zbn_pause
{
    [self.player pause];
    if (self.player) {
        // 手动暂停状态 YES
        _isUserPause = YES;
        self.state = ZBNRemotePlayerStatePause;
    }
}
/** 恢复播放 */
- (void)zbn_resume
{
    [self.player play];
    // 判断状态,如果当前播放器存在并且资源已经加载到可以播放
    if (self.player && self.player.currentItem.playbackLikelyToKeepUp) {
        // 手动暂停状态 NO
        _isUserPause = NO;
        self.state = ZBNRemotePlayerStatePlaying;
    }
}
/** 停止播放 */
- (void)zbn_stop
{
    [self.player pause];
    // 移除监听者 设置相关状态
    [self clearObserver:self.player.currentItem];
    self.player = nil;
    self.state = ZBNRemotePlayerStateStopped;
}

/** 按照某个进度播放 */
- (void)zbn_seekToTime:(NSTimeInterval)time
{
    // CMTime 影片时间
    // 影片时间 -> 秒
    // 秒 -> 影片时间
    
    // 获取当前的时间点(秒)
    double currentTime = self.currentTime + time;
    double totalTime = self.duration;
    [self setProgress:currentTime / totalTime];
}

#pragma mark -- GET && SET

/** 状态 */
- (void)setState:(ZBNRemotePlayerState)state
{
    _state = state;
    
    if (self.stateChange) {
        self.stateChange(state);
    }
}
/** 加载进度 */
- (float)loadProgress
{
    CMTimeRange range = [self.player.currentItem.loadedTimeRanges.lastObject CMTimeRangeValue];
    CMTime loadTime = CMTimeAdd(range.start, range.duration);
    double loadTimeSec = CMTimeGetSeconds(loadTime);
    
    if (self.duration == 0) {
        return 0;
    }
    return loadTimeSec / self.duration;
}

/** 播放速率 */
- (void)setRate:(float)rate
{
    self.player.rate = rate;
}
/** 播放速率 */
- (float)rate
{
    return self.player.rate;
}
/** 播放音量 */
- (void)setVolume:(float)volume
{
    self.player.volume = volume;
}
/** 播放音量 */
- (float)volume
{
    return self.player.volume;
}
/** 静音 */
- (void)setMute:(BOOL)mute
{
    self.player.muted = mute;
}
/** 静音 */
- (BOOL)mute
{
    return self.player.isMuted;
}
/** 总时长 */
- (double)duration
{
    // 将影片时间转换成秒
    double time = CMTimeGetSeconds(self.player.currentItem.duration);
    // 如果time不是数值
    if (isnan(time)) {
        return 0;
    }
    return time;
}
/** 当前时长 */
- (double)currentTime
{
    // 将影片时间转换成秒
    double time = CMTimeGetSeconds(self.player.currentItem.currentTime);
    if (isnan(time)) {
        return 0;
    }
    return time;
}
/** 进度 */
- (float)progress
{
    // 如果当前时长为0
    if (self.duration == 0) {
        return 0;
    }
    return self.currentTime / self.duration;
}
/** 进度 */
- (void)setProgress:(float)progress
{
    
    double totalTime = self.duration;
    double currentTimeSec = totalTime * progress;
    //将秒转换成CMTime
    CMTime playTime = CMTimeMakeWithSeconds(currentTimeSec, NSEC_PER_SEC);
    
    [self.player seekToTime:playTime completionHandler:^(BOOL finished) {
        if (finished) {
            NSLog(@"确认加载这个时间点的数据");
        } else {
            NSLog(@"取消加载这个时间节点的播放数据");
        }
    }];
}


#pragma mark -- 事件监听
/** KVO */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
                NSLog(@"准备完毕, 开始播放");
                [self zbn_resume];
                break;
            case AVPlayerItemStatusFailed:
                NSLog(@"数据准备失败, 无法播放");
                self.state = ZBNRemotePlayerStateFailed;
                break;
            default:
            {
                NSLog(@"未知");
                self.state = ZBNRemotePlayerStateUnknown;
                break;
            }
                
        }
        
    }
    
    if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        // 代表, 是否加载的可以进行播放了
        BOOL playbackLikelyToKeepUp = [change[NSKeyValueChangeNewKey] boolValue];
        if (playbackLikelyToKeepUp) {
            NSLog(@"数据加载的足够播放了");
            if (!_isUserPause) {
                [self zbn_resume];
            }
        } else {
            NSLog(@"数据不够播放");
            self.state = ZBNRemotePlayerStateLoading;
        }
        
    }
    
}
/** 播放结束 */
- (void)playEnd
{
    self.state = ZBNRemotePlayerStateStopped;
    if (self.playEndBlock) {
        self.playEndBlock();
    }
}
/** 播放被打断 */
- (void)playIntrupt
{
    NSLog(@"播放被打断");
    self.state = ZBNRemotePlayerStatePause;
}



#pragma mark -- 其他方法
/** 移除监听者 */
- (void)clearObserver:(AVPlayerItem *)item
{
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}


#pragma mark -- 生命周期方法
- (void)dealloc
{
    [self clearObserver:self.player.currentItem];
}

@end
