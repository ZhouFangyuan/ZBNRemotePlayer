//
//  ZBNAudioFileTool.h
//  ZBNRemotePayer
//
//  Created by 周芳圆 on 2019/11/15.
//  Copyright © 2019 周不晒. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBNAudioFileTool : NSObject
/**
 * 根据url查找沙盒路径
 */
+ (NSString *)zbn_cachePathWithURL:(NSURL *)url;
/**
 * 根据url查找临时文件路径
 */
+ (NSString *)zbn_tmpPathWithURL:(NSURL *)url;
/**
 * 判断沙盒路径是否存在
 */
+ (BOOL)zbn_isCacheFileExists:(NSURL *)url;
/**
 * 判断临时文件存储路径是否存在
 */
+ (BOOL)zbn_isTmpFileExists:(NSURL *)url;
/**
 * 根据url拿到contentType
 */
+ (NSString *)zbn_contentTypeWithURL:(NSURL *)url;
/**
 * 根据url计算沙盒缓存的大小
 */
+ (long long)zbn_cacheFileSizeWithURL:(NSURL *)url;
/**
 * 根据url计算临时缓存的大小
 */
+ (long long)zbn_tmpFileSizeWithURL:(NSURL *)url;
/**
 * 根据url移除临时文件
 */
+ (void)zbn_removeTmpFileWithURL:(NSURL *)url;
/**
 * 将临时文件移动到沙盒
 */
+ (void)zbn_moveTmpPathToCachePath:(NSURL *)url;






@end

NS_ASSUME_NONNULL_END
