//
//  XMPPOutOfBandHTTPTransferHandler.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 06/07/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPOutOfBandHTTPTransferHandler.h"

@class XMPPOutOfBandHTTPTransferItem;

@interface XMPPOutOfBandHTTPTransferHandler () <NSURLSessionDataDelegate>

@property (strong, nonatomic, readonly) XMPPHTTPFileUpload *xmppHTTPFileUpload;
@property (strong, nonatomic, readonly) XMPPJID *uploadServiceJID;
@property (strong, nonatomic, readonly) NSURLSession *transferSession;
@property (strong, nonatomic, readonly) NSMutableDictionary<NSNumber *, __kindof XMPPOutOfBandHTTPTransferItem *> *transferItemIndex;

@end

@interface XMPPOutOfBandHTTPTransferItem : NSObject

@property (strong, nonatomic, readonly) XMPPOutOfBandTransfer *transfer;
@property (strong, nonatomic, readonly) NSProgress *progress;

- (instancetype)initWithTransfer:(XMPPOutOfBandTransfer *)transfer progress:(NSProgress *)progress;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface XMPPOutOfBandHTTPUploadItem : XMPPOutOfBandHTTPTransferItem

@property (strong, nonatomic, readonly) XMPPOutOfBandUpload *upload;
@property (strong, nonatomic, readonly) XMPPSlot *slot;

- (instancetype)initWithUpload:(XMPPOutOfBandUpload *)upload progress:(NSProgress *)progress slot:(XMPPSlot *)slot;
- (instancetype)initWithTransfer:(XMPPOutOfBandTransfer *)transfer progress:(NSProgress *)progress NS_UNAVAILABLE;

@end

@interface XMPPOutOfBandHTTPDownloadItem : XMPPOutOfBandHTTPTransferItem

@property (strong, nonatomic, readonly) XMPPOutOfBandDownload *download;

- (instancetype)initWithDownload:(XMPPOutOfBandDownload *)download progress:(NSProgress *)progress;
- (instancetype)initWithTransfer:(XMPPOutOfBandTransfer *)transfer progress:(NSProgress *)progress NS_UNAVAILABLE;

@end

@implementation XMPPOutOfBandHTTPTransferHandler

- (instancetype)initWithURLSessionConfiguration:(NSURLSessionConfiguration *)URLSessionConfiguration XMPPHTTPFileUpload:(XMPPHTTPFileUpload *)xmppHTTPFileUpload uploadServiceJID:(XMPPJID *)uploadServiceJID
{
    self = [super init];
    if (self) {
        _xmppHTTPFileUpload = xmppHTTPFileUpload;
        _uploadServiceJID = uploadServiceJID;
        _transferSession = [NSURLSession sessionWithConfiguration:URLSessionConfiguration delegate:self delegateQueue:nil];
        _transferItemIndex = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)handleUpload:(XMPPOutOfBandUpload *)upload
{
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:upload.data.length];
    [upload beginWithProgress:progress];
    
    [self.xmppHTTPFileUpload requestSlotFromService:self.uploadServiceJID
                                           filename:[NSUUID UUID].UUIDString
                                               size:upload.data.length
                                        contentType:upload.MIMEType
                                         completion:^(XMPPSlot * _Nullable slot, XMPPIQ * _Nullable responseIq, NSError * _Nullable error) {
                                             if (error) {
                                                 [upload failWithError:error];
                                                 return;
                                             }
                                             [self processUploadItem:[[XMPPOutOfBandHTTPUploadItem alloc] initWithUpload:upload progress:progress slot:slot]];
                                         }];
}

- (void)handleDownload:(XMPPOutOfBandDownload *)download
{
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:0];
    [download beginWithProgress:progress];
    
    XMPPOutOfBandHTTPDownloadItem *downloadItem = [[XMPPOutOfBandHTTPDownloadItem alloc] initWithDownload:download progress:progress];
    NSURLSessionTask *downloadTask = [self.transferSession dataTaskWithURL:download.URL];
    
    [self.transferSession.delegateQueue addOperationWithBlock:^{
        self.transferItemIndex[@(downloadTask.taskIdentifier)] = downloadItem;
        [downloadTask resume];
    }];
}

