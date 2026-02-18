//
//  file: XPCDaemon.m
//  project: lulu (launch daemon)
//  description: interface for XPC methods, invoked by user
//
//  created by Patrick Wardle
//  copyright (c) 2017 Objective-See. All rights reserved.
//

#import "Rule.h"
#import "Rules.h"
#import "Alerts.h"
#import "consts.h"
#import "Profiles.h"
#import "XPCDaemon.h"
#import "utilities.h"
#import "Preferences.h"

//global rules obj
extern Rules* rules;

//global alerts obj
extern Alerts* alerts;

//global profiles obj
extern Profiles* profiles;

//global prefs obj
extern Preferences* preferences;

//global log handle
extern os_log_t logHandle;

//path to connection telemetry
static NSString* getConnectionsPath(void)
{
    return [INSTALL_DIRECTORY stringByAppendingPathComponent:CONNECTIONS_FILE];
}

//path to pending silent-mode connections
static NSString* getPendingConnectionsPath(void)
{
    return [INSTALL_DIRECTORY stringByAppendingPathComponent:PENDING_CONNECTIONS_FILE];
}

//load list entries from disk
static NSMutableArray* loadEntries(NSString* path)
{
    //entries
    NSArray* entries = [NSArray arrayWithContentsOfFile:path];
    
    //sanity check
    if(YES != [entries isKindOfClass:[NSArray class]])
    {
        return [NSMutableArray array];
    }
    
    return [entries mutableCopy];
}

//save list entries to disk
static BOOL saveEntries(NSArray* entries, NSString* path)
{
    return [entries writeToFile:path atomically:YES];
}

//append a connection event
static void appendConnectionEvent(NSDictionary* event)
{
    //events
    NSMutableArray* events = loadEntries(getConnectionsPath());
    
    //append
    [events addObject:event];
    
    //cap list size
    if(events.count > 5000)
    {
        [events removeObjectsInRange:NSMakeRange(0, events.count - 5000)];
    }
    
    //save
    saveEntries(events, getConnectionsPath());
}

@implementation XPCDaemon

//send preferences to the client
-(void)getPreferences:(void (^)(NSDictionary*))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //reply w/ prefs
    reply(preferences.preferences);
        
    return;
}

//update preferences
// note: sends full preferences back to the client
-(void)updatePreferences:(NSDictionary*)updates reply:(void (^)(NSDictionary*))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s' (%{public}@)", __PRETTY_FUNCTION__, updates);
    
    //call into prefs obj
    if(YES != [preferences update:updates replace:NO])
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to updates to preferences");
    }
    
    //reply w/ prefs
    reply(preferences.preferences);
    
    return;
}

//send rules to the client
-(void)getRules:(void (^)(NSData*))reply
{
    //archived rules
    NSData* archivedRules = nil;
    
    //error
    NSError* error = nil;
    
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //archive rules
    archivedRules = [NSKeyedArchiver archivedDataWithRootObject:rules.rules requiringSecureCoding:YES error:&error];
    if(nil == archivedRules)
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to archive rules: %{public}@", error);
            
    } else os_log_debug(logHandle, "archived %lu rules, and sending to user...", (unsigned long)rules.rules.count);

    //reply w/ rules
    reply(archivedRules);
           
    return;
}

//send connection telemetry to the client
-(void)getConnectionEvents:(void (^)(NSArray*))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //reply
    reply(loadEntries(getConnectionsPath()));
    
    return;
}

//send pending connections to client
-(void)getPendingConnections:(void (^)(NSArray*))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //reply
    reply(loadEntries(getPendingConnectionsPath()));
    
    return;
}

