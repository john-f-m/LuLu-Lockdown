//
//  file: PrefsWindowController.h
//  project: lulu (main app)
//  description: preferences window controller (header)
//
//  created by Patrick Wardle
//  copyright (c) 2017 Objective-See. All rights reserved.
//

#import "consts.h"
#import "Update.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "PrefsWindowController.h"
#import "UpdateWindowController.h"
#import <netinet/in.h>

/* GLOBALS */

//log handle
extern os_log_t logHandle;

//xpc for daemon comms
extern XPCDaemonClient* xpcDaemonClient;

@interface PrefsWindowController ()

//advanced mode controls (added programmatically)
@property(nonatomic, retain)NSButton* strictModeButton;
@property(nonatomic, retain)NSButton* silentModeButton;
@property(nonatomic, retain)NSButton* reviewPendingButton;
@property(nonatomic, retain)NSButton* openInsightsButton;
@property(nonatomic, retain)NSButton* importLockdownBlocklistsButton;

@end

@implementation PrefsWindowController

@synthesize toolbar;
@synthesize modesView;
@synthesize rulesView;
@synthesize updateView;
@synthesize updateWindowController;

//'allow apple' button
#define BUTTON_ALLOW_APPLE 1

//'allow installed' button
#define BUTTON_ALLOW_INSTALLED 2

//'allow dns' button
#define BUTTON_ALLOW_DNS 3

//'allow iOS simulator apps' mode button
#define BUTTON_ALLOW_SIMULATOR 4

//'passive mode' button
#define BUTTON_PASSIVE_MODE 5

//'block mode' button
#define BUTTON_BLOCK_MODE 6

//'no-icon mode' button
#define BUTTON_NO_ICON_MODE 7

//'no-VT mode' button
#define BUTTON_NO_VT_MODE 8

//'detailed' rule mode
#define BUTTON_DETAILED_RULE_MODE 9

//'use allow list' button
#define BUTTON_USE_ALLOW_LIST 10

//'use block list' button
#define BUTTON_USE_BLOCK_LIST 11

//'update mode' button
#define BUTTON_NO_UPDATE_MODE 12

//'strict mode' button
#define BUTTON_STRICT_MODE 1300

//'silent mode' button
#define BUTTON_SILENT_MODE 1301

//'passive mode' actions
#define BUTTON_PASSIVE_MODE_ACTION_ALLOW 0
#define BUTTON_PASSIVE_MODE_ACTION_BLOCK 1

//init 'general' view
// add it, and make it selected
-(void)awakeFromNib
{
    //set subtitle
    [self setSubTitle];
    
    //get prefs
    self.preferences = [xpcDaemonClient getPreferences];
    
    //add advanced controls
    [self installAdvancedFeatureControls];
    
    return;
}

//make a checkbox-style button
-(NSButton*)makeCheckbox:(NSString*)title frame:(NSRect)frame tag:(NSInteger)tag
{
    //button
    NSButton* button = [[NSButton alloc] initWithFrame:frame];
    
    //set
    button.title = title;
    button.tag = tag;
    button.buttonType = NSButtonTypeSwitch;
    button.target = self;
    button.action = @selector(togglePreference:);
    
    return button;
}

//add advanced controls (strict/silent/review/import/insights)
-(void)installAdvancedFeatureControls
{
    //already added?
    if(nil != self.strictModeButton)
    {
        return;
    }
    
    //layout values
    CGFloat width = self.modesView.frame.size.width - 40;
    
    //strict mode
    self.strictModeButton = [self makeCheckbox:NSLocalizedString(@"Strict interactive mode (prompt for each new/changed connection)", @"Strict interactive mode (prompt for each new/changed connection)")
                                         frame:NSMakeRect(20, 24, width, 20)
                                           tag:BUTTON_STRICT_MODE];
    [self.modesView addSubview:self.strictModeButton];
    
    //silent mode
    self.silentModeButton = [self makeCheckbox:NSLocalizedString(@"Silent mode (allow now, review and block later)", @"Silent mode (allow now, review and block later)")
                                         frame:NSMakeRect(20, 4, width, 20)
                                           tag:BUTTON_SILENT_MODE];
    [self.modesView addSubview:self.silentModeButton];
    
    //review pending queue button
    self.reviewPendingButton = [[NSButton alloc] initWithFrame:NSMakeRect(20, 50, 190, 24)];
    self.reviewPendingButton.title = NSLocalizedString(@"Review Silent Queue", @"Review Silent Queue");
    self.reviewPendingButton.bezelStyle = NSBezelStyleRounded;
    self.reviewPendingButton.target = self;
    self.reviewPendingButton.action = @selector(reviewPendingConnections:);
    [self.modesView addSubview:self.reviewPendingButton];
    
    //open traffic insights button
    self.openInsightsButton = [[NSButton alloc] initWithFrame:NSMakeRect(220, 50, 180, 24)];
    self.openInsightsButton.title = NSLocalizedString(@"Open Traffic Insights", @"Open Traffic Insights");
    self.openInsightsButton.bezelStyle = NSBezelStyleRounded;
    self.openInsightsButton.target = self;
    self.openInsightsButton.action = @selector(openTrafficInsights:);
    [self.modesView addSubview:self.openInsightsButton];
    
    //import Lockdown blocklists button
    self.importLockdownBlocklistsButton = [[NSButton alloc] initWithFrame:NSMakeRect(20, 8, self.listsView.frame.size.width - 40, 24)];
    self.importLockdownBlocklistsButton.title = NSLocalizedString(@"Import Lockdown-Mac Bad Actor Lists", @"Import Lockdown-Mac Bad Actor Lists");
    self.importLockdownBlocklistsButton.bezelStyle = NSBezelStyleRounded;
    self.importLockdownBlocklistsButton.target = self;
    self.importLockdownBlocklistsButton.action = @selector(importLockdownBlocklists:);
    [self.listsView addSubview:self.importLockdownBlocklistsButton];
}

//sync strict/silent controls from current preferences
-(void)syncAdvancedModeControls
{
    //strict/silent states
    self.strictModeButton.state = [self.preferences[PREF_STRICT_MODE] boolValue];
    self.silentModeButton.state = [self.preferences[PREF_SILENT_MODE] boolValue];
}

//set subtitle to current profile
-(void)setSubTitle
{
    //dbg msg
    os_log_debug(logHandle, "method '%s' invoked", __PRETTY_FUNCTION__);
    
    //current profile
    NSString* currentProfile = [xpcDaemonClient getCurrentProfile];
    
    //have profile?
    if(0 != currentProfile.length) {
        
        //add subtitle
        if (@available(macOS 11.0, *)) {
            self.window.subtitle = [NSString stringWithFormat:NSLocalizedString(@"Current Profile: %@",@"Current Profile: %@"), currentProfile];
        }
    }
    //set to default
    else
    {
        //set
        if (@available(macOS 11.0, *)) {
            self.window.subtitle = NSLocalizedString(@"Current Profile: Default",@"Current Profile: Default");
        }
    }
    
    return;
}

//switch to tab
-(void)switchTo:(NSString*)itemID
{
    //predicate
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"itemIdentifier == %@", itemID];
    
    //item
    NSToolbarItem* item = [[self.toolbar.items filteredArrayUsingPredicate:predicate] firstObject];
    
    //dbg msg
    os_log_debug(logHandle, "item '%@' -> %{public}@", itemID, item);
    
    //select
    [self toolbarButtonHandler:item];
    [self.toolbar setSelectedItemIdentifier:itemID];
    
    return;
}

