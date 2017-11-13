//
//  PlistData.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 30/12/14.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef PlistData_h
#define PlistData_h

@interface PlistData : NSObject

//  Function to set values in plist
+(void)setValue:(NSString *)Value
   keyForSlider:(NSString *)Key;

//  Function to get values from plist
+(NSDictionary *)getValue;

//  Function to delete key from plist
+(void)removeKey:(NSString *)Key;

@end

#endif
