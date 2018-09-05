//  AppController.h
//  Port Map.app

@import Cocoa;

@interface AppController : NSObject <NSApplicationDelegate> {
}

- (IBAction)togglePortMapper:(id)aSender;

- (IBAction)refresh:(id)aSender;
- (IBAction)addMapping:(id)aSender;
- (IBAction)removeMapping:(id)aSender;
- (IBAction)addMappingEndSheet:(id)aSender;
- (IBAction)addMappingCancelSheet:(id)aSender;
- (IBAction)choosePreset:(id)aSender;
- (IBAction)showInstructionalPanel:(id)aSender;
- (IBAction)endInstructionalSheet:(id)aSender;

- (IBAction)gotoTCMPortMapperSources:(id)aSender;
- (IBAction)reportABug:(id)aSender;
- (IBAction)showReleaseNotes:(id)aSender;

- (IBAction)showAbout:(id)aSender;

- (IBAction)requestUPNPMappingTable:(id)aSender;
- (IBAction)requestUPNPMappingTableRemoveMappings:(id)aSender;
- (IBAction)requestUPNPMappingTableOKSheet:(id)aSender;

@end
