//
//  MyWindowController.m
//  StudyAlgorithm
//
//  Created by Zhao Yu on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyWindowController.h"

#import "IconViewController.h"
#import "ImageAndTextCell.h"
#import "SeparatorCell.h"
#import "ChildNode.h"
#import "BaseNode.h"

#define COLUMNID_NAME			@"NameColumn"	// the single column name in our outline view
#define INITIAL_INFODICT		@"Outline"		// name of the dictionary file to populate our outline view

#define ICONVIEW_NIB_NAME		@"IconView"		// nib name for the icon view
#define FILEVIEW_NIB_NAME		@"FileView"		// nib name for the file view
#define CHILDEDIT_NAME			@"ChildEdit"	// nib name for the child edit window controller

#define UNTITLED_NAME			@"Untitled"		// default name for added folders and leafs

#define HTTP_PREFIX				@"http://"

// default folder titles
#define DEVICES_NAME			@"DEVICES"
#define PLACES_NAME				@"PLACES"

// keys in our disk-based dictionary representing our outline view's data
#define KEY_NAME				@"name"
#define KEY_URL					@"url"
#define KEY_SEPARATOR			@"separator"
#define KEY_GROUP				@"group"
#define KEY_FOLDER				@"folder"
#define KEY_ENTRIES				@"entries"
#define KEY_INNER               @"inner"

#define kMinOutlineViewSplit	120.0f

#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type

// -------------------------------------------------------------------------------
//	TreeAdditionObj
//
//	This object is used for passing data between the main and secondary thread
//	which populates the outline view.
// -------------------------------------------------------------------------------
@interface TreeAdditionObj : NSObject
{
	NSIndexPath *indexPath;
	NSString	*nodeURL;
	NSString	*nodeName;
	BOOL		selectItsParent;
    BOOL        inResources;
}

@property (readonly) NSIndexPath *indexPath;
@property (readonly) NSString *nodeURL;
@property (readonly) NSString *nodeName;
@property (readonly) BOOL selectItsParent;
@property (readonly) BOOL inResources;
@end

@implementation TreeAdditionObj
@synthesize indexPath, nodeURL, nodeName, selectItsParent,inResources;

// -------------------------------------------------------------------------------
- (id)initWithURL:(NSString *)url withName:(NSString *)name selectItsParent:(BOOL)select inResources:(BOOL) inner
{
	self = [super init];
	
	nodeName = name;
	nodeURL = url;
	selectItsParent = select;
	inResources = inner;
	return self;
}
- (id)initWithURL:(NSString *)url withName:(NSString *)name selectItsParent:(BOOL)select
{
	return [self initWithURL:url withName:name selectItsParent:select inResources:NO];
}

@end

@implementation MyWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        contents = [[NSMutableArray alloc] init];
		windowName = @"StudyAlgorithm ";
		// cache the reused icon images
		folderImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] retain];
		[folderImage setSize:NSMakeSize(16,16)];
		
		urlImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericURLIcon)] retain];
		[urlImage setSize:NSMakeSize(16,16)];
//        [webView setOpaque:NO];
//        [webView setBackgroundColor:[NSColor clearColor]];
//        [webView setDrawsBackground:NO];
//        [webView setAcceptsTouchEvents:NO];
//        [webView changeColor:[NSColor grayColor]];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