//toolbar view handler
// toggle view based on user selection
-(IBAction)toolbarButtonHandler:(id)sender
{
    //view
    NSView* view = nil;
    
    //dbg msg
    os_log_debug(logHandle, "%s invoked with %{public}@", __PRETTY_FUNCTION__, sender);
    
    //when we've prev added a view
    // remove the prev view cuz adding a new one
    if(YES == self.viewWasAdded)
    {
        //dbg msg
        os_log_debug(logHandle, "removing previous view...");
        
        //remove
        [[[self.window.contentView subviews] lastObject] removeFromSuperview];
    }
    
    //assign view
    switch(((NSToolbarItem*)sender).tag)
    {
        //rules
        case TOOLBAR_RULES:
            
            //set view
            view = self.rulesView;
            
            //show
            self.showRulesButton.hidden = NO;
            
            //set 'apple allowed' button state
            ((NSButton*)[view viewWithTag:BUTTON_ALLOW_APPLE]).state = [self.preferences[PREF_ALLOW_APPLE] boolValue];
            
            //set 'installed allowed' button state
            ((NSButton*)[view viewWithTag:BUTTON_ALLOW_INSTALLED]).state = [self.preferences[PREF_ALLOW_INSTALLED] boolValue];
            
            //set 'allow dns' button state
            ((NSButton*)[view viewWithTag:BUTTON_ALLOW_DNS]).state = [self.preferences[PREF_ALLOW_DNS] boolValue];
        
            //set 'allow simulator apps' button
            ((NSButton*)[view viewWithTag:BUTTON_ALLOW_SIMULATOR]).state = [self.preferences[PREF_ALLOW_SIMULATOR] boolValue];

            break;
            
        //modes
        case TOOLBAR_MODES:
            
            //set view
            view = self.modesView;
            
            //set 'passive mode' button state
            ((NSButton*)[view viewWithTag:BUTTON_PASSIVE_MODE]).state = [self.preferences[PREF_PASSIVE_MODE] boolValue];
            
            //set 'passive mode' action
            [self.passiveModeAction selectItemAtIndex: [self.preferences[PREF_PASSIVE_MODE_ACTION] integerValue]];
            
            //set 'passive mode' rules
            [self.passiveModeRules selectItemAtIndex: [self.preferences[PREF_PASSIVE_MODE_RULES] integerValue]];
            
            //set 'block mode' button state
            ((NSButton*)[view viewWithTag:BUTTON_BLOCK_MODE]).state = [self.preferences[PREF_BLOCK_MODE] boolValue];
            
            //set 'no icon' button state
            ((NSButton*)[view viewWithTag:BUTTON_NO_ICON_MODE]).state = [self.preferences[PREF_NO_ICON_MODE] boolValue];
            
            //set 'no VT icon' button state
            ((NSButton*)[view viewWithTag:BUTTON_NO_VT_MODE]).state = [self.preferences[PREF_NO_VT_MODE] boolValue];
            
            //sync strict/silent controls
            [self syncAdvancedModeControls];
            
            break;
            
        //lists
        case TOOLBAR_LISTS:
            
            //set view
            view = self.listsView;
            
            //set 'allow list' button state
            ((NSButton*)[view viewWithTag:BUTTON_USE_ALLOW_LIST]).state = [self.preferences[PREF_USE_ALLOW_LIST] boolValue];
            
            //is there a allow list? ...set!
            if(0 != [self.preferences[PREF_ALLOW_LIST] length])
            {
                //set
                self.allowList.stringValue = self.preferences[PREF_ALLOW_LIST];
            }
            
            //set 'browse' button state
            self.selectAllowListButton.enabled = [self.preferences[PREF_USE_ALLOW_LIST] boolValue];
            
            //set allow list input state
            self.allowList.enabled = [self.preferences[PREF_USE_ALLOW_LIST] boolValue];
            
            //set 'block list' button state
            ((NSButton*)[view viewWithTag:BUTTON_USE_BLOCK_LIST]).state = [self.preferences[PREF_USE_BLOCK_LIST] boolValue];
            
            //is there a block list? ...set!
            if(0 != [self.preferences[PREF_BLOCK_LIST] length])
            {
                //set
                self.blockList.stringValue = self.preferences[PREF_BLOCK_LIST];
            }
            
            //set 'browse' button state
            self.selectBlockListButton.enabled = [self.preferences[PREF_USE_BLOCK_LIST] boolValue];
            
            //set block list input state
            self.blockList.enabled = [self.preferences[PREF_USE_BLOCK_LIST] boolValue];
            
            break;
            
        //profiles
        case TOOLBAR_PROFILES:
            
            //set view
            view = self.profilesView;
            
            //send XPC msg to daemon get profiles
            self.profiles = [xpcDaemonClient getProfiles];
            
            //manually add default at start
            [self.profiles insertObject:@"Default" atIndex:0];
            
            //dbg msg
            os_log_debug(logHandle, "list of profiles: %{public}@", self.profiles);
            
            //reload table
            [self.profilesTable reloadData];
            
            break;
            
        //update
        case TOOLBAR_UPDATE:
            
            //set view
            view = self.updateView;
    
            //set 'update' button state
            ((NSButton*)[view viewWithTag:BUTTON_NO_UPDATE_MODE]).state = [self.preferences[PREF_NO_UPDATE_MODE] boolValue];
            
            //show
            self.updateButton.hidden = NO;
            
            //(re)set update label
            self.updateLabel.stringValue = @"";
            
            break;
            
        default:
            return;
    }

    // Resize window to fit the view’s height (keeping top edge fixed)
    NSRect windowFrame = self.window.frame;
    CGFloat newHeight = view.frame.size.height + 50 + 10; //toolbar + a bit extra
    CGFloat newWidth = view.frame.size.width;
    CGFloat deltaY = NSMaxY(windowFrame) - newHeight;
    [self.window setFrame:NSMakeRect(windowFrame.origin.x, deltaY, newWidth, newHeight) display:YES];

    // Position view so its top aligns with the window’s contentView top
    NSView *container = self.window.contentView;
    NSRect viewFrame = view.frame;
    viewFrame.origin.y = container.bounds.size.height - viewFrame.size.height;
    viewFrame.origin.x = 0;
    view.frame = viewFrame;
    
    //add to window
    [self.window.contentView addSubview:view];
    
    //set
    self.viewWasAdded = YES;
    
bail:
    
    return;
}

