//
//  ZBNAudioDownLoader.h
//  ZBNRemotePayer
//
//  Created by 周芳圆 on 2019/11/15.
//  Copyright © 2019 周不晒. All rights reserved.
//  下载器 处理相关的下载操作

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZBNAudioDownLoaderDelegate <NSObject>
/**
 * 正在下载
 */
- (void)zbn_downLoaderLoading;

@end

@interface ZBNAudioDownLoader : NSObject
/**
 * 已经下载的大小
 */
@property (nonatomic, assign) long long loadedSize;
/**
 * 区间
 */
@property (nonatomic, assign) long long offset;
/**
 * contenttype
 */
@property (nonatomic, copy) NSString *contentType;
/**
 * 总大小
 */
@property (nonatomic, assign) long long totalSize;
/**
 * 代理属性
 */
@property (nonatomic, weak) id<ZBNAudioDownLoaderDelegate> delegate;
/**
 * 根据url和区间进行下载
 * @param url 地址
 * @param offset 区间:从哪里开始下载
 */
- (void)zbn_downLoadWithURL:(NSURL *)url offset:(long long)offset;

@end

NS_ASSUME_NONNULL_END