// -------------------------------------------------------------------------------
//	selectParentFromSelection:
//
//	Take the currently selected node and select its parent.
// -------------------------------------------------------------------------------
- (void)selectParentFromSelection
{
	if ([[treeController selectedNodes] count] > 0)
	{
		NSTreeNode* firstSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
		NSTreeNode* parentNode = [firstSelectedNode parentNode];
		if (parentNode)
		{
			// select the parent
			NSIndexPath* parentIndex = [parentNode indexPath];
			[treeController setSelectionIndexPath:parentIndex];
		}
		else
		{
			// no parent exists (we are at the top of tree), so make no selection in our outline
			NSArray* selectionIndexPaths = [treeController selectionIndexPaths];
			[treeController removeSelectionIndexPaths:selectionIndexPaths];
		}
	}
}
// -------------------------------------------------------------------------------
//	performAddFolder:treeAddition
// -------------------------------------------------------------------------------
-(void)performAddFolder:(TreeAdditionObj *)treeAddition
{
	// NSTreeController inserts objects using NSIndexPath, so we need to calculate this
	NSIndexPath *indexPath = nil;
	
	// if there is no selection, we will add a new group to the end of the contents array
	if ([[treeController selectedObjects] count] == 0)
	{
		// there's no selection so add the folder to the top-level and at the end
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	}
	else
	{
		// get the index of the currently selected node, then add the number its children to the path -
		// this will give us an index which will allow us to add a node to the end of the currently selected node's children array.
		//
		indexPath = [treeController selectionIndexPath];
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf])
		{
			// user is trying to add a folder on a selected child,
			// so deselect child and select its parent for addition
			[self selectParentFromSelection];
		}
		else
		{
			indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
		}
	}
	
	ChildNode *node = [[ChildNode alloc] init];
	[node setNodeTitle:[treeAddition nodeName]];
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
	
	[node release];
}
// -------------------------------------------------------------------------------
//	performAddChild:treeAddition
// -------------------------------------------------------------------------------
-(void)performAddChild:(TreeAdditionObj *)treeAddition
{
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection
		if ([[[treeController selectedObjects] objectAtIndex:0] isLeaf])
		{
			// trying to add a child to a selected leaf node, so select its parent for add
			[self selectParentFromSelection];
		}
	}
	
	// find the selection to insert our node
	NSIndexPath *indexPath;
	if ([[treeController selectedObjects] count] > 0)
	{
		// we have a selection, insert at the end of the selection
		indexPath = [treeController selectionIndexPath];
		indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
	}
	else
	{
		// no selection, just add the child to the end of the tree
		indexPath = [NSIndexPath indexPathWithIndex:[contents count]];
	}
	
	// create a leaf node
	ChildNode *node = [[ChildNode alloc] initLeaf];
	[node setURL:[treeAddition nodeURL]];
    [node setinResources:[treeAddition inResources]];
	
	if ([treeAddition nodeURL])
	{
		if ([[treeAddition nodeURL] length] > 0)
		{
			// the child to insert has a valid URL, use its display name as the node title
			if ([treeAddition nodeName])
				[node setNodeTitle:[treeAddition nodeName]];
			else
				[node setNodeTitle:[[NSFileManager defaultManager] displayNameAtPath:[node urlString]]];
		}
		else
		{
			// the child to insert will be an emppty URL
			[node setNodeTitle:UNTITLED_NAME];
			[node setURL:HTTP_PREFIX];
		}
	}
	
	// the user is adding a child node, tell the controller directly
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
    
	[node release];
	
	// adding a child automatically becomes selected by NSOutlineView, so keep its parent selected
	if ([treeAddition selectItsParent])
		[self selectParentFromSelection];
}
// -------------------------------------------------------------------------------
//	addChild:url:withName:
// -------------------------------------------------------------------------------
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select inResources:(BOOL) inner
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:url withName:nameStr selectItsParent:select inResources:inner];
	
	if (buildingOutlineView)
	{
		// add the child node to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddChild:) withObject:treeObjInfo waitUntilDone:YES];
	}
	else
	{
		[self performAddChild:treeObjInfo];
	}
	
	[treeObjInfo release];
}
- (void)addChild:(NSString *)url withName:(NSString *)nameStr selectParent:(BOOL)select
{
	[self addChild:url withName:nameStr selectParent:select inResources:NO];
}




// -------------------------------------------------------------------------------
//	addFolder:folderName:
// -------------------------------------------------------------------------------
- (void)addFolder:(NSString *)folderName
{
	TreeAdditionObj *treeObjInfo = [[TreeAdditionObj alloc] initWithURL:nil withName:folderName selectItsParent:NO];
	
	if (buildingOutlineView)
	{
		// add the folder to the tree controller, but on the main thread to avoid lock ups
		[self performSelectorOnMainThread:@selector(performAddFolder:) withObject:treeObjInfo waitUntilDone:YES];
	}
	else
	{
		[self performAddFolder:treeObjInfo];
	}
	
	[treeObjInfo release];
}
// -------------------------------------------------------------------------------
//	addDevicesSection:
// -------------------------------------------------------------------------------
- (void)addDevicesSection
{
	// insert the "Devices" group at the top of our tree
	[self addFolder:DEVICES_NAME];
	
	// automatically add mounted and removable volumes to the "Devices" group
	NSArray *mountedVols = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]; 
	if ([mountedVols count] > 0)
	{
		for (NSString *element in mountedVols)
			[self addChild:element withName:nil selectParent:YES];
	}
    
	[self selectParentFromSelection];
}