//invoked when user toggles button
// update preferences for that button/item
-(IBAction)togglePreference:(id)sender
{
    //preferences
    NSMutableDictionary* updatedPreferences = nil;
    
    //button state
    NSNumber* state = nil;
    
    //in "add profile" mode
    // want to capture all the preferences
    if(YES == self.addProfileSheet.isVisible)
    {
        updatedPreferences = self.profilePreferences;
    }
    //otherwise
    // grab (just) updated preferences to send to daemon
    else
    {
        //init
        updatedPreferences = [NSMutableDictionary dictionary];
    }
    
    //get button state
    state = [NSNumber numberWithBool:((NSButton*)sender).state];
    
    //set appropriate preference
    switch(((NSButton*)sender).tag)
    {
        //allow apple
        case BUTTON_ALLOW_APPLE:
            updatedPreferences[PREF_ALLOW_APPLE] = state;
            break;
            
        //allow installed
        case BUTTON_ALLOW_INSTALLED:
            updatedPreferences[PREF_ALLOW_INSTALLED] = state;
            break;
        
        //allow dns traffic
        case BUTTON_ALLOW_DNS:
            updatedPreferences[PREF_ALLOW_DNS] = state;
            break;
            
        //allow simulator apps
        case BUTTON_ALLOW_SIMULATOR:
            updatedPreferences[PREF_ALLOW_SIMULATOR] = state;
            break;
            
        //use block list
        case BUTTON_USE_ALLOW_LIST:
            
            //set state
            updatedPreferences[PREF_USE_ALLOW_LIST] = state;
            
            //disable?
            // remove allow list too
            if(NSControlStateValueOff == state.longValue)
            {
                //unset
                updatedPreferences[PREF_ALLOW_LIST] = @"";
                
                //clear
                self.allowList.stringValue = @"";
            }
            
            //set allow list input state
            self.allowList.enabled = (NSControlStateValueOn == state.longValue);
            
            //set 'browse' button state
            self.selectAllowListButton.enabled = (NSControlStateValueOn == state.longValue);
            
            break;
            
        //use block list
        case BUTTON_USE_BLOCK_LIST:
            
            //set
            updatedPreferences[PREF_USE_BLOCK_LIST] = state;
            
            //disable?
            // remove block list too
            if(NSControlStateValueOff == state.longValue)
            {
                //unset
                updatedPreferences[PREF_BLOCK_LIST] = @"";
                
                //clear
                self.blockList.stringValue = @"";
            }
            
            //set block list input state
            self.blockList.enabled = (NSControlStateValueOn == state.longValue);
            
            //set 'browse' button state
            self.selectBlockListButton.enabled = (NSControlStateValueOn == state.longValue);
            
            break;
            
        //passive mode
        case BUTTON_PASSIVE_MODE:
            
            //grab state
            updatedPreferences[PREF_PASSIVE_MODE] = state;
            
            //passive mode and strict/silent are mutually exclusive
            if(NSControlStateValueOn == state.longValue)
            {
                updatedPreferences[PREF_STRICT_MODE] = @NO;
                updatedPreferences[PREF_SILENT_MODE] = @NO;
                
                //update UI immediately
                self.strictModeButton.state = NSControlStateValueOff;
                self.silentModeButton.state = NSControlStateValueOff;
            }
            
            //grab selected item of action
            updatedPreferences[PREF_PASSIVE_MODE_ACTION] = [NSNumber numberWithInteger:self.passiveModeAction.indexOfSelectedItem];
            
            //grab selected item of rules
            updatedPreferences[PREF_PASSIVE_MODE_RULES] = [NSNumber numberWithInteger:self.passiveModeRules.indexOfSelectedItem];
            
            break;
            
        //strict mode
        case BUTTON_STRICT_MODE:
            
            //set strict mode
            updatedPreferences[PREF_STRICT_MODE] = state;
            
            //strict mode and passive/silent are mutually exclusive
            if(NSControlStateValueOn == state.longValue)
            {
                updatedPreferences[PREF_SILENT_MODE] = @NO;
                updatedPreferences[PREF_PASSIVE_MODE] = @NO;
                updatedPreferences[PREF_ALERT_LAST_RULE_SCOPE] = @(ACTION_SCOPE_ENDPOINT);
                self.silentModeButton.state = NSControlStateValueOff;
                ((NSButton*)[self.modesView viewWithTag:BUTTON_PASSIVE_MODE]).state = NSControlStateValueOff;
            }
            
            break;
            
        //silent mode
        case BUTTON_SILENT_MODE:
            
            //set silent mode
            updatedPreferences[PREF_SILENT_MODE] = state;
            
            //silent mode and passive/strict are mutually exclusive
            if(NSControlStateValueOn == state.longValue)
            {
                updatedPreferences[PREF_STRICT_MODE] = @NO;
                updatedPreferences[PREF_PASSIVE_MODE] = @NO;
                self.strictModeButton.state = NSControlStateValueOff;
                ((NSButton*)[self.modesView viewWithTag:BUTTON_PASSIVE_MODE]).state = NSControlStateValueOff;
            }
            
            break;
            
        //block mode
        case BUTTON_BLOCK_MODE:
            updatedPreferences[PREF_BLOCK_MODE] = state;
            
            //enable?
            // show alert
            if(NSControlStateValueOn == state.longValue)
            {
                //show alert
                showAlert(NSAlertStyleInformational, NSLocalizedString(@"Outgoing traffic will now be blocked.",@"Outgoing traffic will now be blocked."), NSLocalizedString(@"Note however:\r\n▪ Existing connections will not be impacted.\r\n▪ OS traffic (not routed thru LuLu) will not be blocked.",@"Note however:\r\n▪ Existing connections will not be impacted.\r\n▪ OS traffic (not routed thru LuLu) will not be blocked."), @[NSLocalizedString(@"OK", @"OK")]);
            }
            
            break;
            
        //no icon mode
        case BUTTON_NO_ICON_MODE:
            updatedPreferences[PREF_NO_ICON_MODE] = state;
            break;
            
        //no vt mode
        case BUTTON_NO_VT_MODE:
            updatedPreferences[PREF_NO_VT_MODE] = state;
            break;
            
        //no update mode
        case BUTTON_NO_UPDATE_MODE:
            updatedPreferences[PREF_NO_UPDATE_MODE] = state;
            break;
            
        default:
            break;
    }
    
    //logic for 'passive mode' action
    if(YES == [sender isEqualTo:self.passiveModeAction])
    {
        //grab selected index
        updatedPreferences[PREF_PASSIVE_MODE_ACTION] = [NSNumber numberWithInteger:self.passiveModeAction.indexOfSelectedItem];
    }
    //logic for 'passive mode' rules
    else if(YES == [sender isEqualTo:self.passiveModeRules])
    {
        //grab selected index
        updatedPreferences[PREF_PASSIVE_MODE_RULES] = [NSNumber numberWithInteger:self.passiveModeRules.indexOfSelectedItem];
    }
    
    //only process here if we're not in "add profile" mode
    if(YES != self.addProfileSheet.isVisible)
    {
        //send XPC msg to daemon to update prefs
        // returns (all/latest) prefs, which is what we want
        self.preferences = [xpcDaemonClient updatePreferences:updatedPreferences];
        
        //sync strict/silent controls
        [self syncAdvancedModeControls];

        //call back into app to process
        // e.g. show/hide status bar icon, etc.
        [((AppDelegate*)[[NSApplication sharedApplication] delegate]) preferencesChanged:self.preferences];
    }
    
    return;
}

//browse for select list
-(IBAction)selectBlockOrAllowList:(id)sender
{
    //'browse' panel
    NSOpenPanel *panel = nil;
        
    //init panel
    panel = [NSOpenPanel openPanel];
        
    //allow files
    panel.canChooseFiles = YES;
    
    //start ...at desktop
    panel.directoryURL = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES) firstObject]];
        
    //disable multiple selections
    panel.allowsMultipleSelection = NO;
        
    //show it
    // and wait for response
    if(NSModalResponseOK == [panel runModal])
    {
        //allow list
        if(sender == self.selectAllowListButton)
        {
            //update ui
            self.allowList.stringValue = panel.URL.path;
            
            //dbg msg
            os_log_debug(logHandle, "user selected allow list: %{public}@", self.allowList.stringValue);
            
            //send XPC msg to daemon to update prefs
            self.preferences = [xpcDaemonClient updatePreferences:@{PREF_ALLOW_LIST:panel.URL.path}];
        }
        //block list
        else if(sender == self.selectBlockListButton)
        {
            //update ui
            self.blockList.stringValue = panel.URL.path;
            
            //dbg msg
            os_log_debug(logHandle, "user selected block list: %{public}@", self.blockList.stringValue);
            
            //send XPC msg to daemon to update prefs
            self.preferences = [xpcDaemonClient updatePreferences:@{PREF_BLOCK_LIST:panel.URL.path}];
        }
        //error
        else
        {
            //err msg
            os_log_error(logHandle, "ERROR: %{public}@ is an invalid sender", sender);
        }
    }
    
    return;
}

//invoked when block list path is (manually entered)
-(IBAction)updateBlockList:(id)sender
{
    //dbg msg
    os_log_debug(logHandle, "got 'update block list event' (value: %{public}@)", self.blockList.stringValue);
    
    //send XPC msg to daemon to update prefs
    // returns (all/latest) prefs, which is what we want
    self.preferences = [xpcDaemonClient updatePreferences:@{PREF_BLOCK_LIST:self.blockList.stringValue}];
    
    return;
}

