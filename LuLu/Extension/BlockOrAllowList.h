//
//  BlockOrAllowList.h
//  Extension
//
//  Created by Patrick Wardle on 11/6/20.
//  Copyright © 2020 Objective-See. All rights reserved.
//

@import Cocoa;
@import OSLog;
@import NetworkExtension;
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BlockOrAllowList : NSObject

/* PROPERTIES */

// path
@property(nonatomic, retain) NSString *path;

// block list
@property(nonatomic, retain) NSMutableSet *items;

// ip prefixes (CIDR)
@property(nonatomic, retain) NSMutableSet *ipPrefixes;

// modification time
@property(nonatomic, retain) NSDate *lastModified;

/* METHODS */

// init
//  with a path
- (id)init:(NSString *)path;

//(re)load from disk
- (void)load:(NSString *)path;

// should reload
//  checks file modification time
- (BOOL)shouldReload;

// add from file
- (void)addFromFile:(NSString *)path;

// check if flow matches item on block or allow list
- (BOOL)isMatch:(NEFilterSocketFlow *)flow;

@end

NS_ASSUME_NONNULL_END
