//
//  RememberRecipient.m
//  c100Benchmarking
//
//  Created by Deepika Nahar on 21/02/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RememberRecipient.h"

@implementation RememberRecipient

NSString *const RECIPIENT = @"recipient";
NSString *const REMEMBERME = @"REMEMBERME";
NSString *const EMAILDOMAIN = @"DOMAIN";

#pragma mark - Defining A Singletone Instance
+(RememberRecipient *)sharedGlobalInstance {
    
    static RememberRecipient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[RememberRecipient alloc] init];
        
    });
    return sharedInstance;
    
}

#pragma mark - Instance Method Defination
-(void)saveRecipient:(id)value withKey:(NSString *)key {
    
    [[NSUserDefaults standardUserDefaults] setObject:value
                                              forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(id)getRecipient:(NSString *)key {
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
}

-(void)saveAppCheckingCondition:(BOOL)value withKey:(NSString *)key {
    
    [[NSUserDefaults standardUserDefaults] setBool:value
                                            forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(BOOL)getAppCheckingCondtion:(NSString *)key {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
    
}

@end
