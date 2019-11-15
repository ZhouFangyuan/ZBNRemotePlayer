//
//  ZBNResourceLoader.m
//  ZBNRemotePayer
//
//  Created by 周芳圆 on 2019/11/15.
//  Copyright © 2019 周不晒. All rights reserved.
//

#import "ZBNResourceLoader.h"
#import "ZBNAudioFileTool.h"
#import "ZBNAudioDownLoader.h"

@interface ZBNResourceLoader () <ZBNAudioDownLoaderDelegate>

@property (nonatomic, strong) ZBNAudioDownLoader *downLoader;

@property (nonatomic, strong) NSMutableArray <AVAssetResourceLoadingRequest *> *loadingRequests;

@end

@implementation ZBNResourceLoader

#pragma mark - 懒加载

- (ZBNAudioDownLoader *)downLoader
{
    if (!_downLoader) {
        _downLoader = [[ZBNAudioDownLoader alloc] init];
        _downLoader.delegate = self;
    }
    return _downLoader;
}

- (NSMutableArray<AVAssetResourceLoadingRequest *> *)loadingRequests
{
    if (!_loadingRequests) {
        _loadingRequests = [NSMutableArray array];
    }
    return _loadingRequests;
}

- (void)handleAllRequest
{
    NSMutableArray *complete = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.loadingRequests) {
        // 直接拿本地的临时缓存数据, 给请求, 让请求, 帮我们返回给服务器
        NSURL *url = loadingRequest.request.URL;
        //1. 填充信息头
        loadingRequest.contentInformationRequest.contentType = self.downLoader.contentType;
        loadingRequest.contentInformationRequest.contentLength = self.downLoader.totalSize;
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        //2. 返回数据
        //2.1 计算请求的数据区间
        long long requestOffset = loadingRequest.dataRequest.requestedOffset;
        if (loadingRequest.dataRequest.currentOffset != 0) {
            requestOffset = loadingRequest.dataRequest.currentOffset;
        }
        long long requestLen = loadingRequest.dataRequest.requestedLength;
        //2.2 根据请求的区间, 看下,本地的临时缓存,能够返回多少
        long long responseOffset = requestOffset - self.downLoader.offset;
        long long responseLength = MIN(requestLen, self.downLoader.offset + self.downLoader.loadedSize - requestOffset);
        
        NSData *data = [NSData dataWithContentsOfFile:[ZBNAudioFileTool zbn_tmpPathWithURL:url] options:NSDataReadingMappedIfSafe error:nil];
        if (data.length == 0) {
            data = [NSData dataWithContentsOfFile:[ZBNAudioFileTool zbn_cachePathWithURL:url] options:NSDataReadingMappedIfSafe error:nil];
        }
        NSData *subData = [data subdataWithRange:NSMakeRange(responseOffset, responseLength)];
        [loadingRequest.dataRequest respondWithData:subData];
        //3. 完成请求(byteRange) (必须, 是这个请求的数据, 全部都给完了, 完成)
        if (requestLen == responseLength) {
            [loadingRequest finishLoading];
            [complete addObject:loadingRequest];
        }
    }
    
    [self.loadingRequests removeObjectsInArray:complete];
}


// 只要播放器, 想要播放某个资源, 都会让资源组织者, 命令资源请求者, 调用这个方法, 去发送请求
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.loadingRequests addObject:loadingRequest];
    NSURL *url = loadingRequest.request.URL;
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestOffset = loadingRequest.dataRequest.currentOffset;
    }
    
    if ([ZBNAudioFileTool zbn_isCacheFileExists:url]) {
        // 三个步骤, 直接响应数据
        [self handleRequestWithLoadingRequest:loadingRequest];
        return YES;
    }
    
    if (self.downLoader.loadedSize == 0) {
        [self.downLoader zbn_downLoadWithURL:url offset:0];
        return YES;
    }
    
    if (requestOffset < self.downLoader.offset || requestOffset > self.downLoader.offset + self.downLoader.loadedSize + 666) {
        [self.downLoader zbn_downLoadWithURL:url offset:0];
        return YES;
    }
    
    // 请求的数据, 就在正在下载当中
    // 在正在下载数据当中, data -> 播放器
    [self handleAllRequest];
    return YES;
}

// 取消某个请求的时候调用
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.loadingRequests removeObject:loadingRequest];
}

#pragma mark - 私有方法
- (void)handleRequestWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *url = loadingRequest.request.URL;
    //1. 填充信息头
    loadingRequest.contentInformationRequest.contentType = [ZBNAudioFileTool zbn_contentTypeWithURL:url];
    loadingRequest.contentInformationRequest.contentLength = [ZBNAudioFileTool zbn_cacheFileSizeWithURL:url];
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    //2. 响应数据
    NSData *data = [NSData dataWithContentsOfFile:[ZBNAudioFileTool zbn_cachePathWithURL:url] options:NSDataReadingMappedIfSafe error:nil];
    long long requestOffset = loadingRequest.dataRequest.requestedOffset;
    long long requestlen = loadingRequest.dataRequest.requestedLength;
    NSData *subData = [data subdataWithRange:NSMakeRange(requestOffset, requestlen)];
    [loadingRequest.dataRequest respondWithData:subData];
    //3. 完成这个请求
    [loadingRequest finishLoading];
}


#pragma mark - 下载协议
- (void)zbn_downLoaderLoading
{
    [self handleAllRequest];
}


@end
