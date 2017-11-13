//
//  IntExpenseGraph.h
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 03/02/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef IntExpenseGraph_h
#define IntExpenseGraph_h

#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIPropertyGroup.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>
#import "I2IBarPlotIE.h"
#import "PlistData.h"
#import "FormulaEvaluator.h"

@interface IntExpenseGraph : MSIWidgetViewer{
    FormulaEvaluator *eval;
    UIView *hostView;
    I2IBarPlotIE *graph;
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
-(void)readFormulae;
-(void)readFormattingInfo;

-(UIView *)renderWidgetContainer:(CGRect)frameRect;
-(UILabel *)createLableWithFrame:(CGRect)frmLabel
                            text:(NSString *)txtLabel
                       textColor:(UIColor *)clrLabel
                            font:(UIFont *)fLabel
                           align:(NSTextAlignment)txtAlignment;

@end
#endif