//reload current toolbar view (as profile changed)
// ...by triggering a 'click' to our toolbar button handler
-(void)reload
{
    //dbg msg
    os_log_debug(logHandle, "%s invoked", __PRETTY_FUNCTION__);
    
    //grab (profile's) preferences
    self.preferences = [xpcDaemonClient getPreferences];
    
    //(re)set subtitle
    [self setSubTitle];
    
    //selected ID
    NSToolbarItemIdentifier selectedID = self.toolbar.selectedItemIdentifier;

    //selected item
    NSToolbarItem* toolbarItem = [[self.toolbar items]
        filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"itemIdentifier == %@", selectedID]].firstObject;

    //trigger reload
    [self toolbarButtonHandler:toolbarItem];
    
    return;
}

#pragma mark – Profile's table delegates

//number of profiles
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.profiles.count;
}

//view for each column + row
- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    //dequeue a cell
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    //first column
    // check button if we're looking at the current profile
    if(YES == [tableColumn.identifier isEqualToString:@"Current"]) {
        
        //current profile
        NSString* currentProfile = [xpcDaemonClient getCurrentProfile];
        
        //select button
        NSButton* selectButton = (NSButton*)[cell viewWithTag:TABLE_ROW_SELECT_BTN_TAG];
        
        //dbg msg
        os_log_debug(logHandle, "current row: %ld, current profile %{public}@, select button: %{public}@", (long)row, currentProfile, selectButton);
        
        //no profile?
        // select button/row zero (default)
        if( (0 == row) &&
            (nil == currentProfile) )
        {
            //dbg msg
            os_log_debug(logHandle, "enabling default button here...");
            
            //select
            selectButton.state = NSControlStateValueOn;
            
            //select row too
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }
        //profile matches current?
        else if(YES == [currentProfile isEqualToString:self.profiles[row]])
        {
            //dbg msg
            os_log_debug(logHandle, "match, enabling button here...");
            
            //select
            selectButton.state = NSControlStateValueOn;
            
            //select row too
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }
        else
        {
            //turn off
            selectButton.state = NSControlStateValueOff;
        }
    }
    
    //add name
    // and customize delete button
    if ([tableColumn.identifier isEqualToString:@"Name"]) {
        
        //delete button
        NSButton* deleteButton = (NSButton*)[cell viewWithTag:TABLE_ROW_DELETE_BTN_TAG];
        
        //add name
        cell.textField.stringValue = self.profiles[row];
        
        //first row?
        // this is 'default' profile, so disable delete button
        if(0 == row) {
            
            //hide
            deleteButton.hidden = YES;
            
        } else {
            
            //show/enable
            deleteButton.hidden = NO;
            deleteButton.enabled = YES;
        }
    }

    return cell;
}

#pragma mark – Profile's button handlers

//get profile name from current/selected row
-(NSString*)profileFromTable:(id)sender
{
    //profile path
    NSString* profile = nil;
    
    //index of row
    // either clicked or selected row
    NSInteger row = 0;

    //dbg msg
    os_log_debug(logHandle, "%s invoked", __PRETTY_FUNCTION__);
    
    //get row
    if(nil != sender)
    {
        //row from sender
        row = [self.profilesTable rowForView:sender];
    }
    //otherwise get selected row
    else
    {
        //selected row
        row = self.profilesTable.selectedRow;
    }
    
    //get profile
    // index 0, is the default profile, which we want as nil
    if(row > 0 && row < self.profiles.count)
    {
        //get profile
        profile = self.profiles[row];
    }
    
    //dbg msg
    os_log_debug(logHandle, "row: %ld, profile: %{public}@", (long)row, profile);
    
    return profile;
}

//'switch profile' button handler
-(IBAction)switchProfile:(id)sender {
    
    //profile
    NSString* profile = nil;
    
    //dbg msg
    os_log_debug(logHandle, "%s invoked", __PRETTY_FUNCTION__);
    
    //get profile
    // can be 'nil' if default profile is selected
    profile = [self profileFromTable:sender];
    
    //dbg msg
    os_log_debug(logHandle, "user wants to change profile to '%{public}@'", profile ? profile : @"Default");
    
    //set profile via XPC
    [xpcDaemonClient setProfile:profile];
    
    //tell app profiles changed
    // will grab profile's preferences too
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) profilesChanged];

    //also tell app preferences changed
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) preferencesChanged:self.preferences];
    
    //show alert
    showAlert(NSAlertStyleInformational, NSLocalizedString(@"Profile Switched", @"Profile Switched"), [NSString stringWithFormat:NSLocalizedString(@"Current profile is now: '%@'.", @"Current profile is now: '%@'."), nil != profile ? profile : NSLocalizedString(@"Default", @"Default")], @[NSLocalizedString(@"OK", @"OK")]);
    
    return;
}

//add profile button handler
// show sheet for user to specify settings
-(IBAction)addProfile:(id)sender {
    
    //dbg msg
    os_log_debug(logHandle, "%s invoked", __PRETTY_FUNCTION__);
    
    //init dictionary to collect preferences
    self.profilePreferences = [NSMutableDictionary dictionary];
    
    //init/reset
    self.profileName = nil;
    
    //init/reset
    self.continueProfileButton.tag = 0;
    
    //remove any old view
    if(self.currentProfileSubview) {
        
        //remove current view
        [self.currentProfileSubview removeFromSuperview];
    }

    //init current view (with profile name)
    self.currentProfileSubview = self.profileNameView;
    
    //add initial (profile name) view
    [self.addProfileSheet.contentView addSubview:self.currentProfileSubview];
    
    //disable autoresizing mask
    self.currentProfileSubview.translatesAutoresizingMaskIntoConstraints = NO;

    //pin to top, leading, and trailing edges
    [NSLayoutConstraint activateConstraints:@[
        [self.currentProfileSubview.topAnchor constraintEqualToAnchor:self.addProfileSheet.contentView.topAnchor],
        [self.currentProfileSubview.leadingAnchor constraintEqualToAnchor:self.addProfileSheet.contentView.leadingAnchor],
        [self.currentProfileSubview.trailingAnchor constraintEqualToAnchor:self.addProfileSheet.contentView.trailingAnchor]
    ]];
    
    //reset button name
    self.continueProfileButton.title = NSLocalizedString(@"Next", @"Next");
    
    //set profile name
    self.profileNameLabel.stringValue = @"";
    
    //show sheet for user to add profile
    [self.window beginSheet:self.addProfileSheet
               completionHandler:^(NSModalResponse returnCode) {
        
            //add profile?
            // and handle UI refreshes, etc
            if (returnCode == NSModalResponseOK) {
            
                //dbg msg
                os_log_debug(logHandle, "user wants to add profile '%{public}@'", self.profileName);
                
                //add profile via XPC
                [xpcDaemonClient addProfile:self.profileName preferences:self.profilePreferences];
                
                //hide profile sheet
                [self.addProfileSheet orderOut:self];
                
                //tell app profiles changed
                // will grab profile's preferences too
                [((AppDelegate*)[[NSApplication sharedApplication] delegate]) profilesChanged];
                
                //tell app preferences changed
                [((AppDelegate*)[[NSApplication sharedApplication] delegate]) preferencesChanged:self.preferences];
                
                //show alert
                showAlert(NSAlertStyleInformational, NSLocalizedString(@"Added Profile", @"Added Profile"), [NSString stringWithFormat:NSLocalizedString(@"New profile '%@' saved and activated.", @"New profile '%@' saved and activated."), self.profileName], @[NSLocalizedString(@"OK", @"OK")]);
            }
            
            //cancel
            else {
                
                //close sheet
                [self.addProfileSheet orderOut:self];
            }
    }];
    
    return;
}

