//
//  I2IWFExtended.h
//  c100CapitalStructure
//
//  Created by Pradeep Yadav on 9/11/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IWFExtended_h
#define I2IWFExtended_h

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
#import "I2IWaterFallPlot.h"
#import "I2IControls.h"
#import "I2IDynamicLabel.h"

@interface I2IWFExtended : MSIWidgetViewer<UITextFieldDelegate>{
    // Contants for the graph to be created.
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
    // Number of bars in the graph
    int intBars;

    FormulaEvaluator *eval;
    
    NSString *gID;
    // Position for waterfall graph
    NSString *chartPosition;
    
    NSMutableArray *controls;
    NSMutableArray *labels;
    
    //Data dictionary for supporting metrics
    NSMutableDictionary *metrics;
    
    //Hosting View for the waterfall chart
    UIView *hostView;
    I2IWaterFallPlot *wfGraph;
    
    NSString *panelKey;
    
    // For Accessory View - Input Text Bar
    UIView *accessoryView;
    UITextField *accessoryTf;
    UITextField *activeInputBox;
    BOOL isValidInput;

    UIColor *inputBarFill;
    UIColor *inputBarColor;
    
    // Dynamic Text Properties
    NSMutableAttributedString *strFullText;
    NSString *position;
    int intNoFormulae;
    NSMutableArray *arrFormulae;
    NSString *strFontFace;
    int intFontSize;
    UIColor *fontColor;
    NSString *strTextAlignment;
    NSMutableString *strImage;
}

@property (nonatomic, strong) MSIModelData *modelData;

-(void)updateLabels;
-(void)updateTexts;

@end
#endif
