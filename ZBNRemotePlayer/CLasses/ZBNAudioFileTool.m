//
//  ZBNAudioFileTool.m
//  ZBNRemotePayer
//
//  Created by 周芳圆 on 2019/11/15.
//  Copyright © 2019 周不晒. All rights reserved.
//

#import "ZBNAudioFileTool.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()

@implementation ZBNAudioFileTool
/**
 * 根据url查找沙盒路径
 */
+ (NSString *)zbn_cachePathWithURL:(NSURL *)url
{
    return [kCachePath stringByAppendingPathComponent:url.lastPathComponent];
}
/**
 * 根据url查找临时文件路径
 */
+ (NSString *)zbn_tmpPathWithURL:(NSURL *)url
{
    return [kTmpPath stringByAppendingPathComponent:url.lastPathComponent];
}

/**
 * 判断沙盒路径是否w存在
 */
+ (BOOL)zbn_isCacheFileExists:(NSURL *)url
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self zbn_cachePathWithURL:url]];
}

/**
 * 判断临时文件存储路径是否存在
 */
+ (BOOL)zbn_isTmpFileExists:(NSURL *)url
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self zbn_tmpPathWithURL:url]];
}
/**
 * 根据url拿到contentType
 */
+ (NSString *)zbn_contentTypeWithURL:(NSURL *)url
{
    NSString *fileExtension = url.absoluteString.pathExtension;
    
    CFStringRef contentTypeCF = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(fileExtension), NULL);
    
    NSString *contentType = CFBridgingRelease(contentTypeCF);
    
    return contentType;
}
/**
 * 根据url计算沙盒缓存的大小
 */
+ (long long)zbn_cacheFileSizeWithURL:(NSURL *)url
{
    // 判断文件是否存在
    if (![self zbn_isCacheFileExists:url]) {
        return 0;
    }
    // 计算大小
    NSString *path = [self zbn_cachePathWithURL:url];
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfo[NSFileSize] longLongValue];
    
}
/**
 * 根据url计算临时缓存的大小
 */
+ (long long)zbn_tmpFileSizeWithURL:(NSURL *)url
{
    if (![self zbn_isTmpFileExists:url]) {
        return 0;
    }
    
    NSString *path = [self zbn_tmpPathWithURL:url];
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return [fileInfo[NSFileSize] longLongValue];
}
/**
 * 根据url移除临时文件
 */
+ (void)zbn_removeTmpFileWithURL:(NSURL *)url
{
    if ([self zbn_isTmpFileExists:url]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self zbn_tmpPathWithURL:url] error:nil];
    }
}
/**
 * 将临时文件移动到沙盒
 */
+ (void)zbn_moveTmpPathToCachePath:(NSURL *)url
{
    if ([self zbn_isTmpFileExists:url]) {
        NSString *tmpPath = [self zbn_tmpPathWithURL:url];
        NSString *cachePath = [self zbn_cachePathWithURL:url];
        
        [[NSFileManager defaultManager] moveItemAtPath:tmpPath toPath:cachePath error:nil];
    }
}

@end

