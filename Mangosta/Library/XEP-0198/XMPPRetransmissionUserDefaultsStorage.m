//
//  XMPPRetransmissionUserDefaultsStorage.m
//  Mangosta
//
//  Created by Piotr Wegrzynek on 22/06/2017.
//  Copyright © 2017 Inaka. All rights reserved.
//

#import "XMPPRetransmissionUserDefaultsStorage.h"

@interface XMPPRetransmissionUserDefaultsStorage ()

@property (strong, nonatomic, readonly) NSUserDefaults *userDefaults;
@property (copy, nonatomic, readonly) NSString *contentKey;
@property (strong, nonatomic, readonly) dispatch_queue_t storageQueue;

@end

@implementation XMPPRetransmissionUserDefaultsStorage

- (instancetype)init
{
    return [self initWithIdentifier:@"default"];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _contentKey = [NSString stringWithFormat:@"XMPPRetransmissionUserDefaultsStorage.%@", identifier];
        _storageQueue = dispatch_queue_create("XMPPRetransmissionUserDefaultsStorage.storageUpdateQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)storeMonitoredElement:(XMPPElement *)element withId:(NSUUID *)elementId;
{
    NSData *elementData = [NSKeyedArchiver archivedDataWithRootObject:element];
    NSDate *timestamp = [NSDate date];
    
    [self updateContentWithBlock:^(NSMutableDictionary<NSString *,NSDictionary<NSString *,id> *> *content) {
        content[elementId.UUIDString] = @{@"timestamp": timestamp, @"payload": elementData};
    }];
}

- (void)enumerateMonitoredElementsWithBlock:(void (^)(NSUUID *, XMPPElement *, NSDate *))enumerationBlock
{
    NSDictionary *storage = [self.userDefaults dictionaryForKey:self.contentKey];
    [storage enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *,id> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSUUID *elementId = [[NSUUID alloc] initWithUUIDString:key];
        XMPPElement *element = [NSKeyedUnarchiver unarchiveObjectWithData:obj[@"payload"]];
        NSDate *timestamp = obj[@"timestamp"];
        enumerationBlock(elementId, element, timestamp);
    }];
}

- (void)clearMonitoredElementsWithIds:(NSArray<NSUUID *> *)elementIds
{
    [self updateContentWithBlock:^(NSMutableDictionary<NSString *,NSDictionary<NSString *,id> *> *content) {
        for (NSUUID *elementId in elementIds) {
            [content removeObjectForKey:elementId.UUIDString];
        }
    }];
}

- (void)updateContentWithBlock:(void (^)(NSMutableDictionary<NSString *, NSDictionary<NSString *,id> *> *))updateBlock
{
    dispatch_sync(self.storageQueue, ^{
        NSMutableDictionary *updatedContent = [[self.userDefaults dictionaryForKey:self.contentKey] mutableCopy] ?: [[NSMutableDictionary alloc] init];
        updateBlock(updatedContent);
        [self.userDefaults setObject:updatedContent forKey:self.contentKey];
    });
}

@end