// -------------------------------------------------------------------------------
//	addPlacesSection:
// -------------------------------------------------------------------------------
- (void)addPlacesSection
{
	// add the "Places" section
	[self addFolder:PLACES_NAME];
	
	// add its children
	[self addChild:NSHomeDirectory() withName:nil selectParent:YES];	
	[self addChild:[NSHomeDirectory() stringByAppendingPathComponent:@"Pictures"] withName:nil selectParent:YES];	
	[self addChild:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] withName:nil selectParent:YES];	
	[self addChild:@"/Applications" withName:nil selectParent:YES];
    
	[self selectParentFromSelection];
}
// -------------------------------------------------------------------------------
//	addEntries:
// -------------------------------------------------------------------------------
-(void)addEntries:(NSDictionary *)entries
{
	NSEnumerator *entryEnum = [entries objectEnumerator];
	
	id entry;
	while ((entry = [entryEnum nextObject]))
	{
		if ([entry isKindOfClass:[NSDictionary class]])
		{
			NSString *urlStr = [entry objectForKey:KEY_URL];
			
			if ([entry objectForKey:KEY_SEPARATOR])
			{
				// its a separator mark, we treat is as a leaf
				[self addChild:nil withName:nil selectParent:YES];
			}
			else if ([entry objectForKey:KEY_FOLDER])
			{
				// its a file system based folder,
				// we treat is as a leaf and show its contents in the NSCollectionView
				NSString *folderName = [entry objectForKey:KEY_FOLDER];
				[self addChild:urlStr withName:folderName selectParent:YES];
			}
			else if ([entry objectForKey:KEY_URL])
			{
				// its a leaf item with a URL
				NSString *nameStr = [entry objectForKey:KEY_NAME];
                if ([entry objectForKey:KEY_INNER]) { 
                    [self addChild:urlStr withName:nameStr selectParent:YES inResources:YES];
                }else{
                    [self addChild:urlStr withName:nameStr selectParent:YES];
                }
			}
			else
			{
				// it's a generic container
				NSString *folderName = [entry objectForKey:KEY_GROUP];
				[self addFolder:folderName];
				
				// add its children
				NSDictionary *entries = [entry objectForKey:KEY_ENTRIES];
				[self addEntries:entries];
				
				[self selectParentFromSelection];
			}
		}
	}
	
	// inserting children automatically expands its parent, we want to close it
	if ([[treeController selectedNodes] count] > 0)
	{
		NSTreeNode *lastSelectedNode = [[treeController selectedNodes] objectAtIndex:0];
		[myOutlineView collapseItem:lastSelectedNode];
	}
}

// -------------------------------------------------------------------------------
//	populateOutline:
//
//	Populate the tree controller from disk-based dictionary (Outline.dict)
// -------------------------------------------------------------------------------
- (void)populateOutline
{
	NSDictionary *initData = [NSDictionary dictionaryWithContentsOfFile:
                              [[NSBundle mainBundle] pathForResource:INITIAL_INFODICT ofType:@"dict"]];
	NSDictionary *entries = [initData objectForKey:KEY_ENTRIES];
	[self addEntries:entries];
}
// -------------------------------------------------------------------------------
//	populateOutlineContents:inObject
//
//	This method is being called on a separate thread to avoid blocking the UI
//	a startup time.
// -------------------------------------------------------------------------------
- (void)populateOutlineContents:(id)inObject
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	buildingOutlineView = YES;		// indicate to ourselves we are building the default tree at startup
    
	[myOutlineView setHidden:YES];	// hide the outline view - don't show it as we are building the contents
	
//	[self addDevicesSection];		// add the "Devices" outline section
//	[self addPlacesSection];		// add the "Places" outline section
	[self populateOutline];			// add the disk-based outline content
	
	buildingOutlineView = NO;		// we're done building our default tree
	
	// remove the current selection
	NSArray *selection = [treeController selectionIndexPaths];
	[treeController removeSelectionIndexPaths:selection];
	
	[myOutlineView setHidden:NO];	// we are done populating the outline view content, show it again
	
	[pool release];
}


