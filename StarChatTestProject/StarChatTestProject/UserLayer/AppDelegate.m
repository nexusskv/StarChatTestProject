//
//  AppDelegate.m
//  StarChatTestProject
//
//  Created by rost on 18.11.14.
//  Copyright (c) 2014 rost. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"


@interface AppDelegate ()

@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[DB shared] setDBFileWithName:@"db_star_chat.sql"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    MainViewController *mainVC = [[MainViewController alloc] init];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:mainVC];
    self.window.rootViewController = self.navigationController;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
