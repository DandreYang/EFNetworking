//
//  EFNRequest.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/28.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "EFNRequest.h"

#define Lock() [self.lock lock]
#define Unlock() [self.lock unlock]

static NSString * const EFNRequestLockName = @"vip.dandre.efnetworking.request.lock";

@interface EFNRequest ()

@property (nonatomic, strong, readwrite) NSMutableArray<EFNUploadFormData *> *uploadDataArray;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation EFNRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestType = EFNRequestTypeGeneral;
        _HTTPMethod = EFNHTTPMethodPOST;
        _timeoutInterval = 60.0;
        _enableGeneralServer = YES;
        _enableGeneralHeaders = YES;
        _enableGeneralParameters = YES;
        _enableCache = NO;
        _cacheTimeout = 60 * 30;
        _enableResumeDownload = YES;
    }
    return self;
}

- (NSMutableArray<EFNUploadFormData *> *)uploadDataArray {
    if (!_uploadDataArray) {
        _uploadDataArray = @[].mutableCopy;
    }
    return _uploadDataArray;
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
        _lock.name = EFNRequestLockName;
    }
    
    return _lock;
}

- (void)setUploadFormDatas:(NSArray<EFNUploadFormData *> *)uploadFormDatas {
    Lock();
    self.uploadDataArray.count == 0?:[self.uploadDataArray removeAllObjects];
    uploadFormDatas.count == 0?:[self.uploadDataArray addObjectsFromArray:uploadFormDatas];
    Unlock();
}

- (NSArray<EFNUploadFormData *> *)uploadFormDatas {
    return self.uploadDataArray.copy;
}

#pragma mark - Methods
- (void)addFormDataWithName:(NSString *_Nullable)name fileData:(NSData *_Nonnull)fileData
{
    Lock();
    [self.uploadDataArray addObject:[EFNUploadFormData formDataWithName:name fileData:fileData]];
    Unlock();
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileData:(NSData *_Nonnull)fileData
{
    Lock();
    [self.uploadDataArray addObject:[EFNUploadFormData formDataWithName:name fileName:fileName fileData:fileData]];
    Unlock();
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileData:(NSData *_Nonnull)fileData
{
    Lock();
    [self.uploadDataArray addObject:[EFNUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileData:fileData]];
    Unlock();
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileURL:(NSURL *_Nonnull)fileURL
{
    Lock();
    [self.uploadDataArray addObject:[EFNUploadFormData formDataWithName:name fileURL:fileURL]];
    Unlock();
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileURL:(NSURL *_Nonnull)fileURL
{
    Lock();
    [self.uploadDataArray addObject:[EFNUploadFormData formDataWithName:name fileName:fileName fileURL:fileURL]];
    Unlock();
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileURL:(NSURL *_Nonnull)fileURL
{
    Lock();
    [self.uploadDataArray addObject:[EFNUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileURL:fileURL]];
    Unlock();
}

@end

@implementation EFNUploadFormData

+ (instancetype)formDataWithName:(NSString *)name fileData:(NSData *)fileData {
    return [self formDataWithName:name fileName:nil mimeType:nil fileData:fileData];
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName fileData:(NSData *)fileData {
    return [self formDataWithName:name fileName:fileName mimeType:nil fileData:fileData];
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    EFNUploadFormData *formData = [[self alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    return [self formDataWithName:name fileName:nil mimeType:nil fileURL:fileURL];
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName fileURL:(NSURL *)fileURL {
    return [self formDataWithName:name fileName:fileName fileURL:fileURL];
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    EFNUploadFormData *formData = [[self alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileURL = fileURL;
    return formData;
}

@end
