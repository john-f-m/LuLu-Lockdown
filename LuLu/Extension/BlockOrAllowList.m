//
//  BlockOrAllowList.m
//  Extension
//
//  Created by Patrick Wardle on 11/6/20.
//  Copyright © 2020 Objective-See. All rights reserved.
//

#import "BlockOrAllowList.h"
#import "Preferences.h"
#import "consts.h"

#import <arpa/inet.h>
#import <sys/socket.h>

/* GLOBALS */

// log handle
extern os_log_t logHandle;

// preferences
extern Preferences *preferences;

@implementation BlockOrAllowList

- (id)init:(NSString *)path {
  // init super
  self = [super init];
  if (nil != self) {
    // alloc
    self.items = [NSMutableSet set];
    self.ipPrefixes = [NSMutableSet set];

    // save list
    self.path = path;

    // load
    [self load:self.path];
  }

  return self;
}

// was specified block list remote
//  ...just checks if prefixed with http:// || https://
- (BOOL)isRemote {
  // specified path a URL?
  return ((YES == [self.path hasPrefix:@"http://"]) ||
          (YES == [self.path hasPrefix:@"https://"]));
}

// should reload
//  checks file modification time
- (BOOL)shouldReload {
  // flag
  BOOL shouldReload = NO;

  // current mod. time
  NSDate *modified = nil;

  // if it's remote
  //  can't tell, so default to no
  if (YES == [self isRemote]) {
    // bail
    goto bail;
  }

  // get modified timestamp
  modified = [[NSFileManager.defaultManager attributesOfItemAtPath:self.path
                                                             error:nil]
      objectForKey:NSFileModificationDate];

  // was file modified?
  if (NSOrderedDescending == [modified compare:self.lastModified]) {
    // dbg msg
    os_log_debug(logHandle, "block list was modified ...will reload");

    // yes
    shouldReload = YES;
  }

bail:

  return shouldReload;
}

//(re)load
- (void)load:(NSString *)path {
  // error
  NSError *error = nil;

  // file contents
  NSString *list = nil;

  // sync
  @synchronized(self) {

    // update path
    self.path = path;

    // reset lists
    [self.items removeAllObjects];
    [self.ipPrefixes removeAllObjects];

    // dbg msg
    os_log_debug(logHandle, "%s", __PRETTY_FUNCTION__);

    // check
    //  path?
    if (0 == self.path.length) {
      // dbg msg
      os_log_debug(logHandle, "no list specified...");

      // bail
      goto bail;
    }

    // remote?
    //  load via URL
    if (YES == [self isRemote]) {
      // dbg msg
      os_log_debug(logHandle, "(re)loading (remote) list");

      // load
      list = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.path]
                                      encoding:NSUTF8StringEncoding
                                         error:&error];
      if (nil != error) {
        // err msg
        os_log_error(logHandle,
                     "ERROR: failed to (re)load (remote) list, %{public}@ "
                     "(error: %{public}@)",
                     self.path, error);

        // bail
        goto bail;
      }

      // split and add to list
      [self addItemsFromString:list];

      //(re)load remote URL once a day
      dispatch_after(
          dispatch_time(DISPATCH_TIME_NOW,
                        (int64_t)(24 * 60 * 60 * NSEC_PER_SEC)),
          dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // dbg msg
            os_log_debug(logHandle, "(re)loading (remote) list");

            //(re)load
            [self load:self.path];
          });
    }

    // local file
    //  check and load
    else {
      // dbg msg
      os_log_debug(logHandle, "(re)loading (local) list, %{public}@",
                   self.path);

      // (re)load
      [self addFromFile:path];

      // save timestamp
      self.lastModified = [[NSFileManager.defaultManager
          attributesOfItemAtPath:self.path
                           error:nil] objectForKey:NSFileModificationDate];
    }
  } // sync

bail:

  return;
}

// add from file
- (void)addFromFile:(NSString *)path {
  // error
  NSError *error = nil;

  // file contents
  NSString *list = nil;

  // dbg msg
  os_log_debug(logHandle, "adding from file, %{public}@", path);

  // load
  list = [NSString stringWithContentsOfFile:path
                                   encoding:NSUTF8StringEncoding
                                      error:&error];
  if (nil != error) {
    // err msg
    os_log_error(logHandle,
                 "ERROR: failed to load file, %{public}@ (error: %{public}@)",
                 path, error);
    return;
  }

  // sync
  @synchronized(self) {
    [self addItemsFromString:list];
  } // sync

  return;
}

// add items from string
- (void)addItemsFromString:(NSString *)list {
  // split and add to list
  for (NSString *item in
       [list componentsSeparatedByCharactersInSet:[NSCharacterSet
                                                      newlineCharacterSet]]) {
    // clean
    NSString *cleaned =
        [item stringByTrimmingCharactersInSet:[NSCharacterSet
                                                  whitespaceCharacterSet]];

    // skip blank or comments
    if ((0 == cleaned.length) || (YES == [cleaned hasPrefix:@"#"])) {
      continue;
    }

    // CIDR?
    if ([cleaned containsString:@"/"]) {
      [self.ipPrefixes addObject:cleaned];
    } else {
      [self.items addObject:cleaned.lowercaseString];
    }
  }

  // dbg msg
  os_log_debug(logHandle, "(re)loaded %lu items and %lu prefixes",
               (unsigned long)self.items.count,
               (unsigned long)self.ipPrefixes.count);
}

