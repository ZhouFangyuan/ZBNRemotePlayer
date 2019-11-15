//
//  ZBNAudioDownLoader.m
//  ZBNRemotePayer
//
//  Created by 周芳圆 on 2019/11/15.
//  Copyright © 2019 周不晒. All rights reserved.
//

#import "ZBNAudioDownLoader.h"
#import "ZBNAudioFileTool.h"

@interface ZBNAudioDownLoader () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
/** 输出流 */
@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) NSURL *url;

@end

@implementation ZBNAudioDownLoader

- (NSURLSession *)session
{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (void)zbn_downLoadWithURL:(NSURL *)url offset:(long long)offset
{
    self.url = url;
    self.offset = offset;
    
    [self cancel];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    [task resume];
}

/**
 * 取消下载
 */
- (void)cancel
{
    [self.session invalidateAndCancel];
    self.session = nil;
    // 清理缓存
    [ZBNAudioFileTool zbn_removeTmpFileWithURL:self.url];
    self.loadedSize = 0;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    self.totalSize = [[[httpResponse.allHeaderFields[@"Content-Range"] componentsSeparatedByString:@"/"] lastObject] longLongValue];
    self.contentType = httpResponse.MIMEType;
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:[ZBNAudioFileTool zbn_tmpPathWithURL:self.url] append:YES];
    [self.outputStream open];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    self.loadedSize += data.length;
    [self.outputStream write:data.bytes maxLength:data.length];
    if ([self.delegate respondsToSelector:@selector(zbn_downLoaderLoading)]) {
        [self.delegate zbn_downLoaderLoading];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error == nil) {
        if ([ZBNAudioFileTool zbn_tmpFileSizeWithURL:self.url] == self.totalSize) {
            [ZBNAudioFileTool zbn_moveTmpPathToCachePath:self.url];
        }
    }
}


@end
