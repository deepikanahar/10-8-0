//
//  Initialisation.h
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 15/10/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef Initialisation_h
#define Initialisation_h
#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIPropertyGroup.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>
#import "PlistData.h"
#import "FormulaEvaluator.h"

@interface Initialisation : MSIWidgetViewer {
    
    int intVariables;
    FormulaEvaluator *eval;
    NSMutableDictionary *metrics;
    NSString *companyID;
    NSString *companyKey;
    
}

@property (retain,nonatomic) MSIModelData *modelData;
-(void)readData;

@end

#endif