//cancel creation of profile
- (IBAction)cancelProfileButtonHandler:(id)sender {
    
    //end w/ cancel
    [self.window endSheet:self.addProfileSheet returnCode:NSModalResponseCancel];
    
    return;
}

//show next view
// note: each case is current view, going to next!
-(IBAction)continueProfileButtonHandler:(NSButton*)sender {
    
    //switch on current view
    // last view, will add the profile
    switch (sender.tag) {
            
        //current view: name
        // setup next view: rules
        case profileName:
        {
            //check against empty
            if(!self.profileNameLabel.stringValue.length)
            {
                //show alert
                showAlert(NSAlertStyleInformational, NSLocalizedString(@"Invalid Profile Name", @"Invalid Profile Name"), NSLocalizedString(@"Profile name can't be blank", @"Profile name can't be blank"), @[NSLocalizedString(@"OK", @"OK")]);
                
                self.profileNameLabel.stringValue = @"";
                goto bail;
            }
            
            //check against 'Default'
            if(NSOrderedSame == [self.profileNameLabel.stringValue caseInsensitiveCompare:NSLocalizedString(@"Default", @"Default")])
            {
                //show alert
                showAlert(NSAlertStyleInformational, NSLocalizedString(@"Invalid Profile Name", @"Invalid Profile Name"), NSLocalizedString(@"'Default' is a reserved profile name.", @"'Default' is a reserved profile name."), @[NSLocalizedString(@"OK", @"OK")]);
                
                goto bail;
            }
            
            //check against existing names
            for(NSString *name in [xpcDaemonClient getProfiles])
            {
                if(NSOrderedSame == [self.profileNameLabel.stringValue caseInsensitiveCompare:name])
                {
                    //show alert
                    showAlert(NSAlertStyleInformational, NSLocalizedString(@"Invalid Profile Name", @"Invalid Profile Name"), [NSString stringWithFormat:NSLocalizedString(@"'%@' matches an existing profile name.", @"'%@' matches an existing profile name."), name], @[NSLocalizedString(@"OK", @"OK")]);
                    
                    self.profileNameLabel.stringValue = @"";
                    goto bail;
                }
            }
            
            //save name
            self.profileName = self.profileNameLabel.stringValue;
            
            //remove current view
            [self.currentProfileSubview removeFromSuperview];
            
            //update
            self.currentProfileSubview = self.rulesView;
            
            //hide 'show buttons'
            self.showRulesButton.hidden = YES;
            
            //add to rule's view
            [self.addProfileSheet.contentView addSubview:self.currentProfileSubview];
            
            //update tag
            self.continueProfileButton.tag = profileRules;
            
            break;
        }
            
        //current view: rules
        // setup next view: modes
        case profileRules:
            
            //remove current view
            [self.currentProfileSubview removeFromSuperview];
            
            //update
            self.currentProfileSubview = self.modesView;
            
            //add to mode's view
            [self.addProfileSheet.contentView addSubview:self.currentProfileSubview];
            
            //update tag
            self.continueProfileButton.tag = profileModes;
            
            break;
        
        //current view: modes
        // setup next view: lists
        case profileModes:
            
            //remove current view
            [self.currentProfileSubview removeFromSuperview];
            
            //update
            self.currentProfileSubview = self.listsView;
            
            //add to list's view
            [self.addProfileSheet.contentView addSubview:self.currentProfileSubview];
            
            //update tag
            self.continueProfileButton.tag = profileLists;
            
            break;
        
        //current view: lists
        // setup next view: updates
        case profileLists:
            
            //remove current view
            [self.currentProfileSubview removeFromSuperview];
            
            //update
            self.currentProfileSubview = self.updateView;
            
            //hide button
            self.updateButton.hidden = YES;
            
            //unset label
            self.updateLabel.stringValue = @"";
            
            //add to mode's view
            [self.addProfileSheet.contentView addSubview:self.currentProfileSubview];
            
            //update tag
            self.continueProfileButton.tag = profileUpdates;
            
            //update button name to "Add Profile"
            self.continueProfileButton.title = NSLocalizedString(@"Add Profile", @"Add Profile");
            
            break;
            
        //current view: updates
        // add profile as this is the last one!
        case profileUpdates:
            
            //end with 'ok'
            [self.window endSheet:self.addProfileSheet returnCode:NSModalResponseOK];
            
        default:
            break;
    }
    
    //uncheck all checks buttons (might be set from current preferences)
    for (NSView *subview in self.currentProfileSubview.subviews) {
        if ([subview isKindOfClass:[NSButton class]]) {
            NSButton *button = (NSButton *)subview;
            // Uncheck only if the button has a toggleable state
                if (button.allowsMixedState || button.state != NSControlStateValueOff) {
                    button.state = NSControlStateValueOff;
                }
        }
    }
    
    //update view's fame
    NSRect bounds = self.addProfileSheet.contentView.bounds;
    NSRect frame = self.currentProfileSubview.frame;
    frame.origin.x  = 0;
    frame.origin.y  = bounds.size.height - frame.size.height;
    
    //set frame
    self.currentProfileSubview.frame = frame;
    
bail:

    return;
}

//delete profile button handler
-(IBAction)deleteProfile:(id)sender {
    
    //response
    NSModalResponse response = 0;
    
    //name
    NSString* profile = nil;

    //get profile
    profile = [self profileFromTable:sender];
    
    //dbg msg
    os_log_debug(logHandle, "user wants to delete profile '%{public}@'", profile);
    
    //show alert
    response = showAlert(NSAlertStyleInformational, NSLocalizedString(@"Confirm Deletion", @"Confirm Deletion"), [NSString stringWithFormat:NSLocalizedString(@"Delete profile: '%@'?", @"Delete profile: '%@'?"), profile], @[NSLocalizedString(@"Ok", @"Ok"), NSLocalizedString(@"Cancel", @"Cancel")]);
    
    //cancel?
    if(NSAlertSecondButtonReturn == response)
    {
        //dbg msg
        os_log_debug(logHandle, "user canceled deleting profile...");
        
        //done
        goto bail;
    }
    
    //delete via XPC
    [xpcDaemonClient deleteProfile:profile];
    
    //dbg msg
    os_log_debug(logHandle, "deleted profile '%{public}@'", profile);
    
    //tell app profiles changed
    // will grab profile's preferences too
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) profilesChanged];
    
    //tell app preferences (maybe) changed
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) preferencesChanged:self.preferences];
    
bail:
    
    return;
}

//sort connections by timestamp descending
-(NSArray*)sortedConnections:(NSArray*)connections
{
    return [connections sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* left, NSDictionary* right) {
        
        //timestamps
        NSDate* leftTime = left[KEY_TIMESTAMP];
        NSDate* rightTime = right[KEY_TIMESTAMP];
        
        //best effort if invalid
        if(YES != [leftTime isKindOfClass:[NSDate class]]) leftTime = [NSDate distantPast];
        if(YES != [rightTime isKindOfClass:[NSDate class]]) rightTime = [NSDate distantPast];
        
        //descending
        return [rightTime compare:leftTime];
    }];
}

//convert protocol number to readable name
-(NSString*)protocolName:(NSNumber*)protocol
{
    if(IPPROTO_TCP == protocol.intValue) return @"TCP";
    if(IPPROTO_UDP == protocol.intValue) return @"UDP";
    if(IPPROTO_ICMP == protocol.intValue) return @"ICMP";
    return [NSString stringWithFormat:@"%d", protocol.intValue];
}

