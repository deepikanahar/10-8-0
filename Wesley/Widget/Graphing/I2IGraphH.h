//
//  I2IGraphH.h
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 30/12/14.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IGraphH_h
#define I2IGraphH_h

#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIPropertyGroup.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>
#import "I2IBarPlotH.h"
#import "PlistData.h"
#import "FormulaEvaluator.h"

@interface I2IGraphH : MSIWidgetViewer{
    FormulaEvaluator *eval;
    UIView *hostView;
    I2IBarPlotH *graph;
    // Title of the graph
    NSString *title;
    // Holds the number of sub-titles to be displayed. Should be equal to Bars - 1
    NSMutableArray *subtitles;
    // Holds the values for the subtitles to be displayed i.e. equal to Bars - 1
    NSMutableArray *subtitleData;
    // Size of font to be displayed on the graph title
    NSString *fsTitle;
    // Size of font to be displayed on the graph sub-titles
    NSString *fsSubTitle;
    // Data dictionary to hold supporting metrics
    NSMutableDictionary *metrics;
}
@property (retain,nonatomic) MSIModelData *modelData;

-(void)readDataValues;
-(void)readConstants;
-(void)readFormulae;
-(void)readFormattingInfo;

-(UIView *)renderWidgetContainer:(CGRect)frameRect;
-(UILabel *)createLableWithFrame:(CGRect)frmLabel text:(NSString *)txtLabel textColor:(UIColor *)clrLabel font:(UIFont *)fLabel align:(NSTextAlignment)txtAlignment;
@end
#endif
