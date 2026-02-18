//
//  file: XPCDaemonProtocol.h
//  project: LuLu (shared)
//  description: methods exported by the daemon
//
//  created by Patrick Wardle
//  copyright (c) 2018 Objective-See. All rights reserved.
//

@import Foundation;

@protocol XPCDaemonProtocol

//get preferences
-(void)getPreferences:(void (^)(NSDictionary*))reply;

//update preferences
-(void)updatePreferences:(NSDictionary*)preferences reply:(void (^)(NSDictionary*))reply;

//get rules
-(void)getRules:(void (^)(NSData*))reply;

//get recent connection telemetry
-(void)getConnectionEvents:(void (^)(NSArray*))reply;

//get pending (silent mode) connections
-(void)getPendingConnections:(void (^)(NSArray*))reply;

//resolve pending connection by creating a rule and removing it from queue
-(void)resolvePendingConnection:(NSString*)uuid action:(NSNumber*)action reply:(void (^)(BOOL))reply;

//delete pending connection (without creating a rule)
-(void)deletePendingConnection:(NSString*)uuid reply:(void (^)(BOOL))reply;

//add rule
-(void)addRule:(NSDictionary*)info;

//disable (or re-enable) rule
-(void)toggleRule:(NSString*)key rule:(NSString*)uuid state:(NSNumber*)state;

//delete rule
-(void)deleteRule:(NSString*)key rule:(NSString*)uuid;

//import rules
-(void)importRules:(NSData*)newRules userOnly:(BOOL)userOnly result:(void (^)(BOOL))reply;

//cleanup rules
-(void)cleanupRules:(BOOL)fule reply:(void (^)(NSInteger))reply;

//get current profile
-(void)getCurrentProfile:(void (^)(NSString*))profile;

//get list of profiles
-(void)getProfiles:(void (^)(NSArray*))reply;

//add profile
-(void)addProfile:(NSString*)name preferences:(NSDictionary*)preferences reply:(void (^)(BOOL))reply;

//delete profile
-(void)deleteProfile:(NSString*)name reply:(void (^)(BOOL))reply;

//set profile
-(void)setProfile:(NSString*)name reply:(void (^)(BOOL))reply;

//uninstall
-(void)uninstall:(void (^)(BOOL))reply;

@end
