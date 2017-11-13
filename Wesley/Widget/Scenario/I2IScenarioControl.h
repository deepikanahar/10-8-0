//
//  I2IScenarioControl.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 24/03/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IScenarioControl_h
#define I2IScenarioControl_h
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
#import "I2IControls.h"
#import "I2IDynamicLabel.h"

@interface I2IScenarioControl : MSIWidgetViewer<UITextFieldDelegate>{
    // Number of Controls like Sliders, textFields, toggles on document
    int intControls;
    // Number of Dynamic Labels
    int intLabels;
    
    NSMutableArray *controls;
    NSMutableArray *labels;
    
    NSString *panelKey;
    
    FormulaEvaluator *eval;
    NSMutableDictionary *metrics;
    
    CGRect originalRect;
    UIColor *inputBarFill;
    UIColor *inputBarColor;
    
    //  For Accessory View
    UIView *accessoryView;
    UITextField *accessoryTf;
    UITextField *activeInputBox;
    BOOL isValidInput;
}

@property (retain,nonatomic) MSIModelData *modelData;

-(void)readData;
-(void)updateLabels;
-(UIView *)renderControl:(I2IControls*)i2iControl;

@end
#endif