//resolve pending connection by creating a rule and removing queue item
-(void)resolvePendingConnection:(NSString*)uuid action:(NSNumber*)action reply:(void (^)(BOOL))reply
{
    //result
    BOOL resolved = NO;
    
    //pending entries
    NSMutableArray* pending = nil;
    
    //matched entry
    NSMutableDictionary* entry = nil;
    
    //match index
    NSUInteger index = NSNotFound;
    
    //rule info
    NSMutableDictionary* ruleInfo = nil;
    
    //uuid invalid?
    if(0 == uuid.length)
    {
        goto bail;
    }
    
    //default action
    if(nil == action)
    {
        action = @RULE_STATE_ALLOW;
    }
    
    //load pending entries
    pending = loadEntries(getPendingConnectionsPath());
    
    //find matching entry
    for(NSUInteger i = 0; i < pending.count; i++)
    {
        NSString* pendingUUID = pending[i][KEY_UUID];
        if( (0 != pendingUUID.length) &&
            (NSOrderedSame == [pendingUUID caseInsensitiveCompare:uuid]) )
        {
            entry = [pending[i] mutableCopy];
            index = i;
            break;
        }
    }
    
    //not found?
    if(nil == entry)
    {
        goto bail;
    }
    
    //init rule info
    if(0 == [entry[KEY_PATH] length])
    {
        goto bail;
    }
    
    ruleInfo = [@{KEY_PATH:entry[KEY_PATH], KEY_ACTION:action, KEY_TYPE:@RULE_TYPE_USER} mutableCopy];
    
    //retain endpoint details when available
    if(0 != [entry[KEY_ENDPOINT_ADDR] length])
    {
        ruleInfo[KEY_ENDPOINT_ADDR] = entry[KEY_ENDPOINT_ADDR];
    }
    if(0 != [entry[KEY_ENDPOINT_PORT] length])
    {
        ruleInfo[KEY_ENDPOINT_PORT] = entry[KEY_ENDPOINT_PORT];
    }
    if(nil != entry[KEY_PROTOCOL])
    {
        ruleInfo[KEY_PROTOCOL] = entry[KEY_PROTOCOL];
    }
    
    //retain code-signing details when available
    if(nil != entry[KEY_CS_INFO])
    {
        ruleInfo[KEY_CS_INFO] = entry[KEY_CS_INFO];
    }
    
    //if endpoint data is missing, fall back to process-wide rule
    if( (0 == [entry[KEY_ENDPOINT_ADDR] length]) &&
        (0 == [entry[KEY_ENDPOINT_PORT] length]) )
    {
        ruleInfo[KEY_SCOPE] = @(ACTION_SCOPE_PROCESS);
    }
    
    //create/save rule
    if(YES != [rules add:[[Rule alloc] init:ruleInfo] save:YES])
    {
        goto bail;
    }
    
    //remove pending entry and save
    [pending removeObjectAtIndex:index];
    if(YES != saveEntries(pending, getPendingConnectionsPath()))
    {
        goto bail;
    }
    
    //append resolved connection event
    appendConnectionEvent(@{
        KEY_UUID: entry[KEY_UUID] ?: [[NSUUID UUID] UUIDString],
        KEY_TIMESTAMP: [NSDate date],
        KEY_PATH: entry[KEY_PATH] ?: @"",
        KEY_PROCESS_NAME: entry[KEY_PROCESS_NAME] ?: @"",
        KEY_ENDPOINT_ADDR: entry[KEY_ENDPOINT_ADDR] ?: @"",
        KEY_ENDPOINT_PORT: entry[KEY_ENDPOINT_PORT] ?: @"",
        KEY_PROTOCOL: entry[KEY_PROTOCOL] ?: @0,
        KEY_DECISION: (RULE_STATE_BLOCK == action.intValue) ? @"block" : @"allow",
        KEY_REASON: @"pending_review"
    });
    
    //tell user rules changed
    [alerts.xpcUserClient rulesChanged];
    
    //happy
    resolved = YES;
    
bail:
    
    reply(resolved);
    
    return;
}

