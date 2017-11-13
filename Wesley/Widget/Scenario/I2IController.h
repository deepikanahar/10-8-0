//
//  I2IController.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 05/08/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

//  This class is the combination of Scenario controller and DynamicText class
#ifndef I2IController_h
#define I2IController_h
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

@interface I2IController : MSIWidgetViewer<UITextFieldDelegate>{
    // ID of the selected company
    int companyID;
    // Number of Controls like Sliders, textFields, toggles, and radio buttons on document
    int intControls;
    // Number of Dynamic Labels
    int intLabels;
    // To get start index of supporting metrics
    int intMetrics;
    // Number of Dynamic Texts
    int intTexts;
    
    NSMutableArray *controls;
    NSMutableArray *labels;
    
    FormulaEvaluator *eval;
    NSMutableDictionary *metrics;
    
    NSString *panelKey;
    
    // Input Text Bar
    UIView *accessoryView;
    UITextField *accessoryTf;
    BOOL isValidInput;
    UITextField *activeInputBox;

    UIColor *inputBarFill;
    UIColor *inputBarColor;
    
    // Dynamic Text Properties
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

-(void)updateLabels;
-(void)updateTexts;

@end
#endif