//simple html escaper
-(NSString*)htmlEscape:(NSString*)string
{
    if(nil == string) return @"";
    
    NSString* escaped = [string stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    return escaped;
}

//simple IP check
-(BOOL)isIPAddress:(NSString*)value
{
    //not set?
    if(0 == value.length) return NO;
    
    //IPv6 (simple check)
    if([value containsString:@":"]) return YES;
    
    //IPv4
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^([0-9]{1,3}\\.){3}[0-9]{1,3}$" options:0 error:nil];
    return (0 != [regex numberOfMatchesInString:value options:0 range:NSMakeRange(0, value.length)]);
}

//resolve IP to geo coordinates
-(NSDictionary*)geoForIP:(NSString*)ip
{
    //URL string
    NSString* encoded = [ip stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
    NSString* urlString = [NSString stringWithFormat:@"https://ipapi.co/%@/json/", encoded];
    
    //data
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if(nil == data) return nil;
    
    //json
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if(YES != [json isKindOfClass:[NSDictionary class]]) return nil;
    
    //lat/lon
    NSNumber* latitude = [json[@"latitude"] isKindOfClass:[NSNumber class]] ? json[@"latitude"] : nil;
    NSNumber* longitude = [json[@"longitude"] isKindOfClass:[NSNumber class]] ? json[@"longitude"] : nil;
    if( (nil == latitude) || (nil == longitude) ) return nil;
    
    return @{
        @"ip": ip,
        @"lat": latitude,
        @"lon": longitude,
        @"city": json[@"city"] ?: @"",
        @"country": json[@"country_name"] ?: @""
    };
}

//review pending silent-mode connections
-(IBAction)reviewPendingConnections:(id)sender
{
    //pending
    NSArray* pending = [self sortedConnections:[xpcDaemonClient getPendingConnections]];
    
    //none?
    if(0 == pending.count)
    {
        showAlert(NSAlertStyleInformational,
                  NSLocalizedString(@"No Pending Connections", @"No Pending Connections"),
                  NSLocalizedString(@"There are no queued silent-mode connections to review.", @"There are no queued silent-mode connections to review."),
                  @[NSLocalizedString(@"OK", @"OK")]);
        return;
    }
    
    //counts
    NSInteger allowed = 0;
    NSInteger blocked = 0;
    NSInteger skipped = 0;
    
    //review entries one-by-one
    for(NSDictionary* entry in pending)
    {
        //title
        NSString* title = [NSString stringWithFormat:NSLocalizedString(@"Review %@ → %@:%@", @"Review %@ → %@:%@"),
                           entry[KEY_PROCESS_NAME] ?: @"(unknown)",
                           entry[KEY_ENDPOINT_ADDR] ?: @"(unknown)",
                           entry[KEY_ENDPOINT_PORT] ?: @"-"];
        
        //details
        NSString* details = [NSString stringWithFormat:@"Path: %@\nProtocol: %@\nDecision needed for this queued connection.",
                             entry[KEY_PATH] ?: @"(unknown)",
                             [self protocolName:entry[KEY_PROTOCOL] ?: @0]];
        
        //response
        NSModalResponse response = showAlert(NSAlertStyleInformational,
                                             title,
                                             details,
                                             @[
                                                NSLocalizedString(@"Allow", @"Allow"),
                                                NSLocalizedString(@"Block", @"Block"),
                                                NSLocalizedString(@"Skip", @"Skip"),
                                                NSLocalizedString(@"Stop Review", @"Stop Review")
                                             ]);
        
        //allow
        if(NSAlertFirstButtonReturn == response)
        {
            if(YES == [xpcDaemonClient resolvePendingConnection:entry[KEY_UUID] action:@RULE_STATE_ALLOW])
            {
                allowed++;
            }
            continue;
        }
        
        //block
        if(NSAlertSecondButtonReturn == response)
        {
            if(YES == [xpcDaemonClient resolvePendingConnection:entry[KEY_UUID] action:@RULE_STATE_BLOCK])
            {
                blocked++;
            }
            continue;
        }
        
        //skip
        if(NSAlertThirdButtonReturn == response)
        {
            skipped++;
            continue;
        }
        
        //stop review
        break;
    }
    
    //refresh preferences and notify app
    self.preferences = [xpcDaemonClient getPreferences];
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) preferencesChanged:self.preferences];
    
    //summary
    showAlert(NSAlertStyleInformational,
              NSLocalizedString(@"Review Complete", @"Review Complete"),
              [NSString stringWithFormat:NSLocalizedString(@"Allowed: %ld\nBlocked: %ld\nSkipped: %ld", @"Allowed: %ld\nBlocked: %ld\nSkipped: %ld"),
               (long)allowed, (long)blocked, (long)skipped],
              @[NSLocalizedString(@"OK", @"OK")]);
}

//import curated Lockdown-Mac bad actor lists and enable as block list
-(IBAction)importLockdownBlocklists:(id)sender
{
    //Lockdown feeds
    NSArray* feeds = @[
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/ransomware.txt",
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/crypto_mining.txt",
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/data_trackers.txt",
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/reporting.txt",
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/general_ads.txt",
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/marketing.txt",
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/facebook_inc.txt",
        @"https://raw.githubusercontent.com/confirmedcode/Lockdown-Mac/master/Block%20Lists/amazon_trackers.txt"
    ];
    
    //all domains
    NSMutableOrderedSet* items = [NSMutableOrderedSet orderedSet];
    
    //successful feeds
    NSInteger feedCount = 0;
    
    //load feeds
    for(NSString* feed in feeds)
    {
        //data
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:feed]];
        if(nil == data) continue;
        
        //to string
        NSString* content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(0 == content.length) continue;
        
        //mark successful feed
        feedCount++;
        
        //split lines
        NSArray* lines = [content componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
        for(NSString* line in lines)
        {
            //trim
            NSString* trimmed = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            
            //skip blanks/comments
            if( (0 == trimmed.length) ||
                (YES == [trimmed hasPrefix:@"#"]) )
            {
                continue;
            }
            
            [items addObject:trimmed.lowercaseString];
        }
    }
    
    //none loaded?
    if(0 == items.count)
    {
        showAlert(NSAlertStyleWarning,
                  NSLocalizedString(@"Import Failed", @"Import Failed"),
                  NSLocalizedString(@"Unable to download Lockdown-Mac block lists right now.", @"Unable to download Lockdown-Mac block lists right now."),
                  @[NSLocalizedString(@"OK", @"OK")]);
        return;
    }
    
    //destination directory
    NSString* appSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString* directory = [appSupport stringByAppendingPathComponent:@"LuLu"];
    NSString* path = [directory stringByAppendingPathComponent:@"lockdown_bad_actors.txt"];
    
    //create directory if needed
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    
    //save merged list
    NSString* merged = [[items array] componentsJoinedByString:@"\n"];
    if(YES != [merged writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil])
    {
        showAlert(NSAlertStyleWarning,
                  NSLocalizedString(@"Import Failed", @"Import Failed"),
                  NSLocalizedString(@"Failed to save merged block list to disk.", @"Failed to save merged block list to disk."),
                  @[NSLocalizedString(@"OK", @"OK")]);
        return;
    }
    
    //enable block list and set path
    self.preferences = [xpcDaemonClient updatePreferences:@{
        PREF_USE_BLOCK_LIST:@YES,
        PREF_BLOCK_LIST:path
    }];
    
    //sync UI state
    self.blockList.stringValue = path;
    self.blockList.enabled = YES;
    self.selectBlockListButton.enabled = YES;
    ((NSButton*)[self.listsView viewWithTag:BUTTON_USE_BLOCK_LIST]).state = NSControlStateValueOn;
    
    //notify app of preference changes
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) preferencesChanged:self.preferences];
    
    //done
    showAlert(NSAlertStyleInformational,
              NSLocalizedString(@"Lockdown Lists Imported", @"Lockdown Lists Imported"),
              [NSString stringWithFormat:NSLocalizedString(@"Imported %lu unique entries from %ld Lockdown-Mac lists.\nSaved to:\n%@", @"Imported %lu unique entries from %ld Lockdown-Mac lists.\nSaved to:\n%@"), (unsigned long)items.count, (long)feedCount, path],
              @[NSLocalizedString(@"OK", @"OK")]);
}

