//
//  ALGAppDelegate.h
//  StudyAlgorithm
//
//  Created by Zhao Yu on 8/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class MyWindowController;

@interface ALGAppDelegate : NSObject <NSApplicationDelegate> {
//@interface ALGAppDelegate : NSObject{
    MyWindowController *myWindowController;
    NSPersistentStoreCoordinator *__persistentStoreCoordinator;
    NSManagedObjectModel *__managedObjectModel;
    NSManagedObjectContext *__managedObjectContext;
}

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;
- (IBAction)openReadMe:(id)sender;

@end
