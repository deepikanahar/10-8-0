//
//  I2IVGController.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 05/08/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IVGController_h
#define I2IVGController_h

#import <Foundation/Foundation.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIPropertyGroup.h>
#import <MicroStrategyMobileSDK/MSIHeaderValue.h>
#import <MicroStrategyMobileSDK/MetricHeader.h>
#import <MicroStrategyMobileSDK/MetricValue.h>
#import "FormulaEvaluator.h"
#import "PlistData.h"
#import "I2IColumnPlotV.h"
#import "I2IControls.h"
#import "I2IDynamicLabel.h"

@interface I2IVGController : MSIWidgetViewer<UITextFieldDelegate>{
    FormulaEvaluator *eval;
    
    // Constants for the graph to be created.
    int intControls;
    int intLabels;   // Number of Dynamic Labels
    
    int companyID;
    NSString *panelKey;
    
    NSMutableArray *controls;
    NSMutableArray *labels;
    
    // Data dictionary for supporting metrics
    NSMutableDictionary *metrics;
    
    // Hosting View for the waterfall chart
    UIView *hostView;
    I2IColumnPlotV *graph;
    
    UIColor *inputBarFill;
    UIColor *inputBarColor;
    
    // For Accessory View
    UIView *accessoryView;
    UITextField *accessoryTf;
    BOOL isValidInput;
    UITextField *activeInputBox;
    
    // Constants for the graph to be created.
    // Title of the graph
    NSString *title;
    // Size of font to be displayed on the graph title
    NSString *fsTitle;
    // Position for waterfall graph
    NSString *chartPosition;
}
@property (nonatomic, strong) MSIModelData *modelData;

-(void)readConstants;
-(void)readData;
-(void)updateLabels;
-(UIView *)renderControl:(I2IControls*)i2iControl;

@end
#endif
