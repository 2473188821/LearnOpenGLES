//
//  AppDelegate.m
//  Demo
//
//  Created by Chenfy on 2020/5/13.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    ViewController *vc = [ViewController new];
    UINavigationController *nv = [[UINavigationController alloc]initWithRootViewController:vc];
    
    self.window.rootViewController = nv;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