//open generated traffic insights (graphs + global map)
-(IBAction)openTrafficInsights:(id)sender
{
    //events
    NSArray* allEvents = [self sortedConnections:[xpcDaemonClient getConnectionEvents]];
    
    //none?
    if(0 == allEvents.count)
    {
        showAlert(NSAlertStyleInformational,
                  NSLocalizedString(@"No Traffic Data Yet", @"No Traffic Data Yet"),
                  NSLocalizedString(@"No connection telemetry has been captured yet.", @"No connection telemetry has been captured yet."),
                  @[NSLocalizedString(@"OK", @"OK")]);
        return;
    }
    
    //process in background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //limit
        NSUInteger maxEvents = MIN((NSUInteger)500, allEvents.count);
        NSArray* events = [allEvents subarrayWithRange:NSMakeRange(0, maxEvents)];
        
        //protocol and port counters
        NSMutableDictionary* protocolCounts = [NSMutableDictionary dictionary];
        NSMutableDictionary* portCounts = [NSMutableDictionary dictionary];
        
        //IP candidates for geolocation
        NSMutableOrderedSet* uniqueIPs = [NSMutableOrderedSet orderedSet];
        
        //aggregate
        for(NSDictionary* event in events)
        {
            NSString* protocol = [self protocolName:event[KEY_PROTOCOL] ?: @0];
            protocolCounts[protocol] = @([protocolCounts[protocol] integerValue] + 1);
            
            NSString* port = event[KEY_ENDPOINT_PORT] ?: @"-";
            portCounts[port] = @([portCounts[port] integerValue] + 1);
            
            NSString* endpoint = event[KEY_ENDPOINT_ADDR];
            if(YES == [self isIPAddress:endpoint])
            {
                [uniqueIPs addObject:endpoint];
            }
        }
        
        //top ports
        NSArray* topPorts = [portCounts keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber* left, NSNumber* right) {
            return [right compare:left];
        }];
        if(topPorts.count > 8)
        {
            topPorts = [topPorts subarrayWithRange:NSMakeRange(0, 8)];
        }
        
        //resolve geo markers (best effort, capped)
        NSMutableArray* markers = [NSMutableArray array];
        NSUInteger markerLimit = MIN((NSUInteger)20, uniqueIPs.count);
        for(NSUInteger i = 0; i < markerLimit; i++)
        {
            NSDictionary* geo = [self geoForIP:uniqueIPs[i]];
            if(nil != geo)
            {
                [markers addObject:geo];
            }
        }
        
        //build html
        NSMutableString* html = [NSMutableString string];
        [html appendString:@"<!doctype html><html><head><meta charset='utf-8'><title>LuLu Traffic Insights</title>"];
        [html appendString:@"<meta name='viewport' content='width=device-width, initial-scale=1'>"];
        [html appendString:@"<link rel='stylesheet' href='https://unpkg.com/leaflet@1.9.4/dist/leaflet.css' />"];
        [html appendString:@"<style>body{font-family:-apple-system,Helvetica,Arial,sans-serif;background:#f4f7fb;color:#111;margin:0;padding:20px;}"];
        [html appendString:@"h1{margin:0 0 6px 0;font-size:24px;}h2{margin:18px 0 8px 0;font-size:18px;}"];
        [html appendString:@".card{background:#fff;border:1px solid #dde3ea;border-radius:10px;padding:14px;margin-bottom:14px;}"];
        [html appendString:@".bar{margin:8px 0;} .bar .label{font-size:13px;margin-bottom:4px;} .bar .track{height:12px;background:#e8eef7;border-radius:8px;overflow:hidden;}"];
        [html appendString:@".bar .fill{height:12px;background:#2f6fec;} table{width:100%;border-collapse:collapse;font-size:12px;} th,td{padding:6px;border-bottom:1px solid #eef2f7;text-align:left;}"];
        [html appendString:@"#map{height:420px;border-radius:10px;overflow:hidden;border:1px solid #dde3ea;} .muted{color:#5f6b7a;font-size:12px;} </style></head><body>"];
        
        [html appendFormat:@"<h1>LuLu Traffic Insights</h1><div class='muted'>Generated %@</div>", [NSDate date]];
        
        //protocol chart
        [html appendString:@"<div class='card'><h2>Protocol Distribution</h2>"];
        NSInteger protocolMax = 1;
        for(NSNumber* count in protocolCounts.allValues)
        {
            if(count.integerValue > protocolMax) protocolMax = count.integerValue;
        }
        for(NSString* key in [protocolCounts keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber* left, NSNumber* right) { return [right compare:left]; }])
        {
            NSInteger count = [protocolCounts[key] integerValue];
            NSInteger pct = (NSInteger)((count * 100.0f) / protocolMax);
            [html appendFormat:@"<div class='bar'><div class='label'>%@ (%ld)</div><div class='track'><div class='fill' style='width:%ld%%'></div></div></div>", [self htmlEscape:key], (long)count, (long)pct];
        }
        [html appendString:@"</div>"];
        
        //port chart
        [html appendString:@"<div class='card'><h2>Top Destination Ports</h2>"];
        NSInteger portMax = 1;
        for(NSString* port in topPorts)
        {
            NSInteger count = [portCounts[port] integerValue];
            if(count > portMax) portMax = count;
        }
        for(NSString* port in topPorts)
        {
            NSInteger count = [portCounts[port] integerValue];
            NSInteger pct = (NSInteger)((count * 100.0f) / portMax);
            [html appendFormat:@"<div class='bar'><div class='label'>%@ (%ld)</div><div class='track'><div class='fill' style='width:%ld%%'></div></div></div>", [self htmlEscape:port], (long)count, (long)pct];
        }
        [html appendString:@"</div>"];
        
        //map
        [html appendString:@"<div class='card'><h2>Global Outgoing Traffic Map (IP-based)</h2><div id='map'></div><div class='muted'>Markers are best-effort geo lookups for remote IPs.</div></div>"];
        
        //recent table
        [html appendString:@"<div class='card'><h2>Recent Connections</h2><table><thead><tr><th>Time</th><th>App</th><th>Endpoint</th><th>Port</th><th>Protocol</th><th>Decision</th><th>Reason</th></tr></thead><tbody>"];
        for(NSDictionary* event in events)
        {
            NSDate* timestamp = [event[KEY_TIMESTAMP] isKindOfClass:[NSDate class]] ? event[KEY_TIMESTAMP] : [NSDate date];
            NSString* time = [NSDateFormatter localizedStringFromDate:timestamp dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
            [html appendFormat:@"<tr><td>%@</td><td>%@</td><td>%@</td><td>%@</td><td>%@</td><td>%@</td><td>%@</td></tr>",
             [self htmlEscape:time],
             [self htmlEscape:event[KEY_PROCESS_NAME] ?: @"-"],
             [self htmlEscape:event[KEY_ENDPOINT_ADDR] ?: @"-"],
             [self htmlEscape:event[KEY_ENDPOINT_PORT] ?: @"-"],
             [self htmlEscape:[self protocolName:event[KEY_PROTOCOL] ?: @0]],
             [self htmlEscape:event[KEY_DECISION] ?: @"-"],
             [self htmlEscape:event[KEY_REASON] ?: @"-"]];
        }
        [html appendString:@"</tbody></table></div>"];
        
        //map script
        NSData* markerData = [NSJSONSerialization dataWithJSONObject:markers options:0 error:nil];
        NSString* markerJSON = [[NSString alloc] initWithData:markerData encoding:NSUTF8StringEncoding] ?: @"[]";
        [html appendString:@"<script src='https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'></script><script>"];
        [html appendFormat:@"const markers=%@;", markerJSON];
        [html appendString:@"const map=L.map('map').setView([20,0],2);"];
        [html appendString:@"L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:18,attribution:'&copy; OpenStreetMap contributors'}).addTo(map);"];
        [html appendString:@"if(markers.length===0){document.getElementById('map').innerHTML='<div style=\"padding:16px;color:#5f6b7a;\">No IP geolocation data available for current events.</div>'; }"];
        [html appendString:@"const bounds=[]; markers.forEach(m=>{ const label=[m.ip,m.city,m.country].filter(Boolean).join(' - '); L.marker([m.lat,m.lon]).addTo(map).bindPopup(label); bounds.push([m.lat,m.lon]); }); if(bounds.length){ map.fitBounds(bounds,{padding:[30,30]}); }"];
        [html appendString:@"</script></body></html>"];
        
        //write file
        NSString* output = [NSTemporaryDirectory() stringByAppendingPathComponent:@"lulu-traffic-insights.html"];
        NSError* writeError = nil;
        BOOL written = [html writeToFile:output atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
        
        //open on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if(YES != written)
            {
                showAlert(NSAlertStyleWarning,
                          NSLocalizedString(@"Failed to Build Insights", @"Failed to Build Insights"),
                          writeError.localizedDescription ?: NSLocalizedString(@"Unknown error while writing insights file.", @"Unknown error while writing insights file."),
                          @[NSLocalizedString(@"OK", @"OK")]);
                return;
            }
            
            [NSWorkspace.sharedWorkspace openURL:[NSURL fileURLWithPath:output]];
        });
    });
}