// helper: check if an IP address falls within a CIDR prefix
- (BOOL)address:(NSString *)address matchesPrefix:(NSString *)cidr {
  // split CIDR into address and prefix length
  NSArray *parts = [cidr componentsSeparatedByString:@"/"];
  if (2 != parts.count)
    return NO;

  NSString *cidrAddr = parts[0];
  int prefixLen = [parts[1] intValue];

  // try IPv4
  struct in_addr addr4, cidr4;
  if (1 == inet_pton(AF_INET, address.UTF8String, &addr4) &&
      1 == inet_pton(AF_INET, cidrAddr.UTF8String, &cidr4)) {
    if (prefixLen < 0 || prefixLen > 32)
      return NO;

    uint32_t mask =
        (prefixLen == 0) ? 0 : htonl(0xFFFFFFFF << (32 - prefixLen));
    return (addr4.s_addr & mask) == (cidr4.s_addr & mask);
  }

  // try IPv6
  struct in6_addr addr6, cidr6;
  if (1 == inet_pton(AF_INET6, address.UTF8String, &addr6) &&
      1 == inet_pton(AF_INET6, cidrAddr.UTF8String, &cidr6)) {
    if (prefixLen < 0 || prefixLen > 128)
      return NO;

    // compare byte by byte
    int fullBytes = prefixLen / 8;
    int remainingBits = prefixLen % 8;

    // compare full bytes
    if (fullBytes > 0 && 0 != memcmp(&addr6, &cidr6, fullBytes))
      return NO;

    // compare remaining bits
    if (remainingBits > 0) {
      uint8_t mask = (uint8_t)(0xFF << (8 - remainingBits));
      if ((addr6.s6_addr[fullBytes] & mask) !=
          (cidr6.s6_addr[fullBytes] & mask))
        return NO;
    }

    return YES;
  }

  return NO;
}

// check if flow matches item on block or allow list
//  note: currently lists don't support port matching
- (BOOL)isMatch:(NEFilterSocketFlow *)flow {
  // match
  BOOL isMatch = NO;

  // remote endpoint
  NWHostEndpoint *remoteEndpoint = nil;

  // endpoint url/hosts
  NSMutableSet *endpointNames = nil;

  // matches
  NSSet *matches = nil;

  // extract remote endpoint
  remoteEndpoint = (NWHostEndpoint *)flow.remoteEndpoint;

  // need to reload list?
  //  checks timestamp to see if modified
  if (YES == [self shouldReload]) {
    //(re)load list
    [self load:self.path];
  }

  // sync
  @synchronized(self) {

    // init endpoint names
    endpointNames = [NSMutableSet set];

    // add url
    if (nil != flow.URL.absoluteString) {
      // add full url
      [endpointNames addObject:flow.URL.absoluteString.lowercaseString];
    }

    // add host
    if (nil != flow.URL.host) {
      // add full url
      [endpointNames addObject:flow.URL.host.lowercaseString];
    }

    // add host name
    if (nil != remoteEndpoint.hostname) {
      // add
      [endpointNames addObject:remoteEndpoint.hostname.lowercaseString];
    }

    // macOS 11+?
    //  add remote host name
    if (@available(macOS 11, *)) {
      // add remote host name
      if (nil != flow.remoteHostname) {
        // add
        [endpointNames addObject:flow.remoteHostname.lowercaseString];

        // if it starts w/ 'www.'
        //  strip and add that too
        if (YES == [flow.remoteHostname hasPrefix:@"www."]) {
          // add
          [endpointNames addObject:[[flow.remoteHostname substringFromIndex:4]
                                       lowercaseString]];
        }
      }
    }

    // first check for "all"
    //  for IPV4 -> '0.0.0.0/0'
    if ((AF_INET == flow.socketFamily) &&
        ([self.items containsObject:@"0.0.0.0/0"])) {
      isMatch = YES;
      goto bail;
    }
    // for IPV6 -> '::/0'
    else if ((AF_INET6 == flow.socketFamily) &&
             ([self.items containsObject:@"::/0"])) {
      isMatch = YES;
      goto bail;
    }

    // find matches
    matches = [self.items objectsPassingTest:^BOOL(NSString *item, BOOL *stop) {
      return [endpointNames containsObject:item];
    }];

    // any matches?
    if (0 != matches.count) {
      // dbg msg
      os_log_debug(logHandle,
                   "endpoint names %{public}@ matched the following list items "
                   "%{public}@",
                   endpointNames, matches);

      // set flag
      isMatch = YES;
    }

    // no match yet?
    //  check IP prefixes
    if ((NO == isMatch) && (0 != self.ipPrefixes.count)) {
      // dbg msg
      os_log_debug(logHandle, "checking IP prefixes for %{public}@",
                   remoteEndpoint.hostname);

      // iterate
      for (NSString *prefix in self.ipPrefixes) {
        // match?
        if (YES == [self address:remoteEndpoint.hostname
                       matchesPrefix:prefix]) {
          // dbg msg
          os_log_debug(logHandle, "IP %{public}@ matched prefix %{public}@",
                       remoteEndpoint.hostname, prefix);

          // set flag
          isMatch = YES;

          // done
          break;
        }
      }
    }

  } // sync

bail:

  return isMatch;
}

@end