-(void)awakeFromNib
{
//    [[self window]setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
//    [[self window]setContentBorderThickness:30 forEdge:NSMinYEdge];
    
    // apply our custom ImageAndTextCell for rendering the first column's cells
    NSTableColumn *tableColumn = [myOutlineView tableColumnWithIdentifier:COLUMNID_NAME];
    ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc]init]autorelease];
    [imageAndTextCell setEditable:NO];
    [tableColumn setDataCell:imageAndTextCell];
    
    separatorCell = [[SeparatorCell alloc ]init];
    [separatorCell setEditable:NO];
    
    // build our default tree on a separate thread,
	// some portions are from disk which could get expensive depending on the size of the dictionary file:
    [NSThread detachNewThreadSelector:	@selector(populateOutlineContents:)
                             toTarget:self		// we are the target
                           withObject:nil];
        
    
    // scroll to the top in case the outline contents is very long
	[[[myOutlineView enclosingScrollView] verticalScroller] setFloatValue:0.0];
	[[[myOutlineView enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0,0)];
    
    // make our outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
	[myOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
    
    
//    WebPreferences *prefs = [webView preferences];
//	[prefs _setLocalStorageDatabasePath:@"~/Library/StudyAlgorithm/LocalStorage"];
    
    [webView setUIDelegate:self];	// be the webView's delegate to capture NSResponder calls
    NSRect leftframe = [[[splitView subviews] objectAtIndex:0] frame];
    leftWidth = leftframe.size.width;
    //[hideButton removeFromSuperview];
    [hideButton setHidden:true];
    
}
#pragma mark - WebView delegate

// -------------------------------------------------------------------------------
//	webView:makeFirstResponder
//
//	We want to keep the outline view in focus as the user clicks various URLs.
//
//	So this workaround applies to an unwanted side affect to some web pages that might have
//	JavaScript code thatt focus their text fields as we target the web view with a particular URL.
//
// -------------------------------------------------------------------------------
- (void)webView:(WebView *)sender makeFirstResponder:(NSResponder *)responder
{
	if (retargetWebView)
	{
		// we are targeting the webview ourselves as a result of the user clicking
		// a url in our outlineview: don't do anything, but reset our target check flag
		//
		retargetWebView = NO;
	}
	else
	{
		// continue the responder chain
		[[self window] makeFirstResponder:sender];
	}
}
// -------------------------------------------------------------------------------
//	isSpecialGroup:
// -------------------------------------------------------------------------------
- (BOOL)isSpecialGroup:(BaseNode *)groupNode
{ 
    //return ([groupNode nodeIcon] == nil);
	return ([groupNode nodeIcon] == nil &&
			([[groupNode nodeTitle] isEqualToString:DEVICES_NAME] || [[groupNode nodeTitle] isEqualToString:PLACES_NAME]));
}
#pragma mark - NSOutlineView delegate
// -------------------------------------------------------------------------------
//	shouldSelectItem:item
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item;
{
	// don't allow special group nodes (Devices and Places) to be selected
	BaseNode* node = [item representedObject];
	return (![self isSpecialGroup:node]);
}

// -------------------------------------------------------------------------------
//	dataCellForTableColumn:tableColumn:row
// -------------------------------------------------------------------------------
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSCell* returnCell = [tableColumn dataCell];
	
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are being asked for the cell for the single and only column
		BaseNode* node = [item representedObject];
		if ([node nodeIcon] == nil && [[node nodeTitle] length] == 0)
			returnCell = separatorCell;
	}
	
	return returnCell;
}

// -------------------------------------------------------------------------------
//	textShouldEndEditing:
// -------------------------------------------------------------------------------
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if ([[fieldEditor string] length] == 0)
	{
		// don't allow empty node names
		return NO;
	}
	else
	{
		return YES;
	}
}

// -------------------------------------------------------------------------------
//	shouldEditTableColumn:tableColumn:item
//
//	Decide to allow the edit of the given outline view "item".
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
	BOOL result = YES;
	
	item = [item representedObject];
	if ([self isSpecialGroup:item])
	{
		result = NO; // don't allow special group nodes to be renamed
	}
	else
	{
		if ([[item urlString] isAbsolutePath])
			result = NO;	// don't allow file system objects to be renamed
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{	 
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME])
	{
		// we are displaying the single and only column
		if ([cell isKindOfClass:[ImageAndTextCell class]])
		{
			item = [item representedObject];
			if (item)
			{
				if ([item isLeaf])
				{
					// does it have a URL string?
					NSString *urlStr = [item urlString];
					if (urlStr)
					{
						if ([item isLeaf])
						{
							NSImage *iconImage;
							if ([[item urlString] hasPrefix:HTTP_PREFIX])
								iconImage = urlImage;
                            else if ([item inResources])
                                iconImage = urlImage;
							else
								iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
						else
						{
							NSImage* iconImage = [[NSWorkspace sharedWorkspace] iconForFile:urlStr];
							[item setNodeIcon:iconImage];
						}
					}
					else
					{
						// it's a separator, don't bother with the icon
					}
				}
				else
				{
					// check if it's a special folder (DEVICES or PLACES), we don't want it to have an icon
					if ([self isSpecialGroup:item])
					{
						[item setNodeIcon:nil];
					}
					else
					{
						// it's a folder, use the folderImage as its icon
						[item setNodeIcon:folderImage];
                        //[item setNodeIcon:nil];
					}
				}
			}
			
			// set the cell's image
			[(ImageAndTextCell*)cell setImage:[item nodeIcon]];
		}
	}
}

