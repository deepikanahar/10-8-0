//
//  I2ICustomURL.h
//  c100CapitalStructure
//
//  Created by Deepika Nahar on 12/07/17.
//  Modified by Pradeep Yadav on 03/08/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

//  This class is the combination of Scenario controller and DynamicText class
#ifndef I2ICustomURL_h
#define I2ICustomURL_h
#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>
#import <MicroStrategyMobileSDK/MSTRVCRetriever.h>


@interface I2ICustomURL : MSIWidgetViewer <MSTRVCRetrieverDelegate> {
    
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