//delete pending connection without creating rule
-(void)deletePendingConnection:(NSString*)uuid reply:(void (^)(BOOL))reply
{
    //result
    BOOL deleted = NO;
    
    //pending entries
    NSMutableArray* pending = nil;
    
    //load pending
    pending = loadEntries(getPendingConnectionsPath());
    
    //find/remove
    for(NSUInteger i = 0; i < pending.count; i++)
    {
        NSString* pendingUUID = pending[i][KEY_UUID];
        if( (0 != pendingUUID.length) &&
            (NSOrderedSame == [pendingUUID caseInsensitiveCompare:uuid]) )
        {
            [pending removeObjectAtIndex:i];
            deleted = YES;
            break;
        }
    }
    
    //save if changed
    if(YES == deleted)
    {
        deleted = saveEntries(pending, getPendingConnectionsPath());
    }
    
    reply(deleted);
    
    return;
}

//add a rule
-(void)addRule:(NSDictionary*)info
{
    //binary obj
    Binary* binary = nil;
    
    //rule info
    NSMutableDictionary* ruleInfo = nil;
    
    //default cs flags
    SecCSFlags flags = kSecCSDefaultFlags | kSecCSCheckNestedCode | kSecCSDoNotValidateResources | kSecCSCheckAllArchitectures;
    
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s' with info: %{public}@", __PRETTY_FUNCTION__, info);
    
    //make copy
    ruleInfo = [info mutableCopy];
    
    //non-specific path
    // init binary and cs info
    if(YES != [info[KEY_PATH] hasSuffix:VALUE_ANY])
    {
        //init binary obj w/ path
        binary = [[Binary alloc] init:info[KEY_PATH]];
        if(nil == binary)
        {
            //err msg
            os_log_error(logHandle, "ERROR: failed init binary object for %@", info[KEY_PATH]);
            
            //bail
            goto bail;
        }
        
        //generate cs info
        [binary generateSigningInfo:flags];
        
        //add any code signing info
        if(nil != binary.csInfo) 
        {
            //add
            ruleInfo[KEY_CS_INFO] = binary.csInfo;
        }
    }
    
    //create and add rule
    if(YES != [rules add:[[Rule alloc] init:ruleInfo] save:YES])
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to add rule for %{public}@", ruleInfo[KEY_PATH]);
         
        //bail
        goto bail;
    }
    
    //dbg msg
    os_log_debug(logHandle, "added rule");
    
bail:
    
    return;
}

//disable (or re-enable) rule
-(void)toggleRule:(NSString*)key rule:(NSString*)uuid state:(NSNumber*)state
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s' with key: %{public}@, rule id: %{public}@", __PRETTY_FUNCTION__, key, uuid);
    
    //toggle
    if(YES != [rules toggleRule:key rule:uuid state:state])
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to toggle rule");
        
        //bail
        goto bail;
    }
    
    //dbg msg
    os_log_debug(logHandle, "toggled rule");
    
bail:
    
    return;

}

//delete rule
-(void)deleteRule:(NSString*)key rule:(NSString*)uuid
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s' with key: %{public}@, rule id: %{public}@", __PRETTY_FUNCTION__, key, uuid);

    //delete rule
    if(YES != [rules delete:key rule:uuid])
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to delete rule");
        
        //bail
        goto bail;
    }
    
    //dbg msg
    os_log_debug(logHandle, "deleted rule");
    
bail:
    
    return;
}

//import rules
-(void)importRules:(NSData*)importedRules userOnly:(BOOL)userOnly result:(void (^)(BOOL))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //import rules
    reply([rules import:importedRules userOnly:userOnly]);

    return;
}

//cleanup rules
-(void)cleanupRules:(BOOL)full reply:(void (^)(NSInteger))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //cleanup rules
    reply([rules cleanup:full]);

    return;
}

