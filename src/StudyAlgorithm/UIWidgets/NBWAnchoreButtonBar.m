//
//  NBWAnchoreButtonBar.m
//  StudyAlgorithm
//
//  Created by Zhao Yu on 8/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NBWAnchoreButtonBar.h"
#import <BWToolkitFramework/BWToolkitFramework.h>

@implementation NBWAnchoreButtonBar

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.isResizable = true;
        self.isAtBottom = true;
//        [self setBoundsSize:NSMakeSize(235, 32)];
//        [self setFrameSize:NSMakeSize(235, 32)];
    }
    
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

@end
