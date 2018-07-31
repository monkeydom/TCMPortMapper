#import "AppController.h"
#import <TCMPortMapper/TCMPortMapper.h>
#import "TCMStatusImageFromMappingStatusValueTransformer.h"
#import "TCMPortStringFromPublicPortValueTransformer.h"
#import "TCMPortMappingAdditions.h"

@implementation AppController

+ (void)initialize {
    [NSValueTransformer setValueTransformer:[TCMStatusImageFromMappingStatusValueTransformer new] forName:@"TCMStatusImageFromMappingStatus"];
    [NSValueTransformer setValueTransformer:[TCMPortStringFromPublicPortValueTransformer new] forName:@"TCMPortStringFromPublicPort"];
    [NSValueTransformer setValueTransformer:[TCMReplacedStringFromPortMappingReferenceStringValueTransformer new] forName:@"TCMReplacedStringFromPortMappingReferenceString"];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    NSWindow *mainWindow = [O_refreshButton window];
    if ([mainWindow respondsToSelector:@selector(setContentBorderThickness:forEdge:)]) {
        [mainWindow setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];
        [mainWindow setContentBorderThickness:90.0 forEdge:NSMaxYEdge];
    }

    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(portMapperExternalIPAddressDidChange:) name:TCMPortMapperExternalIPAddressDidChange object:pm];
    [center addObserver:self selector:@selector(portMapperWillSearchForRouter:) name:TCMPortMapperWillStartSearchForRouterNotification object:pm];
    [center addObserver:self selector:@selector(portMapperDidFindRouter:) name:TCMPortMapperDidFinishSearchForRouterNotification object:pm];
    [center addObserver:self selector:@selector(portMappingDidChangeMappingStatus:) name:TCMPortMappingDidChangeMappingStatusNotification object:nil];
    [center addObserver:self selector:@selector(startProgressIndicator:) name:TCMPortMapperDidStartWorkNotification object:nil];
    [center addObserver:self selector:@selector(stopProgressIndicator:) name:TCMPortMapperDidFinishWorkNotification   object:nil];
    NSEnumerator *mappings=[[[NSUserDefaults standardUserDefaults] objectForKey:@"StoredMappings"] objectEnumerator];
    NSDictionary *mappingRep = nil;
    while ((mappingRep = [mappings nextObject])) {
       TCMPortMapping *mapping = [TCMPortMapping portMappingWithDictionaryRepresentation:mappingRep];
       [O_mappingsArrayController addObject:mapping];
       [mapping addObserver:self forKeyPath:@"userInfo.active" options:0 context:nil];
       if ([[[mapping userInfo] objectForKey:@"active"] boolValue]) {
           [pm addPortMapping:mapping];
       }
    }
    [pm start]; 

    [center addObserver:self selector:@selector(portMapperDidReceiveUPNPMappingTable:) name:TCMPortMapperDidReceiveUPNPMappingTableNotification object:pm];

    NSArray *array = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Presets" ofType:@"plist"]];
    NSEnumerator *presets = [array objectEnumerator];
    NSDictionary *preset = nil;
    while ((preset = [presets nextObject])) {
        NSString *title = [preset objectForKey:@"mappingTitle"];
        if (title) {
            [O_addPresetPopupButton addItemWithTitle:title];
            [[[O_addPresetPopupButton itemArray] lastObject] setRepresentedObject:preset];
        }
    }
    
    // set the version
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = [NSString stringWithFormat:@"%@ %@ (%@)",[O_aboutVersionLineTextField stringValue],[infoDictionary objectForKey:@"CFBundleShortVersionString"],[infoDictionary objectForKey:@"CFBundleVersion"]];
    [O_aboutVersionLineTextField setStringValue:versionString];
}