//uninstall
-(void)uninstall:(void (^)(BOOL))reply
{
    //flag
    BOOL uninstalled = NO;
    
    //directory
    NSString* path = nil;

    //error
    NSError* error = nil;
    
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //init path w/ install dir
    path = INSTALL_DIRECTORY;
    
    //remove install directory
    if(YES != [NSFileManager.defaultManager removeItemAtPath:path error:&error])
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to remove %{public}@ (error: %{public}@)", path, error);
    }
    else
    {
        //dbg msg
        os_log_debug(logHandle, "removed %{public}@", path);
        
        //happy
        uninstalled = YES;
    }
    
    //up to Obj-See's install dir
    path = [path stringByDeletingLastPathComponent];
    
    //no other Obj-See tools?
    // remove the Obj-See directory too
    if( (0 == [[NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:&error] count]) &&
        (nil == error) )
    {
        //remove
        if(YES != [NSFileManager.defaultManager removeItemAtPath:path error:&error])
        {
            //err msg
            os_log_error(logHandle, "ERROR: failed to delete %{public}@ (error: %{public}@)", path, error);
        }
        else
        {
            //dbg msg
            os_log_debug(logHandle, "removed %{public}@", path);
            
            //happy
            uninstalled = YES;
        }
    }
    
    //return result
    reply(uninstalled);
    
    return;
}

//get current profile *name*
-(void)getCurrentProfile:(void (^)(NSString*))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //reply
    reply([[preferences getCurrentProfile] lastPathComponent]);
        
    return;
}

//get list of profile names
-(void)getProfiles:(void (^)(NSArray*))reply
{
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s'", __PRETTY_FUNCTION__);
    
    //reply w/ prefs
    // return immutable copy
    reply([profiles enumerate].copy);
        
    return;
}

//add profile
-(void)addProfile:(NSString*)name preferences:(NSDictionary*)preferences reply:(void (^)(BOOL))reply
{
    //flag
    BOOL wasAdded = NO;
    
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s' with %{public}@", __PRETTY_FUNCTION__, name);
    
    //create and add profile
    if(YES != [profiles add:name preferences:preferences])
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to add new profile '%{public}@'", name);
         
        //bail
        goto bail;
    }
    
    //happy
    wasAdded = YES;
    
    //dbg msg
    os_log_debug(logHandle, "added new profile '%{public}@'", name);
    
bail:
    
    reply(wasAdded);
    
    return;
}

//set profile
-(void)setProfile:(NSString*)name reply:(void (^)(BOOL))reply
{
    //flag
    BOOL wasSet = NO;
    
    //full path
    NSString* newProfilePath = nil;
    
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s' with name: %{public}@", __PRETTY_FUNCTION__, name);

    //new profile?
    if(nil != name)
    {
        //init path for new profile directory
        newProfilePath = [profiles.directory stringByAppendingPathComponent:name];
    }
    
    //set
    [profiles set:newProfilePath];
    
    //reload rules
    [rules load];
    
    //tell user rules changed
    // ...in case rule's window need refreshing
    [alerts.xpcUserClient rulesChanged];
    
    //reload prefs
    [preferences load];
    
    //happy
    wasSet = YES;
    
    //dbg msg
    os_log_debug(logHandle, "set profile to %{public}@", newProfilePath ? newProfilePath : @"Default");
    
    reply(wasSet);
    
    return;
}

//delete profile
-(void)deleteProfile:(NSString*)name reply:(void (^)(BOOL))reply
{
    //flag
    BOOL wasDeleted = NO;
    
    //dbg msg
    os_log_debug(logHandle, "XPC request: '%s' with name: %{public}@", __PRETTY_FUNCTION__, name);
    
    //sanity check
    if(nil == name)
    {
        //err msg
        os_log_error(logHandle, "ERROR: profile name is nil, so ignoring...");
        goto bail;
    }

    //delete profile
    if(YES != [profiles delete:name])
    {
        //err msg
        os_log_error(logHandle, "ERROR: failed to delete profile");
        goto bail;
    }
    
    //happy
    wasDeleted = YES;
    
    //dbg msg
    os_log_debug(logHandle, "deleted profile %{public}@", name);
    
bail:
    
    reply(wasDeleted);
    
    return;
}

@end