- (void)processUploadItem:(XMPPOutOfBandHTTPUploadItem *)uploadItem
{
    NSMutableURLRequest *putRequest = [uploadItem.slot.putRequest mutableCopy];
    putRequest.allHTTPHeaderFields = @{@"Content-Type": uploadItem.upload.MIMEType};
    NSURLSessionTask *uploadTask = [self.transferSession uploadTaskWithRequest:putRequest fromData:uploadItem.upload.data];
    
    [self.transferSession.delegateQueue addOperationWithBlock:^{
        self.transferItemIndex[@(uploadTask.taskIdentifier)] = uploadItem;
        [uploadTask resume];
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    XMPPOutOfBandHTTPTransferItem *transferItem = self.transferItemIndex[@(task.taskIdentifier)];
    if (![transferItem isKindOfClass:[XMPPOutOfBandHTTPUploadItem class]]) {
        return;
    }
    transferItem.progress.totalUnitCount = totalBytesExpectedToSend;
    transferItem.progress.completedUnitCount = MIN(totalBytesSent, transferItem.progress.totalUnitCount - 1);   // leave one unit until an HTTP 200 response is received
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
    
    __kindof XMPPOutOfBandHTTPTransferItem *transferItem = self.transferItemIndex[@(dataTask.taskIdentifier)];
    if (((NSHTTPURLResponse *)response).statusCode / 100 != 2) {
        [transferItem.transfer failWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                 code:NSURLErrorBadServerResponse
                                                             userInfo:@{NSURLErrorFailingURLErrorKey: response.URL}]];
        [self.transferItemIndex removeObjectForKey:@(dataTask.taskIdentifier)];
        return;
    }
    
    if ([transferItem isKindOfClass:[XMPPOutOfBandHTTPUploadItem class]]) {
        transferItem.progress.completedUnitCount = transferItem.progress.totalUnitCount;
    }
    
    if ([transferItem isKindOfClass:[XMPPOutOfBandHTTPDownloadItem class]]) {
        XMPPOutOfBandHTTPDownloadItem *downloadItem = transferItem;
        [downloadItem.download provideMIMEType:response.MIMEType];
        if (response.expectedContentLength != NSURLResponseUnknownLength) {
            downloadItem.progress.totalUnitCount = response.expectedContentLength;
        }
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    __kindof XMPPOutOfBandHTTPTransferItem *transferItem = self.transferItemIndex[@(dataTask.taskIdentifier)];
    if (![transferItem isKindOfClass:[XMPPOutOfBandHTTPDownloadItem class]]) {
        return;
    }
    XMPPOutOfBandHTTPDownloadItem *downloadItem = transferItem;
    [downloadItem.download provideDataChunk:data];
    
    if (![downloadItem.progress isIndeterminate]) {
        downloadItem.progress.completedUnitCount += data.length;
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    __kindof XMPPOutOfBandHTTPTransferItem *transferItem = self.transferItemIndex[@(task.taskIdentifier)];
    [self.transferItemIndex removeObjectForKey:@(task.taskIdentifier)];
    
    if (error) {
        [transferItem.transfer failWithError:error];
        return;
    }
    
    if ([transferItem isKindOfClass:[XMPPOutOfBandHTTPUploadItem class]]) {
        XMPPOutOfBandHTTPUploadItem *uploadItem = transferItem;
        [uploadItem.upload completeWithDownloadURL:uploadItem.slot.getURL];
    }
    
    if ([transferItem isKindOfClass:[XMPPOutOfBandHTTPDownloadItem class]]) {
        XMPPOutOfBandHTTPDownloadItem *downloadItem = transferItem;
        [downloadItem.download complete];
    }
}

@end

@implementation XMPPOutOfBandHTTPTransferItem

- (instancetype)initWithTransfer:(XMPPOutOfBandTransfer *)transfer progress:(NSProgress *)progress
{
    self = [super init];
    if (self) {
        _transfer = transfer;
        _progress = progress;
    }
    return self;
}

@end

@implementation XMPPOutOfBandHTTPUploadItem

- (instancetype)initWithUpload:(XMPPOutOfBandUpload *)upload progress:(NSProgress *)progress slot:(XMPPSlot *)slot
{
    self = [super initWithTransfer:upload progress:progress];
    if (self) {
        _upload = upload;
        _slot = slot;
    }
    return self;
}

@end

@implementation XMPPOutOfBandHTTPDownloadItem

- (instancetype)initWithDownload:(XMPPOutOfBandDownload *)download progress:(NSProgress *)progress
{
    self = [super initWithTransfer:download progress:progress];
    if (self) {
        _download = download;
    }
    return self;
}

@end