- (void)writeMappingDefaults {
    NSEnumerator *mappings = [[O_mappingsArrayController arrangedObjects] objectEnumerator];
    NSMutableArray *mappingsToStore = [NSMutableArray array];
    TCMPortMapping *mapping = nil;
    while ((mapping=[mappings nextObject])) {
        [mappingsToStore addObject:[mapping dictionaryRepresentation]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:mappingsToStore forKey:@"StoredMappings"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self writeMappingDefaults];
    [[TCMPortMapper sharedInstance] stopBlocking];
}

- (IBAction)refresh:(id)aSender {
    [[TCMPortMapper sharedInstance] refresh];
}

- (NSWindow *)mainWindow {
    return [O_currentIPTextField window];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)aSender {
    [self.mainWindow orderFront:self];
    return NO;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    NSLog(@"%s %@ %@ %@",__FUNCTION__,keyPath,object,change);
    if ([[[object userInfo] objectForKey:@"active"] boolValue]) {
        [[TCMPortMapper sharedInstance] addPortMapping:object];
    } else {
        [[TCMPortMapper sharedInstance] removePortMapping:object];
    }
    [self writeMappingDefaults];
}

- (void)updateTagLine {
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    if ([pm isRunning]) {
        if ([pm externalIPAddress]) {
            [O_taglineTextField setStringValue:[NSString stringWithFormat:@"%@ - %@ - %@",[pm mappingProtocol],[pm routerName],[pm routerIPAddress]]];
        } else {
            [O_taglineTextField setStringValue:[NSString stringWithFormat:@"%@ - %@ - %@",[pm mappingProtocol],[pm routerName],[pm routerIPAddress]?[pm routerIPAddress]:NSLocalizedString(@"No Router",@"")]];
        }
    } else {
        [O_taglineTextField setStringValue:NSLocalizedString(@"Stopped",@"")];
    }

}

- (NSString *)externalIPAddressString {
    NSString *externalIPAddress = [[TCMPortMapper sharedInstance] externalIPAddress];
    if (!externalIPAddress || [externalIPAddress isEqualToString:@"0.0.0.0"]) {
        externalIPAddress = NSLocalizedString(@"No external Address.",@"");
    }
    return externalIPAddress;
}

- (void)portMapperExternalIPAddressDidChange:(NSNotification *)aNotification {
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    if ([pm isRunning]) {
        if ([pm externalIPAddress]) {
            [O_currentIPTextField setObjectValue:[self externalIPAddressString]];
        }
    } else {
        [O_currentIPTextField setStringValue:NSLocalizedString(@"Stopped",@"")];
    }
    [self updateTagLine];
}

- (IBAction)togglePortMapper:(id)aSender {
    if ([aSender state]==NSOnState) {
        [[TCMPortMapper sharedInstance] start];
    } else {
        [[TCMPortMapper sharedInstance] stop];
        [self portMapperExternalIPAddressDidChange:nil];
    }
}

- (void)portMapperWillSearchForRouter:(NSNotification *)aNotification {
    [O_refreshButton setEnabled:NO];
    [O_currentIPTextField setStringValue:NSLocalizedString(@"Searching...",@"")];
}

- (void)portMapperDidFindRouter:(NSNotification *)aNotification {
    [O_refreshButton setEnabled:YES];
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    NSString *externalIPAddress = pm.externalIPAddress;
    if (externalIPAddress) {
        if (externalIPAddress.IPv4AddressIsInPrivateSubnet) {
            [O_currentIPTextField setObjectValue:@"No external address."];
        } else {
            [O_currentIPTextField setObjectValue:[self externalIPAddressString]];
        }
    } else {
        if ([pm routerIPAddress]) {
            [O_currentIPTextField setStringValue:NSLocalizedString(@"Router incompatible.",@"")];
            [self showInstructionalPanel:self];
        } else {
            [O_currentIPTextField setStringValue:NSLocalizedString(@"Can't find router.",@"")];
        }
    }
    [self updateTagLine];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    NSTextView *fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
    if (fieldEditor == [O_addLocalPortField currentEditor]) {
        [O_addDesiredField setStringValue:[O_addLocalPortField stringValue]];
    }
    [O_invalidLocalPortView   setHidden:[O_addLocalPortField intValue]>0 && [O_addLocalPortField intValue]<=65535];
    [O_invalidDesiredPortView setHidden:  [O_addDesiredField intValue]>0 &&   [O_addDesiredField intValue]<=65535];
}

- (void)portMappingDidChangeMappingStatus:(NSNotification *)aNotification {
    [O_replacedReferenceStringTextField setStringValue:[[NSValueTransformer valueTransformerForName:@"TCMReplacedStringFromPortMappingReferenceString"] transformedValue:[O_mappingsArrayController selectedObjects]]];
}

- (void)startProgressIndicator:(NSNotification *)aNotification {
    [O_globalProgressIndicator startAnimation:self];
    [O_showUPNPMappingTableButton setEnabled:NO];
    [O_UPNPTabItemProgressIndicator startAnimation:self];
}


- (void)stopProgressIndicator:(NSNotification *)aNotification {
    [O_globalProgressIndicator stopAnimation:self];
    [O_UPNPTabItemProgressIndicator stopAnimation:self];
    [O_showUPNPMappingTableButton setEnabled:[[TCMPortMapper sharedInstance] mappingProtocol] == TCMUPNPPortMapProtocol];
    NSString *localIPAddress = [[TCMPortMapper sharedInstance] localIPAddress];
     if (!localIPAddress) {
        [self.mainWindow setTitle:@"Port Map"];
        [O_localIPAddressTextField setStringValue:@""];
     } else {
        [O_localIPAddressTextField setStringValue:localIPAddress];
        [self.mainWindow setTitle:[NSString stringWithFormat:NSLocalizedString(@"Port Map on %@",@""), localIPAddress]];
     }
}

#pragma mark -
#pragma mark IBActions

- (IBAction)addMappingEndSheet:(id)aSender {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"active",[O_addDescriptionField stringValue],@"mappingTitle",[O_addReferenceStringField stringValue],@"referenceString",nil];
    TCMPortMapping *mapping = [TCMPortMapping portMappingWithLocalPort:[O_addLocalPortField intValue] desiredExternalPort:[O_addDesiredField intValue] transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:userInfo];
    int transportProtocol = 0;
    if ([O_addProtocolTCPButton state] == NSOnState) transportProtocol+=TCMPortMappingTransportProtocolTCP;
    if ([O_addProtocolUDPButton state] == NSOnState) transportProtocol+=TCMPortMappingTransportProtocolUDP;
    [mapping setTransportProtocol:transportProtocol];
    [mapping addObserver:self forKeyPath:@"userInfo.active" options:0 context:nil];
    [O_mappingsArrayController addObject:mapping];
    [[TCMPortMapper sharedInstance] addPortMapping:mapping];
    [self.mainWindow endSheet:O_addSheetPanel returnCode:NSModalResponseOK];
    [self writeMappingDefaults];
}

