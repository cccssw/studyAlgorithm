//
//  MyWindowController.h
//  StudyAlgorithm
//
//  Created by Zhao Yu on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class SeparatorCell;

@interface MyWindowController : NSWindowController
{  
    IBOutlet NSTreeController *treeController; 
    IBOutlet WebView *webView;
    
    IBOutlet NSButton *hideButton;
    IBOutlet NSWindow *window;
    IBOutlet NSView *placeHolderView;
    IBOutlet NSSplitView *splitView;
    IBOutlet NSOutlineView *myOutlineView;
    
    NSMutableArray				*contents;
    
    // cached images for generic folder and url document
	NSImage						*folderImage;
	NSImage						*urlImage;
    
    NSView						*currentView;
    
    BOOL						buildingOutlineView;	// signifies we are building the outline view at launch time
    
    NSArray						*dragNodesArray; // used to keep track of dragged nodes
    
    BOOL						retargetWebView;
    SeparatorCell				*separatorCell;	// the cell used to draw a separator line in the outline view
    
    NSString    *windowName;
    BOOL        isLeftHiden;
    CGFloat     leftWidth;
    
}
- (IBAction)toggleTheLeft:(id)sender;

@property (retain) NSArray *dragNodesArray;


- (void)setContents:(NSArray *)newContents;
- (NSMutableArray *)contents;

@end
