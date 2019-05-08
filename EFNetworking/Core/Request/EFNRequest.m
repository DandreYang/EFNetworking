//
//  EFNRequest.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/28.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "EFNRequest.h"
#import "NSDictionary+EFNetworking.h"
#include <objc/runtime.h>

#define Lock() [self.lock lock]
#define Unlock() [self.lock unlock]

static NSString * const EFNRequestLockName = @"vip.dandre.efnetworking.request.lock";

@interface EFNRequest ()

@property (nonatomic, strong, readwrite) NSMutableArray<__kindof EFNUploadData *> *uploadDataArray;
@property (nonatomic, strong, readwrite) NSLock *lock;

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

- (NSMutableArray<__kindof EFNUploadData *> *)uploadDataArray {
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

- (void)setUploadFormDatas:(NSArray<__kindof EFNUploadData *> *)uploadFormDatas {
    Lock();
    self.uploadDataArray.count == 0?:[self.uploadDataArray removeAllObjects];
    uploadFormDatas.count == 0?:[self.uploadDataArray addObjectsFromArray:uploadFormDatas];
    Unlock();
}

- (NSArray<__kindof EFNUploadData *> *)uploadFormDatas {
    return self.uploadDataArray.copy;
}

- (NSString *)description {
    NSDictionary *dict = [NSDictionary efn_dictionaryWithObject:self];
    NSString *desc = [NSString stringWithFormat:@"<%@: %p> => %@", [self class], self, dict];

    return desc;
}

@end

@implementation EFNRequest (AppendUploadData)

- (BOOL)appendUploadDataWithFileData:(NSData *_Nonnull)fileData
{
    Lock();
    [self.uploadDataArray addObject:[[EFNStreamUploadData alloc] initWithFileData:fileData]];
    Unlock();
    return YES;
}

- (BOOL)appendUploadDataWithFileData:(NSData *_Nonnull)fileData name:(NSString *_Nonnull)name
{
    Lock();
    [self.uploadDataArray addObject:[EFNMutipartFormData formDataWithFileData:fileData name:name]];
    Unlock();
    return YES;
}

- (BOOL)appendUploadDataWithFileData:(NSData *_Nonnull)fileData name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType
{
    Lock();
    [self.uploadDataArray addObject:[EFNMutipartFormData formDataWithFileData:fileData name:name fileName:fileName mimeType:mimeType]];
    Unlock();
    return YES;
}

- (BOOL)appendUploadDataWithFileURL:(NSURL *_Nonnull)fileURL
{
    Lock();
    [self.uploadDataArray addObject:[[EFNStreamUploadData alloc] initWithFileURL:fileURL]];
    Unlock();
    return YES;
}

- (BOOL)appendUploadDataWithFileURL:(NSURL *_Nonnull)fileURL name:(NSString *_Nonnull)name
{
    Lock();
    [self.uploadDataArray addObject:[EFNMutipartFormData formDataWithFileURL:fileURL name:name]];
    Unlock();
    return YES;
}

- (BOOL)appendUploadDataWithFileURL:(NSURL *_Nonnull)fileURL name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType
{
    Lock();
    [self.uploadDataArray addObject:[EFNMutipartFormData formDataWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType]];
    Unlock();
    return YES;
}

@end

@implementation EFNRequest (Deprecated)

#pragma mark - Methods
- (void)addFormDataWithName:(NSString *_Nullable)name fileData:(NSData *_Nonnull)fileData
{
    [self appendUploadDataWithFileData:fileData name:name];
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileData:(NSData *_Nonnull)fileData
{
    [self appendUploadDataWithFileData:fileData name:name fileName:name mimeType:nil];
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileData:(NSData *_Nonnull)fileData
{
    [self appendUploadDataWithFileData:fileData name:name fileName:fileName mimeType:mimeType];
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileURL:(NSURL *_Nonnull)fileURL
{
    [self appendUploadDataWithFileURL:fileURL name:name];
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileURL:(NSURL *_Nonnull)fileURL
{
    [self appendUploadDataWithFileURL:fileURL name:name fileName:fileName mimeType:nil];
}

- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileURL:(NSURL *_Nonnull)fileURL
{
    [self appendUploadDataWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType];
}

@end

@interface EFNUploadData ()

@property (nonatomic, strong, readwrite, nullable) NSData *fileData;
@property (nonatomic, strong, readwrite, nullable) NSURL *fileURL;

@end

@implementation EFNUploadData

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    NSAssert(fileURL, @"The fileURL must not be null");
    self = [super init];
    if (self) {
        self.fileURL = fileURL;
    }
    return self;
}

- (instancetype)initWithFileData:(NSData *)fileData
{
    NSAssert(fileData, @"The fileData must not be null");
    self = [super init];
    if (self) {
        self.fileData = fileData;
    }
    return self;
}

@end

@interface EFNMutipartFormData ()

@property (nonatomic, copy, readwrite, nullable) NSString *name;
@property (nonatomic, copy, readwrite, nullable) NSString *fileName;
@property (nonatomic, copy, readwrite, nullable) NSString *mimeType;

@end

@implementation EFNMutipartFormData

+ (instancetype)formDataWithFileData:(NSData *)fileData name:(NSString *)name {
    return [self formDataWithFileData:fileData name:name fileName:nil mimeType:nil];
}

+ (instancetype)formDataWithFileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName {
    return [self formDataWithFileData:fileData name:name fileName:fileName mimeType:nil];
}

+ (instancetype)formDataWithFileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    NSParameterAssert(fileData);
    NSParameterAssert(name);
    return [[self alloc] initWithFileData:fileData name:name fileName:fileName mimeType:mimeType];
}

+ (instancetype)formDataWithFileURL:(NSURL *)fileURL name:(NSString *)name {
    return [self formDataWithFileURL:fileURL name:name fileName:nil mimeType:nil];
}

/// @bug 1.0.1及之前版本存在BUG：内部方法调用错误，导致递归死循环
+ (instancetype)formDataWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName {
    return [self formDataWithFileURL:fileURL name:name fileName:fileName mimeType:nil];
}

+ (instancetype)formDataWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType {
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    return [[self alloc] initWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType];
}

#pragma mark - Init Method
- (instancetype)initWithFileURL:(NSURL *)fileURL name:(NSString *)name  fileName:(NSString *)fileName mimeType:(NSString *)mimeType
{
    self = [super initWithFileURL:fileURL];
    if (self) {
        self.name = name;
        self.fileName = fileName;
        self.mimeType = mimeType;
    }
    return self;
}

- (instancetype)initWithFileData:(NSData *)fileData name:(NSString *)name  fileName:(NSString *)fileName mimeType:(NSString *)mimeType
{
    self = [super initWithFileData:fileData];
    if (self) {
        self.name = name;
        self.fileName = fileName;
        self.mimeType = mimeType;
    }
    return self;
}

@end

@implementation EFNStreamUploadData

@end
