//
//  FLORouter+ObjC.m
//  FLORouter
//
//  Created by Florian Schliep on 02.05.17.
//  Copyright © 2017 Florian Schliep. All rights reserved.
//

#import "FLORouter+ObjC.h"

@implementation FLORouter (ObjC)

- (NSInteger)registerRoute:(NSString *)route action:(BOOL(^)(FLORoutingRequest * _Nonull))action {
    return [self registerRoute:route forScheme:nil priority:0 action:action];
}

- (NSInteger)registerRoute:(NSString *)route forScheme:(NSString *)scheme action:(BOOL (^)(FLORoutingRequest *))action {
    return [self registerRoute:route forScheme:scheme priority:0 action:action];
}

- (NSInteger)registerRoute:(NSString *)route priority:(NSInteger)priority action:(BOOL (^)(FLORoutingRequest *))action {
    return [self registerRoute:route forScheme:nil priority:priority action:action];
}

- (NSArray<NSNumber *> *)registerRoutes:(NSArray<NSString *> *)routes action:(BOOL (^)(FLORoutingRequest * _Nonnull))action {
    return [self registerRoutes:routes forScheme:nil priority:0 action:action];
}

- (NSArray<NSNumber *> *)registerRoutes:(NSArray<NSString *> *)routes forScheme:(NSString *)scheme action:(BOOL (^)(FLORoutingRequest * _Nonnull))action {
    return [self registerRoutes:routes forScheme:scheme priority:0 action:action];
}

- (NSArray<NSNumber *> *)registerRoutes:(NSArray<NSString *> *)routes priority:(NSInteger)priority action:(BOOL (^)(FLORoutingRequest * _Nonnull))action {
    return [self registerRoutes:routes forScheme:nil priority:priority action:action];
}

@end
