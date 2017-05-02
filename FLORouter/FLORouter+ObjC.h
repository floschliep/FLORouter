//
//  FLORouter+ObjC.h
//  FLORouter
//
//  Created by Florian Schliep on 02.05.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

#import "FLORouter-Swift.h"

NS_ASSUME_NONNULL_BEGIN;
@interface FLORouter (ObjC)

- (NSInteger)registerRoute:(NSString *)route action:(BOOL(^)(FLORoutingRequest *))action;
- (NSInteger)registerRoute:(NSString *)route forScheme:(NSString *)scheme action:(BOOL(^)(FLORoutingRequest *))action;
- (NSInteger)registerRoute:(NSString *)route priority:(NSInteger)priority action:(BOOL(^)(FLORoutingRequest *))action;

- (NSArray<NSNumber *> *)registerRoutes:(NSArray<NSString *> *)routes action:(BOOL (^)(FLORoutingRequest *))action;
- (NSArray<NSNumber *> *)registerRoutes:(NSArray<NSString *> *)routes forScheme:(NSString *)scheme action:(BOOL (^)(FLORoutingRequest *))action;
- (NSArray<NSNumber *> *)registerRoutes:(NSArray<NSString *> *)routes priority:(NSInteger)priority action:(BOOL (^)(FLORoutingRequest *))action;

@end
NS_ASSUME_NONNULL_END;
