//
//  RememberRecipient.h
//  c100Benchmarking
//
//  Created by Deepika Nahar on 21/02/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface RememberRecipient : NSObject {
    
    NSString *recipient;
    NSString *domain;
    
}

#pragma mark - Constant Declaration
extern NSString *const RECIPIENT;
extern NSString *const REMEMBERME;
extern NSString *const EMAILDOMAIN;

#pragma mark - Class method declaration
/**
 *  Declaring a class instance which should be a Singletone Instance of this class.
 */
+(RememberRecipient *)sharedGlobalInstance;

/**
 *  Saving the App preference in NSUserDefaults to use it inside the app anytime
 *
 *  @param value is the stored value which we can retrive late by using Key. It stores at memory
 *  @param key by which we can retrive value which we are storing for futher use in our app.
 */
- (void)saveRecipient:(id)value
              withKey:(NSString *)key;

/**
 *  Get the stored value from the app for further use if needed through out the app.
 *
 *  @param key by which we can retrive value which we are storing for futher use in our app.
 *
 *  @return id instance type whihc can hold any type of variable.
 */
- (id)getRecipient:(NSString *)key;

/**
 *  Saving the condition based value like Boolean, Integer as id can not store integer or boolean type variable as they are non-primitive type data.
 *
 *  @param value passing True or False to the parameter.
 *  @param key   on which name it will store it and later it will be useful for retriving.
 */

-(void)saveAppCheckingCondition:(BOOL)value
                        withKey:(NSString *)key;
/**
 *  Get the stored condition based value whihc is used through the app.
 *
 *  @param key on which key it is being stored at the App memory.
 *
 *  @return the True or False results to check condition.
 */
-(BOOL)getAppCheckingCondtion:(NSString *)key;

@end