- (IBAction)addMappingCancelSheet:(id)aSender {
    [self.mainWindow endSheet:O_addSheetPanel returnCode:NSModalResponseCancel];
}

- (IBAction)showInstructionalPanel:(id)aSender {
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"DontShowInstructionsAgain"] boolValue]) {
        [self.mainWindow beginSheet:O_instructionalSheetPanel completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSModalResponseContinue) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"NAT-PMP Howto URL",@"")]];
            }
        }];
    }
}

- (IBAction)endInstructionalSheet:(id)aSender {
    NSModalResponse response = NSModalResponseOK;
    if ([aSender tag] == 42) {
        response = NSModalResponseContinue;
    }
    
    if ([O_dontShowInstructionsAgainButton state] == NSOnState) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"DontShowInstructionsAgain"];    
    }
    [self.mainWindow endSheet:O_instructionalSheetPanel returnCode:response];
}

- (IBAction)choosePreset:(id)aSender {
//    NSLog(@"%s %@ %@ %@",__FUNCTION__,aSender, [aSender selectedItem],[[aSender selectedItem] representedObject]);
    NSDictionary *preset = [[aSender selectedItem] representedObject];
    [O_addLocalPortField setObjectValue:[preset objectForKey:@"localPort"]];
    [O_addDesiredField   setObjectValue:[preset objectForKey:@"desiredPort"]];
    [O_addReferenceStringField setObjectValue:[preset objectForKey:@"referenceString"]];
    [O_addDescriptionField setObjectValue:[preset objectForKey:@"mappingTitle"]];
    [O_addProtocolTCPButton setState:([[preset objectForKey:@"transportProtocol"] intValue] & TCMPortMappingTransportProtocolTCP)?NSOnState:NSOffState];
    [O_addProtocolUDPButton setState:([[preset objectForKey:@"transportProtocol"] intValue] & TCMPortMappingTransportProtocolUDP)?NSOnState:NSOffState];
}


- (IBAction)addMapping:(id)aSender {
    [self.mainWindow beginSheet:O_addSheetPanel completionHandler:^(NSModalResponse returnCode) {
    }];
}

- (IBAction)removeMapping:(id)aSender {
    NSEnumerator *mappings = [[O_mappingsArrayController selectedObjects] objectEnumerator];
    TCMPortMapping *mapping = nil;
    while ((mapping=[mappings nextObject])) {
        if ([[[mapping userInfo] objectForKey:@"active"] boolValue]) {
            [[TCMPortMapper sharedInstance] removePortMapping:mapping];
        }
        [mapping removeObserver:self forKeyPath:@"userInfo.active"];
    }
    [O_mappingsArrayController removeObjects:[O_mappingsArrayController selectedObjects]];
}

- (IBAction)gotoPortMapHomepage:(id)aSender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Port Map URL",@"")]];
}

- (IBAction)gotoTCMPortMapperSources:(id)aSender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"TCMPortMapper URL",@"")]];
}

- (IBAction)reportABug:(id)aSender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Bugtracker URL",@"")]];
}

- (IBAction)showReleaseNotes:(id)aSender {
    NSURL *releaseNotesURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"portmap_releasenotes" ofType:@"html"]];
    [[NSWorkspace sharedWorkspace] openURL:releaseNotesURL];
}


- (IBAction)showAbout:(id)aSender {
    [O_aboutWindow center];
    [O_aboutWindow makeKeyAndOrderFront:self];
}

- (IBAction)requestUPNPMappingTable:(id)aSender {
    [[O_progressIndictatorTabItem tabView] selectTabViewItem:O_progressIndictatorTabItem];
    [[TCMPortMapper sharedInstance] requestUPNPMappingTable];
    [self.mainWindow beginSheet:O_showUPNPMappingListWindow completionHandler:^(NSModalResponse returnCode) {
    }];
}

- (void)portMapperDidReceiveUPNPMappingTable:(NSNotification *)aNotification {
    [O_UPNPMappingListArrayController setContent:[[aNotification userInfo] objectForKey:@"mappingTable"]];
    [[O_upnpMappingListTabItem tabView] selectTabViewItem:O_upnpMappingListTabItem];
}

- (IBAction)requestUPNPMappingTableRemoveMappings:(id)aSender {
    [[TCMPortMapper sharedInstance] removeUPNPMappings:[O_UPNPMappingListArrayController selectedObjects]];
    [NSApp endSheet:O_showUPNPMappingListWindow];
}

- (IBAction)requestUPNPMappingTableOKSheet:(id)aSender {
    [NSApp endSheet:O_showUPNPMappingListWindow];
}

@end
