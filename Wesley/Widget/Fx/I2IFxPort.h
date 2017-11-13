//
//  I2IFxPort.h
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 30/03/17.
//  Modified by Pradeep Yadav on 10/04/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IFxPort_h
#define I2IFxPort_h
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

@interface I2IFxPort : MSIWidgetViewer<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource> {
    
    // Number of Controls like Sliders, textFields, toggles on table
    int intControls;
    // Number of Dynamic Labels on document
    int intLabels;
    // Number of Dynamic Labels on table
    int intInternalLabels;
    // Number of variables to save
    int intVariablesToSave;
    int intFirstVariableIndex;
    
    NSMutableArray *internalControls;
    NSMutableArray *internalControlInstances;
    NSMutableArray *internalLabels;
    NSMutableArray *internalLabelInstances;
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
    
    // For Table View
    UITableView *i2iTableView;
    NSString *i2iTableID;
    UIView *itemPicker;
    NSArray *itemListDescriptions;
    NSArray *itemListCodes;
    NSInteger pickedItemIndex;
    int intMaxRows;
    int intMinRows;
    int intCurrentRows;
    int intRemoveButton;
    int spinnerFlag;
    int intRowHeight;
    
    UIButton *activePopButton;
    I2IControls *pickerViewControl;
    
}

@property (retain, nonatomic) MSIModelData *dataModel;

-(void)readData;
-(void)updateLabels;
-(void)updateInternalLabels;
-(UIView *)renderControl:(I2IControls *)i2iControl;

@end

#endif
