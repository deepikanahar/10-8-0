//
//  I2IFxMove.h
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 30/03/17.
//  Modified by Pradeep Yadav on 10/04/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IFxMove_h
#define I2IFxMove_h
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

@interface I2IFxMove : MSIWidgetViewer<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    // Number of Controls like Sliders, textFields, toggles on table
    int intControls;
    // Number of Dynamic Labels on document
    int intLabels;
    // Number of Dynamic Labels on table
    int intInternalLabels;
    
    NSMutableArray *internalControls;
    NSMutableArray *internalLabels;
    NSMutableArray *labels;
    
    NSString *panelKey;
    
    FormulaEvaluator *eval;
    NSMutableDictionary *metrics;
    
    CGRect originalRect;
    UIColor *activeFxColor;
    UIColor *inactiveFxColor;
    
    //  For Accessory View
    UIView *accessoryView;
    UITextField *accessoryTf;
    int flagInverseRate;
    UITextField *activeInputBox;
    BOOL isValidInput;
    NSString *fontFace;
    int fontSize;
    NSString *keyFCY;
    UILabel *title;
    UILabel *rateLabel;
    UILabel *inverseRateLabel;
    UILabel *inverseRate;
    
    // For Table View
    UITableView *i2iTableView;
    NSString *i2iTableID;
    int intMaxRows;
    int intRowHeight;
    int resetFlag;
    
    I2IControls *resetControl;
    
}

@property (retain, nonatomic) MSIModelData *dataModel;

-(void)readData;
-(void)updateLabels;
-(void)updateInternalLabels;
-(UIView *)renderControl:(I2IControls *)i2iControl;

@end

#endif