//'check for update' button handler
-(IBAction)check4Update:(id)sender
{
    //update obj
    Update* update = nil;
    
    //disable button
    self.updateButton.enabled = NO;
    
    //reset
    self.updateLabel.stringValue = @"";
    
    //show/start spinner
    [self.updateIndicator startAnimation:self];
    
    //init update obj
    update = [[Update alloc] init];
    
    //check
    // but after a delay for UI
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(),
    ^{
        //check for update
        [update checkForUpdate:^(NSUInteger result, NSString* newVersion) {
            
            //process response
            [self updateResponse:result newVersion:newVersion];
            
        }];
    });
    
    return;
}

//'view rules' button handler
// call helper method to show rule's window
-(IBAction)viewRules:(id)sender
{
    //call into app delegate to show app rules
    [((AppDelegate*)[[NSApplication sharedApplication] delegate]) showRules:nil];
    
    return;
}

//process update response
// error, no update, update/new version
-(void)updateResponse:(NSInteger)result newVersion:(NSString*)newVersion
{
    //re-enable button
    self.updateButton.enabled = YES;
    
    //stop/hide spinner
    [self.updateIndicator stopAnimation:self];
    
    switch(result)
    {
        //error
        case Update_Error:
            
            //set label
            self.updateLabel.stringValue = NSLocalizedString(@"error: update check failed", @"error: update check failed");
            break;
            
        //no updates
        case Update_None:
            
            //dbg msg
            os_log_debug(logHandle, "no updates available");
            
            //set label
            self.updateLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Installed version (%@),\r\nis the latest.",@"Installed version (%@),\r\nis the latest."), getAppVersion()];
           
            break;
            
        //update is not compatible
        case Update_NotSupported:
            
            //dbg msg
            os_log_debug(logHandle, "update available, but isn't supported on macOS %ld.%ld", NSProcessInfo.processInfo.operatingSystemVersion.majorVersion, NSProcessInfo.processInfo.operatingSystemVersion.minorVersion);
            
            //set label
            self.updateLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Update available, but isn't supported on macOS %ld.%ld", @"Update available, but isn't supported on macOS %ld.%ld"), NSProcessInfo.processInfo.operatingSystemVersion.majorVersion, NSProcessInfo.processInfo.operatingSystemVersion.minorVersion];
           
            break;
         
        //new version
        case Update_Available:
            
            //dbg msg
            os_log_debug(logHandle, "a new version (%@) is available", newVersion);
            
            //alloc update window
            updateWindowController = [[UpdateWindowController alloc] initWithWindowNibName:@"UpdateWindow"];
            
            //configure
            [self.updateWindowController configure:[NSString stringWithFormat:NSLocalizedString(@"a new version (%@) is available!",@"a new version (%@) is available!"), newVersion]];
            
            //center window
            [[self.updateWindowController window] center];
            
            //show it
            [self.updateWindowController showWindow:self];
            
            //invoke function in background that will make window modal
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                //make modal
                makeModal(self.updateWindowController);
                
            });
            
            break;
    }
    
    return;
}

//button handler
// open LuLu home page/docs
-(IBAction)openHomePage:(id)sender {
    
    //open
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:PRODUCT_URL]];
    
    return;
}

//on window close
// update prefs/set activation policy
-(void)windowWillClose:(NSNotification *)notification
{
    //blank allow list?
    // uncheck 'enabled' and update prefs
    if(0 == self.allowList.stringValue.length)
    {
        //uncheck 'allow list' radio button
        ((NSButton*)[self.listsView viewWithTag:BUTTON_USE_ALLOW_LIST]).state = NSControlStateValueOff;
        
        //disable 'browse' button
        self.selectAllowListButton.enabled = NSControlStateValueOff;
        
        //clear allow list
        self.allowList.stringValue = @"";
        
        //disable allow list input
        self.allowList.enabled = NSControlStateValueOff;
        
        //send XPC msg to daemon to update prefs
        self.preferences = [xpcDaemonClient updatePreferences:@{PREF_USE_ALLOW_LIST:@0, PREF_ALLOW_LIST:@""}];
    }
    
    //allow list changed? capture!
    // this logic is needed, as window can be closed when text field still has focus and 'end edit' won't have fired
    else if(YES != [self.preferences[PREF_ALLOW_LIST] isEqualToString:self.allowList.stringValue])
    {
        //send XPC msg to daemon to update prefs
        self.preferences = [xpcDaemonClient updatePreferences:@{PREF_ALLOW_LIST:self.allowList.stringValue}];
    }
    
    //blank block list?
    // uncheck 'enabled' and update prefs
    if(0 == self.blockList.stringValue.length)
    {
        //uncheck 'blocklist' radio button
        ((NSButton*)[self.listsView viewWithTag:BUTTON_USE_BLOCK_LIST]).state = NSControlStateValueOff;
        
        //disable 'browse' button
        self.selectBlockListButton.enabled = NSControlStateValueOff;
        
        //clear block list
        self.blockList.stringValue = @"";
        
        //disable block list input
        self.blockList.enabled = NSControlStateValueOff;
        
        //send XPC msg to daemon to update prefs
        self.preferences = [xpcDaemonClient updatePreferences:@{PREF_USE_BLOCK_LIST:@0, PREF_BLOCK_LIST:@""}];
    }
        
    //block list changed? capture!
    // this logic is needed, as window can be closed when text field still has focus and 'end edit' won't have fired
    else if(YES != [self.preferences[PREF_BLOCK_LIST] isEqualToString:self.blockList.stringValue])
    {
        //send XPC msg to daemon to update prefs
        // returns (all/latest) prefs, which is what we want
        self.preferences = [xpcDaemonClient updatePreferences:@{PREF_BLOCK_LIST:self.blockList.stringValue}];
    }
     
    //wait a bit, then set activation policy
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
         //on main thread
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             
             //set activation policy
             [((AppDelegate*)[[NSApplication sharedApplication] delegate]) setActivationPolicy];
             
         });
    });
    
    return;
}
@end
