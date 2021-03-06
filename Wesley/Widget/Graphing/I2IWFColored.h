//
//  I2IWFColored.h
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 31/12/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IWFColored_h
#define I2IWFColored_h

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
#import "I2IWFColoredPlot.h"
#import "I2IControls.h"

@interface I2IWFColored : MSIWidgetViewer<UITextFieldDelegate>{
    // Contants for the graph to be created.
    // ID of the selected company
    int companyID;
    // Key for storing Company ID
    NSString *panelKey;
    // Number of bars in the graph
    int intBars;
    // Number of Controls like Sliders, textFields, toggles, and radio buttons on document
    int intControls;
    
    FormulaEvaluator *eval;
    
    NSString *gID;
    // Position for waterfall graph
    NSString *chartPosition;
    
    NSMutableArray *controls;
    
    // Data dictionary for supporting metrics
    NSMutableDictionary *metrics;
    // Hosting View for the waterfall chart
    UIView *hostView;
    I2IWFColoredPlot *wfGraph;
    // For Accessory View - Input Text Bar
    UIView *accessoryView;
    UITextField *accessoryTf;
    UITextField *activeInputBox;
    BOOL isValidInput;
    
    UIColor *inputBarFill;
    UIColor *inputBarColor;
}
@property (nonatomic, strong) MSIModelData *modelData;

-(void)readConstants;
-(void)readData;

@end
#endif
