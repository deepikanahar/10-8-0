//
//  I2ICustomBack.h
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 06/09/17.
//  Modified by Pradeep Yadav on 06/09/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

//  This class is the combination of Scenario controller and DynamicText class
#ifndef I2ICustomBack_h
#define I2ICustomBack_h
#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>
#import <MicroStrategyMobileSDK/MSTRVCRetriever.h>


@interface I2ICustomBack : MSIWidgetViewer <MSTRVCRetrieverDelegate> {
    
    UIView *linkView;
    NSString *linkViewType;
    NSString *linkViewDisplay;
    
    NSString *customURL;
    NSString *objectId;
    NSString *elementPromptAnswers;
    NSString *valuePromptAnswers;
    
    MSTRVCRetriever *vcRetriever;
    
}

@property (retain,nonatomic) MSIModelData *dataModel;

@end

#endif
