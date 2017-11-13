//
//  I2IDynamicText.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 08/04/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IDynamicText_h
#define I2IDynamicText_h
#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIPropertyGroup.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>

@interface I2IDynamicText : MSIWidgetViewer {
    
    int intMetrics;
    int intTexts;
    NSMutableDictionary *metrics;
    // Text properties
    NSMutableAttributedString *strFullText;
    NSString *strPosition;
    int intNoFormulae;
    NSMutableArray *arrFormulae;
    NSString *strFontFace;
    int intFontSize;
    UIColor *fontColor;
    NSString *strTextAlignment;
    NSMutableString *strImage;
    
}

@property (retain,nonatomic) MSIModelData *modelData;

@end
#endif
