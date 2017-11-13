//
//  I2IGraphV.h
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 30/12/14.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IGraphV_h
#define I2IGraphV_h

#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIPropertyGroup.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>
#import "I2IColumnPlotV.h"
#import "PlistData.h"
#import "FormulaEvaluator.h"

@interface I2IGraphV : MSIWidgetViewer{
    FormulaEvaluator *eval;
    UIView *hostView;
    I2IColumnPlotV *graph;
    // Title of the graph
    NSString *title;
    // Size of font to be displayed on the graph title
    NSString *fsTitle;
    // Data dictionary to hold supporting metrics
    NSMutableDictionary *metrics;
}
@property (retain,nonatomic) MSIModelData *modelData;

-(void)readDataValues;
-(void)readConstants;
-(void)readFormattingInfo;

-(UIView *)renderWidgetContainer:(CGRect)frameRect;
-(UILabel *)createLableWithFrame:(CGRect)frmLabel text:(NSString *)txtLabel textColor:(UIColor *)clrLabel font:(UIFont *)fLabel align:(NSTextAlignment)txtAlignment;

@end
#endif