// -------------------------------------------------------------------------------
//	removeSubview:
// -------------------------------------------------------------------------------
- (void)removeSubview
{
	// empty selection
	NSArray *subViews = [placeHolderView subviews];
    for(int i=0;i<[subViews count];i++)
    {
        NSView *view = [subViews objectAtIndex:i];
        if([view isEqual:(hideButton)]){
            
        }else{
            [view removeFromSuperview];
        }
        
    }
	
	[placeHolderView displayIfNeeded];	// we want the removed views to disappear right away
}

// -------------------------------------------------------------------------------
//	changeItemView:
// ------------------------------------------------------------------------------
- (void)changeItemView
{
	NSArray		*selection = [treeController selectedNodes];	
	BaseNode	*node = [[selection objectAtIndex:0] representedObject];
	NSString	*urlStr = [node urlString];
	BOOL        inResource = [node inResources];
    NSString    *name = [node nodeTitle];
    [window setTitle:[windowName stringByAppendingString:name]];
    [[self window] setTitle:[windowName stringByAppendingString:name] ];
	if (urlStr)
	{
		NSURL *targetURL = [NSURL fileURLWithPath:urlStr];
		
		if ( inResource || [urlStr hasPrefix:HTTP_PREFIX])
		{
			// the url is a web-based url
			if (currentView != webView)
			{
				// change to web view
				[self removeSubview];
				currentView = nil;
				[placeHolderView addSubview:webView];
                [hideButton removeFromSuperview];
                //[[hideButton cell] setHidden:false];
                //[placeHolderView addSubview:hideButton positioned:NSWindowAbove relativeTo:nil];
                [webView addSubview:hideButton];
                [hideButton setHidden:false];
				currentView = webView;
			}
			
			// this will tell our WebUIDelegate not to retarget first responder since some web pages force
			// forus to their text fields - we want to keep our outline view in focus.
			retargetWebView = YES;	
			
            if (inResource) {
                [webView setMainFrameURL:nil];		// reset the webview to an empty frame
                NSString *resourcesPath = [[NSBundle mainBundle] resourcePath];
                NSString *htmlPath = [resourcesPath stringByAppendingString:urlStr];
                [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
                
            } else {
                [webView setMainFrameURL:nil];		// reset the webview to an empty frame
                [webView setMainFrameURL:urlStr];	// re-target to the new url
            }
			
		}
		/*
        else
		{
			// the url is file-system based (folder or file)
			if (currentView != [fileViewController view] || currentView != [iconViewController view])
			{
				// add a spinning progress gear in case populating the icon view takes too long
				NSRect bounds = [placeHolderView bounds];
				CGFloat x = (bounds.size.width-32)/2;
				CGFloat y = (bounds.size.height-32)/2;
				NSProgressIndicator* busyGear = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(x, y, 32, 32)];
				[busyGear setStyle:NSProgressIndicatorSpinningStyle];
				[busyGear startAnimation:self];
				[placeHolderView addSubview:busyGear];
				[placeHolderView displayIfNeeded];	// we want the removed views to disappear right away
                
				// detect if the url is a directory
				Boolean isDirectory;
				FSRef ref;
				FSPathMakeRef((const UInt8 *)[urlStr fileSystemRepresentation], &ref, &isDirectory);
				
				if (isDirectory)
				{
					// avoid a flicker effect by not removing the icon view if it is already embedded
					if (!(currentView == [iconViewController view]))
					{
						// remove the old subview
						[self removeSubview];
						currentView = nil;
					}
					
					// change to icon view to display folder contents
					[placeHolderView addSubview:[iconViewController view]];
					currentView = [iconViewController view];
					
					// its a directory - show its contents using NSCollectionView
					iconViewController.url = targetURL;
				}
				else
				{
					// its a file, just show the item info
                    
					// remove the old subview
					[self removeSubview];
					currentView = nil;
                    
					// change to file view
					[placeHolderView addSubview:[fileViewController view]];
					currentView = [fileViewController view];
					
					// update the file's info
					fileViewController.url = targetURL;
				}
				
				[busyGear removeFromSuperview];
			}
		}
		*/
		NSRect newBounds;
		newBounds.origin.x = 0;
		newBounds.origin.y = 0;
		newBounds.size.width = [[currentView superview] frame].size.width;
		newBounds.size.height = [[currentView superview] frame].size.height;
		//[currentView setFrame:[[currentView superview] frame]];
		[currentView setFrame:newBounds];

		// make sure our added subview is placed and resizes correctly
		[currentView setFrameOrigin:NSMakePoint(0,0)];
		[currentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	}
	else
	{
		// there's no url associated with this node
		// so a container was selected - no view to display
		[self removeSubview];
		currentView = nil;
	}
}

// -------------------------------------------------------------------------------
//	outlineViewSelectionDidChange:notification
// -------------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	if (buildingOutlineView)	// we are currently building the outline view, don't change any view selections
		return;
    
	// ask the tree controller for the current selection
	NSArray *selection = [treeController selectedObjects];
	if ([selection count] > 1)
	{
		// multiple selection - clear the right side view
		[self removeSubview];
		currentView = nil;
	}
	else
	{
		if ([selection count] == 1)
		{
			// single selection
			[self changeItemView];
		}
		else
		{
			// there is no current selection - no view to display
			[self removeSubview];
			currentView = nil;
		}
	}
}

// ----------------------------------------------------------------------------------------
// outlineView:isGroupItem:item
// ----------------------------------------------------------------------------------------
-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
{
	if ([self isSpecialGroup:[item representedObject]])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark - Split View Delegate

// -------------------------------------------------------------------------------
//	splitView:constrainMinCoordinate:
//
//	What you really have to do to set the minimum size of both subviews to kMinOutlineViewSplit points.
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate + kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:constrainMaxCoordinate:
// -------------------------------------------------------------------------------
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(int)index
{
	return proposedCoordinate - kMinOutlineViewSplit;
}

// -------------------------------------------------------------------------------
//	splitView:resizeSubviewsWithOldSize:
//
//	Keep the left split pane from resizing as the user moves the divider line.
// -------------------------------------------------------------------------------
- (void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [sender frame]; // get the new size of the whole splitView
	NSView *left = [[sender subviews] objectAtIndex:0];
	NSRect leftFrame = [left frame];
	NSView *right = [[sender subviews] objectAtIndex:1];
	NSRect rightFrame = [right frame];
    
	CGFloat dividerThickness = [sender dividerThickness];
    
	leftFrame.size.height = newFrame.size.height;
    
	rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
	rightFrame.size.height = newFrame.size.height;
	rightFrame.origin.x = leftFrame.size.width + dividerThickness;
    
	[left setFrame:leftFrame];
	[right setFrame:rightFrame];
}


// -------------------------------------------------------------------------------
//	setContents:newContents
// -------------------------------------------------------------------------------
- (void)setContents:(NSArray*)newContents
{
	if (contents != newContents)
	{
		[contents release];
		contents = [[NSMutableArray alloc] initWithArray:newContents];
	}
}

// -------------------------------------------------------------------------------
//	contents:
// -------------------------------------------------------------------------------
- (NSMutableArray *)contents
{
	return contents;
}
- (IBAction)toggleTheLeft:(id)sender {
    CGFloat width = leftWidth;
    NSRect newFrame = [splitView frame];
    NSView *left = [[splitView subviews] objectAtIndex:0];
    NSRect leftFrame = [left frame];
    NSView *right = [[splitView subviews]objectAtIndex:1];
    NSRect rightFrame = [right frame];
    
    if (isLeftHiden) {
        [[hideButton cell] setUserInterfaceLayoutDirection:NSUserInterfaceLayoutDirectionRightToLeft];
        isLeftHiden = false;
    }else{
        [[hideButton cell] setUserInterfaceLayoutDirection:NSUserInterfaceLayoutDirectionLeftToRight];
        isLeftHiden = true;
        width = 0;
        leftWidth = leftFrame.size.width;
    }
    [hideButton setState:0];
    
    
    CGFloat dividerThickness = [splitView dividerThickness];
    
    leftFrame.size.height = newFrame.size.height;
    
    leftFrame.size.width = width;
    
    rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
    rightFrame.size.height = newFrame.size.height;
    rightFrame.origin.x = leftFrame.size.width + dividerThickness;
    
    [left setFrame:leftFrame];
    [right setFrame:rightFrame];
}
@end
















