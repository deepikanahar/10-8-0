//
//  I2IScenarioControl.m
//  c100Benchmarking
//
//  Created by Neha Salankar on 24/03/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2IScenarioControl.h"
#import "FormulaEvaluator.h"

@implementation I2IScenarioControl

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander withProps:(NSString*)_props {
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    
    if(self){
        controls = [[NSMutableArray alloc]init];
        labels = [[NSMutableArray alloc]init];
        eval = [[FormulaEvaluator alloc]init];
        activeInputBox = [[UITextField alloc]init];
        isValidInput = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}
//  This method is used to clear all the widget’s views in order to save memory. It is called the first time the widget is loaded, and later if the widget needs to be recreated or deleted.
-(void)cleanViews {
    for (UIView *view in self.subviews){
        if([view isKindOfClass:[UIView class]]){
            UIView *v = (UIView *)view;
            [v removeFromSuperview];
        }
    }
}
//  This method is called every time the widget is recreated, which could be during initialization, when a layout or panel changes, or when the widget’s source selector is changed.
-(void)recreateWidget {
    [self reInitDataModels];
    for (I2IControls *i2iControl in controls) {
        [self addSubview:[self renderControl:i2iControl]];
    }
    int i = 0;
    for (I2IDynamicLabel *i2iLabel in labels) {
        
        NSArray *arrPosition = [[NSArray alloc] initWithArray:[i2iLabel.position componentsSeparatedByString:@","]];
        CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
        
        // -999<i> is tag for Dynamic label.
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d",@"-999",i] integerValue];
        
        [self addSubview:[i2iLabel initializeLabel:frameRect withTag:intTag]];
        
        i++;
    }
    // Evaluates the formulae and updates the value of dynamic labels.
    [self updateLabels];
    
    // Creates an instance of the Input Bar
    accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
    accessoryView.backgroundColor = [UIColor colorWithRed:0.576 green:0.584 blue:0.592 alpha:0.5];
    // Code for accessory Textbar.
    accessoryTf = [[UITextField alloc] initWithFrame:CGRectMake(0, 738, 1024, 30)];
    accessoryTf.backgroundColor = inputBarFill;
    accessoryTf.textColor = inputBarColor;
    accessoryTf.keyboardType = UIKeyboardTypeDecimalPad;
    accessoryTf.delegate = self;
    accessoryTf.tag = -1010;
    [accessoryView addSubview:accessoryTf];
}
//  Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    //  Update the widget's data.
    [self.widgetHelper reInitDataModels];
    [self readData];
}
#pragma mark Data Retrieval Method
-(void)readData {
    
    // Keep a reference to the grid's data.
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    
    // Always expect first metric header to be the unique identifier for the panel / control grid.
    NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:0];
    MSIHeaderValue *attributeCell = [row objectAtIndex:0];
    panelKey = [[NSString alloc]initWithFormat:@"%@",attributeCell.headerValue];
    
    metrics = [[NSMutableDictionary alloc]init];
    
    // Always expect second metric to be the number of controls.
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:1];
    intControls = [metricValue.rawValue intValue];
    
    int rowID = 0;
    if (intControls > 0) {
        for (int i = 0; i < intControls; i++) {
            // To get control details from grid.
            rowID = 2 + (8 * i);
            
            I2IControls *objControls = [[I2IControls alloc]init];
            
            // This variable stores the unique ID of the control.
            objControls.uid = [[metricHeader.elements objectAtIndex:rowID] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID];
            MSIMetricValue *metricProperties = [row objectAtIndex:1];
            MSIPropertyGroup *propertyGroup = metricProperties.format;
            
            // These variables store font face and font size for the control labels.
            objControls.fFace = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingName];
            objControls.fSize = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
            
            objControls.colors = [[NSMutableArray alloc] init];
            
            // Primary color for the control and its label.
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            // Used to identify the type of control.
            // 1 = Slider, 2 = Textbox, 3 = Toggle/Switch, 4 = Radio Button.
            objControls.type = [[[metricHeader.elements objectAtIndex:rowID+1] rawValue] intValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+1];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            
            // Secondary color for the control and its label.
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            // Default value of the control.
            objControls.defaultCV = [[metricHeader.elements objectAtIndex:rowID+2] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+2];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            
            // Number format and category for the control values and its label.
            objControls.category = [propertyGroup propertyByPropertySetID:FormattingNumber propertyID:NumberFormattingCategory];
            objControls.format = [propertyGroup propertyByPropertySetID:FormattingNumber propertyID:NumberFormattingFormat];
            
            // Tertiary color for the control and its label.
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            // Minimum value that the control can have.
            objControls.min = [[metricHeader.elements objectAtIndex:rowID+3] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+3];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            
            // Additional color for the control and its label.
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            // Maximum value that the control can have.
            objControls.max = [[metricHeader.elements objectAtIndex:rowID+4] rawValue];
            
            // Lowest value by which the control can incerement/decrement it's value. Only applicable to sliders.
            objControls.step = [[metricHeader.elements objectAtIndex:rowID+5] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+5];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            
            // Horizontal aligment for the control's label.
            objControls.align = [propertyGroup propertyByPropertySetID:FormattingAlignment propertyID:AlignmentFormattingHorizontal];
            
            // Suffix for the control's label.
            objControls.suffix = [[metricHeader.elements objectAtIndex:rowID+6] rawValue];
            
            // Position of the control on the screen.
            // Format is "x,y,width,height". It is relative to the grid position in the document.
            objControls.position = [[metricHeader.elements objectAtIndex:rowID+7] rawValue];
            [self setDefaultValues:objControls];
            [controls addObject:objControls];
        }
    }
    
    rowID = 2 + (8 * intControls);
    
    // Always expect this metric to be the number of dynamic labels.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    intLabels = [metricValue.rawValue intValue];
    
    if (intLabels > 0) {
        for (int i = 0; i < intLabels; i++) {
            // To get dynamic label details from grid.
            rowID = 3 + (8 * intControls) + (2 * i);
            
            I2IDynamicLabel *objLabel = [[I2IDynamicLabel alloc]init];
            
            // Gets the header value of the dynamic label.
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID];
            attributeCell = [row objectAtIndex:0];
            objLabel.key = [[NSString alloc]initWithFormat:@"%@",attributeCell.headerValue];
            
            // Gets the formula used to dynamically evaluate the value of dynamic label.
            objLabel.formula = [[metricHeader.elements objectAtIndex:rowID] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID];
            MSIMetricValue *metricProperties = [row objectAtIndex:1];
            MSIPropertyGroup *propertyGroup = metricProperties.format;
            
            // Font parameters for the dynamic label.
            objLabel.fFace = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingName];
            
            objLabel.fBold = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingBold];
            objLabel.fItalic = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingItalic];
            objLabel.fUnderline = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingUnderline];
            
            objLabel.fSize = [[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize] intValue];
            objLabel.fColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]];
            
            // Horizontal alignment parameters for the dynamic label.
            objLabel.align = [propertyGroup propertyByPropertySetID:FormattingAlignment propertyID:AlignmentFormattingHorizontal];
            objLabel.wrap = [propertyGroup propertyByPropertySetID:FormattingAlignment propertyID:AlignmentFormattingTextWrap];
            
            // Number formatting parameters for the dynamic label.
            objLabel.category = [propertyGroup propertyByPropertySetID:FormattingNumber propertyID:NumberFormattingCategory];
            objLabel.format = [propertyGroup propertyByPropertySetID:FormattingNumber propertyID:NumberFormattingFormat];
            objLabel.format = [objLabel.format stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
            // Padding parameters for the dynamic label.
            objLabel.leftPad = [propertyGroup propertyByPropertySetID:FormattingPadding propertyID:PaddingFormattingLeftPadding];
            objLabel.rightPad = [propertyGroup propertyByPropertySetID:FormattingPadding propertyID:PaddingFormattingRightPadding];
            objLabel.topPad = [propertyGroup propertyByPropertySetID:FormattingPadding propertyID:PaddingFormattingTopPadding];
            objLabel.bottomPad = [propertyGroup propertyByPropertySetID:FormattingPadding propertyID:PaddingFormattingBottomPadding];
            
            // Position of the dynamic label on the screen.
            // Format is "x,y,width,height". It is relative to the grid position in the document.
            objLabel.position = [[metricHeader.elements objectAtIndex:rowID+1] rawValue];
            [labels addObject:objLabel];
        }
    }
    
    // Sets the index to the row containing the first supporting/base metric.
    if (intControls > 0) {
        rowID = 3 + (8 * intControls) + (2 * intLabels);
    }
    
    for (NSString *strKey in [[PlistData getValue] allKeys]) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:[NSString stringWithFormat:@"%@",[[PlistData getValue] valueForKey:strKey]]];
        if (number!=nil) {
            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",[[PlistData getValue] valueForKey:strKey]]] forKey:strKey];
        }
        else{
            [metrics setValue:[NSString stringWithFormat:@"%@",[[PlistData getValue] valueForKey:strKey]] forKey:strKey];
            
        }
    }
    
#pragma mark Supporting Metrics
    // Loop through all the supporting metrics and add to the key-value pair to metrics dictionary.
    for(int i = rowID; i < current.count; i++){
        row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i];//Number of columns in grid
        
        attributeCell = [row objectAtIndex:0];
        NSString *attributeValue = attributeCell.headerValue;
        metricValue = [row objectAtIndex:1];
        NSString *strMetricValue = metricValue.rawValue;
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *number = [f numberFromString:strMetricValue];
        NSDecimalNumber *fMetricAvg = [NSDecimalNumber decimalNumberWithString:@"0"];
        
        if (row.count > 2) {
            for (int j = 1; j < row.count; j++) {
                MSIMetricValue *metricVal = [row objectAtIndex:j];
                fMetricAvg = [fMetricAvg decimalNumberByAdding:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",metricVal.rawValue]]];
            }
            
            fMetricAvg = [fMetricAvg decimalNumberByDividingBy:[[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lu",(unsigned long)row.count]] decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithString:@"1"]]];
            
            if (number != nil) {
                [metrics setValue:fMetricAvg forKey:attributeValue];
            }
            else {
                [metrics setValue:metricValue.rawValue forKey:attributeValue];
            }
            
        }
        else{
            if (number != nil) {
                [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",[metricValue rawValue]]] forKey:attributeValue];
            }
            else {
                [metrics setValue:[metricValue rawValue] forKey:attributeValue];
            }        }
        
    }
}

#pragma mark handleEvent Methods
//  When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    [self cleanViews];
    [controls removeAllObjects];
    [labels removeAllObjects];
    [metrics removeAllObjects];
    [self recreateWidget];
}

#pragma mark Converts BGR value to UIColor object
-(UIColor *)colorConvertor:(NSString *)strColor {
    //  We got B G R here, but we need RGB
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF)/255.0f green:((bgrValue & 0xFF00)>>8)/255.0f blue:((bgrValue & 0xFF0000) >> 16)/255.0f alpha:1.0f];
}

#pragma mark Implementation of Control objects
-(UIView *)renderControl:(I2IControls*)i2iControl{
    
    // Renders the container for the control.
    NSArray *arrPosition = [[NSArray alloc] initWithArray:[i2iControl.position componentsSeparatedByString:@","]];
    CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
    UIView *uivContainer = [[UIView alloc]initWithFrame:frameRect];
    
    switch (i2iControl.type) {
        case 1:
            //  Code for Slider.
            uivContainer = [self createSlider:frameRect withParams:i2iControl];
            break;
        case 2:
            //  Code for Textbox.
            uivContainer = [self createTextBox:frameRect withParams:i2iControl];
            break;
        case 3:
            //  Code for Toggle.
            uivContainer = [self createToggle:frameRect withParams:i2iControl];
            break;
        case 4:
            //  Code for Radio Button.
            uivContainer = [self createRadioButton:frameRect withParams:i2iControl];
            break;
        case 5:
            //  Code for Reset Button.
            if ([i2iControl.defaultCV isEqualToString:@"1"]) {
                uivContainer = [self createResetButton:frameRect withParams:i2iControl];
            }
            break;
        case 6:
            //  Code for Emit Button.
            uivContainer = [self createEmitButton:frameRect withParams:i2iControl];
            break;
        default:
            break;
    }
    return uivContainer;
}
-(UIView *)createSlider:(CGRect)frameRect withParams:(I2IControls*)i2iControl{
    
    UIView *uivSlider = [[UIView alloc] initWithFrame:frameRect];
    
    CGRect frameLabel = CGRectMake(0, 0, frameRect.size.width, 20);
    UILabel *lblValue = [[UILabel alloc] initWithFrame:frameLabel];
    
    // Tags the label object for reference and updating the value in event handlers.
    lblValue.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Slider" withString:@"909"] integerValue];
    lblValue.font = [UIFont fontWithName:i2iControl.fFace size:[i2iControl.fSize intValue]];
    
    lblValue.text = [self setNumberFormat:[[PlistData getValue] valueForKey:i2iControl.uid] withFormatCategory:i2iControl.category withFormat:i2iControl.format];
    
    if ([i2iControl.suffix isEqualToString:@"Days"]) {
        if ([lblValue.text isEqualToString:@"1"]) {
            lblValue.text = [NSString stringWithFormat:@"%@ Day",lblValue.text];
        }
        else {
            lblValue.text = [NSString stringWithFormat:@"%@ %@",lblValue.text,i2iControl.suffix];
        }
    }
    
    // Horizontal alignment for the control's label.
    switch ([i2iControl.align intValue]) {
        case 4:
            lblValue.textAlignment = NSTextAlignmentRight;
            break;
        case 3:
            lblValue.textAlignment = NSTextAlignmentCenter;
            break;
        default:
            lblValue.textAlignment = NSTextAlignmentLeft;
            break;
    }
    
    // This color is set on the minimum value para-metric
    lblValue.textColor = [i2iControl.colors objectAtIndex:3];
    lblValue.numberOfLines = 0;
    lblValue.lineBreakMode = NSLineBreakByWordWrapping;
    [uivSlider addSubview:lblValue];
    
    UIButton *btnMinus = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frameMinusButton = CGRectMake(0, frameRect.size.height-35, 25, 25);
    btnMinus.frame = frameMinusButton;
    [btnMinus setTitle:@"" forState:UIControlStateNormal];
    btnMinus.titleLabel.font = [UIFont fontWithName:i2iControl.fFace size:[i2iControl.fSize intValue]];
    btnMinus.backgroundColor = [UIColor clearColor];
    
    [btnMinus addTarget:self action:@selector(handleMinus:) forControlEvents:UIControlEventTouchUpInside];
    [btnMinus setBackgroundImage:[UIImage imageNamed:@"minus.png"] forState:UIControlStateNormal];
    [uivSlider addSubview:btnMinus];
    
    CGRect frameSlider = CGRectMake(35, frameRect.size.height-35, frameRect.size.width-70, 25);
    
    UISlider *i2iSlider = [[UISlider alloc] init];
    i2iSlider.frame = frameSlider;
    i2iSlider.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Slider" withString:@"999"] integerValue];
    i2iSlider.minimumValue = [i2iControl.min floatValue];
    i2iSlider.maximumValue = [i2iControl.max floatValue];
    
    i2iSlider.value = [lblValue.text floatValue];
    
    i2iSlider.continuous = YES;
    i2iSlider.minimumTrackTintColor = [i2iControl.colors objectAtIndex:0];
    i2iSlider.maximumTrackTintColor = [i2iControl.colors objectAtIndex:2];
    
    [i2iSlider addTarget:self action:@selector(handleSliderChange:) forControlEvents:UIControlEventValueChanged];
    [uivSlider addSubview:i2iSlider];
    
    CGRect framePlusButton = CGRectMake(frameRect.size.width-25, frameRect.size.height-35, 25, 25);
    UIButton *btnPlus = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPlus.frame = framePlusButton;
    [btnPlus setTitle:@"" forState:UIControlStateNormal];
    btnPlus.titleLabel.font = [UIFont fontWithName:i2iControl.fFace size:[i2iControl.fSize intValue]];
    btnPlus.backgroundColor = [UIColor clearColor] ;
    
    [btnPlus addTarget:self action:@selector(handlePlus:) forControlEvents:UIControlEventTouchUpInside];
    [btnPlus setBackgroundImage:[UIImage imageNamed:@"plus.png"] forState:UIControlStateNormal];
    [uivSlider addSubview:btnPlus];
    
    return uivSlider;
}
-(UITextField *)createTextBox:(CGRect)frameRect withParams:(I2IControls*)i2iControl{
    
    UITextField *uitfInput = [[UITextField alloc] initWithFrame:frameRect];
    uitfInput.delegate = self;
    uitfInput.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Input" withString:@"919"] integerValue];
    uitfInput.font = [UIFont fontWithName:i2iControl.fFace size:[i2iControl.fSize intValue]];
    uitfInput.textColor = [i2iControl.colors objectAtIndex:0];
    inputBarFill = [i2iControl.colors objectAtIndex:0];
    inputBarColor = [i2iControl.colors objectAtIndex:1];
    
    uitfInput.layer.cornerRadius=0.0f;
    uitfInput.layer.masksToBounds=YES;
    uitfInput.layer.borderColor=[[i2iControl.colors objectAtIndex:1]CGColor];
    uitfInput.layer.borderWidth= 1.0f;
    uitfInput.borderStyle = UITextBorderStyleBezel;
    uitfInput.keyboardType = UIKeyboardTypeDecimalPad;
    uitfInput.text = [self setNumberFormat:i2iControl.defaultCV withFormatCategory:i2iControl.category withFormat:i2iControl.format];
    // Horizontal alignment for the control's label.
    switch ([i2iControl.align intValue]) {
        case 4:
            uitfInput.textAlignment = NSTextAlignmentRight;
            break;
        case 3:
            uitfInput.textAlignment = NSTextAlignmentCenter;
            break;
        default:
            uitfInput.textAlignment = NSTextAlignmentLeft;
            break;
    }
    uitfInput.userInteractionEnabled=YES;
    return uitfInput;
}
-(UIView *)createToggle:(CGRect)frameRect withParams:(I2IControls*)i2iControl{
    
    UIView *uivToggle = [[UIView alloc] initWithFrame:frameRect];
    UISwitch *uisToggle = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)];
    uisToggle.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Toggle" withString:@"111"] integerValue];
    uisToggle.onTintColor = [i2iControl.colors objectAtIndex:0];
    uisToggle.thumbTintColor = [i2iControl.colors objectAtIndex:1];
    uisToggle.tintColor = [i2iControl.colors objectAtIndex:2];
    uivToggle.userInteractionEnabled = YES;
    if ([i2iControl.defaultCV isEqualToString:@"0"]) {
        [uisToggle setOn:NO];
    }
    else
    {
        [uisToggle setOn:YES];
    }
    
    [uisToggle addTarget:self action:@selector(handleToggle:) forControlEvents:UIControlEventValueChanged];
    [uivToggle addSubview:uisToggle];
    
    return uivToggle;
}
-(UIView *)createRadioButton:(CGRect)frameRect withParams:(I2IControls*)i2iControl{
    UIView *uivRadioBtn = [[UIView alloc] initWithFrame:frameRect];
    UIButton *radioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    radioBtn.frame = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
    radioBtn.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Radio" withString:@"222"] intValue];
    [radioBtn addTarget:self action:@selector(handleRadioButton:) forControlEvents:UIControlEventTouchUpInside];
    radioBtn.userInteractionEnabled = YES;
    
    NSString *currentRadio = [[PlistData getValue] valueForKey:[NSString stringWithFormat:@"Radio%@",panelKey]];
    
    if([currentRadio isEqualToString:[@(radioBtn.tag) stringValue]]){
        [radioBtn setBackgroundImage:[UIImage imageNamed:@"RadioChecked.png"] forState:UIControlStateNormal];
        [metrics setValue:[i2iControl.uid stringByReplacingOccurrencesOfString:@"Radio" withString:@"222"] forKey:[NSString stringWithFormat:@"Radio%@",panelKey]];
    }
    else {
        [radioBtn setBackgroundImage:[UIImage imageNamed:@"RadioUncheck.png"] forState:UIControlStateNormal];
    }
    [uivRadioBtn addSubview:radioBtn];
    return uivRadioBtn;
}
-(UIView *)createResetButton:(CGRect)frameRect withParams:(I2IControls*)i2iControl{
    UIView *uivResetButton = [[UIView alloc] initWithFrame:frameRect];
    UIButton *btnReset = [UIButton buttonWithType:UIButtonTypeCustom];
    btnReset.frame = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
    btnReset.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Reset" withString:@"939"] intValue];
    [btnReset addTarget:self action:@selector(handleResetButton:) forControlEvents:UIControlEventTouchUpInside];
    btnReset.userInteractionEnabled = YES;
    [btnReset setBackgroundImage:[UIImage imageNamed:@"refresh.png"] forState:UIControlStateNormal];
    [uivResetButton addSubview:btnReset];
    return uivResetButton;
}
-(UIView *)createEmitButton:(CGRect)frameRect withParams:(I2IControls*)i2iControl{
    UIView *uivEmitButton = [[UIView alloc] initWithFrame:frameRect];
    UIButton *btnEmit = [UIButton buttonWithType:UIButtonTypeCustom];
    btnEmit.frame = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
    btnEmit.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Emit" withString:@"949"] intValue];
    [btnEmit addTarget:self action:@selector(handleEmitButton:) forControlEvents:UIControlEventTouchUpInside];
    btnEmit.userInteractionEnabled = YES;
    [btnEmit setBackgroundImage:[UIImage imageNamed:@"emit.png"] forState:UIControlStateNormal];
    [uivEmitButton addSubview:btnEmit];
    return uivEmitButton;
}

#pragma mark Event Handlers for Controls
//  Calls when slider value changes
-(void)handleSliderChange:(id)sender {
    [activeInputBox resignFirstResponder];
    UISlider *slider = (UISlider *)sender;
    NSString *strSliderVal;
    
    for(I2IControls *i2iControl in controls){
        if ([i2iControl.uid isEqualToString:[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999" withString:@"Slider"]]) {
            UILabel *lblTarget = (UILabel *)[self viewWithTag:[[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999" withString:@"909"] integerValue]];
            // 909 is tag for Slider Label
            if ([i2iControl.suffix isEqualToString:@"%"]) {
                if ([i2iControl.step isEqualToString:@"1"]) {
                    slider.value = (int)slider.value;
                    strSliderVal = [NSString stringWithFormat:@"%.2f",slider.value / 100];
                }
                else {
                    if (roundf(slider.value / [i2iControl.step floatValue]) * [i2iControl.step floatValue] == 0) {
                        strSliderVal = @"0";
                    }
                    else {
                        strSliderVal = [NSString stringWithFormat:@"%.3f",slider.value / 100];
                    }
                }
            }
            else {
                if ([i2iControl.step isEqualToString:@"1"]) {
                    strSliderVal = [NSString stringWithFormat:@"%d", (int)slider.value];
                }
                else {
                    if (roundf(slider.value / [i2iControl.step floatValue]) * [i2iControl.step floatValue] == 0) {
                        strSliderVal = @"0";
                    }
                    else {
                        strSliderVal = [NSString stringWithFormat:@"%.1f", slider.value];
                    }
                }
            }
            
            lblTarget.text = [self setNumberFormat:strSliderVal withFormatCategory:i2iControl.category withFormat:i2iControl.format];
            
            if ([i2iControl.suffix isEqualToString:@"Days"]) {
                if ([lblTarget.text isEqualToString:@"1"] || [lblTarget.text isEqualToString:@"-1"]) {
                    lblTarget.text = [NSString stringWithFormat:@"%@ Day",lblTarget.text];
                }
                else {
                    lblTarget.text = [NSString stringWithFormat:@"%@ %@",lblTarget.text,i2iControl.suffix];
                }
            }
            
            [PlistData setValue:strSliderVal keyForSlider:i2iControl.uid];
            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",strSliderVal]] forKey:i2iControl.uid];
            break;
        }
    }
    [self updateLabels];
}
//  Calls when minus button is pressed
-(void)handleMinus:(id)sender {
    UISlider *slider;
    for (UIView *view in [[sender superview] subviews]) {
        if ([view isKindOfClass:[UISlider class]])
        {
            slider = (UISlider *)view;
            break;
        }
    }
    for(I2IControls *i2iControl in controls){
        if ([i2iControl.uid isEqualToString:[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999" withString:@"Slider"]]) {
            slider.value -= [i2iControl.step floatValue];
            break;
        }
    }
    [self handleSliderChange:slider];
}
//  Calls when plus button is pressed
-(void)handlePlus:(id)sender {
    UISlider *slider;
    for (UIView *view in [[sender superview] subviews]) {
        if ([view isKindOfClass:[UISlider class]])
        {
            slider = (UISlider *)view;
            break;
        }
    }
    for(I2IControls *i2iControl in controls){
        if ([i2iControl.uid isEqualToString:[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999" withString:@"Slider"]]) {
            slider.value += [i2iControl.step floatValue];
            break;
        }
    }
    [self handleSliderChange:slider];
}
-(void)handleToggle:(id)sender {
    UISwitch *uisToggle;
    for (UIView *view in [[sender superview] subviews]) {
        if ([view isKindOfClass:[UISwitch class]])
        {
            uisToggle = (UISwitch *)view;
            break;
        }
    }
    for(I2IControls *i2iControl in controls){
        if ([i2iControl.uid isEqualToString:[[@(uisToggle.tag) stringValue] stringByReplacingOccurrencesOfString:@"111" withString:@"Toggle"]]) {
            if (uisToggle.on) {
                [PlistData setValue:@"1" keyForSlider:i2iControl.uid];
                [metrics setValue:[NSNumber numberWithInt:1]  forKey:i2iControl.uid];
            }
            else {
                [PlistData setValue:@"0" keyForSlider:i2iControl.uid];
                [metrics setValue:[NSNumber numberWithInt:0]  forKey:i2iControl.uid];
            }
            break;
        }
    }
    [self updateLabels];
}
-(void)handleRadioButton:(id)sender {
    UIButton *radioBtn = (UIButton *)sender;
    for(I2IControls *i2iControl in controls) {
        if ([i2iControl.uid isEqualToString:[[@(radioBtn.tag) stringValue] stringByReplacingOccurrencesOfString:@"222" withString:@"Radio"]]) {
            [radioBtn setBackgroundImage:[UIImage imageNamed:@"RadioChecked.png"] forState:UIControlStateNormal];
            [metrics setValue:[i2iControl.uid stringByReplacingOccurrencesOfString:@"Radio" withString:@"222"] forKey:[NSString stringWithFormat:@"Radio%@",panelKey]];
            [PlistData setValue:[i2iControl.uid stringByReplacingOccurrencesOfString:@"Radio" withString:@"222"] keyForSlider:[NSString stringWithFormat:@"Radio%@",panelKey]];
        }
        else {
            if (i2iControl.type == 4) {
                UIButton *radioUnchecked = (UIButton *)[self viewWithTag:[[i2iControl.uid stringByReplacingOccurrencesOfString:@"Radio" withString:@"222"] integerValue]];
                [radioUnchecked setBackgroundImage:[UIImage imageNamed:@"RadioUncheck.png"] forState:UIControlStateNormal];
            }
        }
    }
    [self updateLabels];
}
-(void)handleResetButton:(id)sender {
    [PlistData removeKey:panelKey];
    for (I2IControls *i2iControl in controls) {
        [PlistData removeKey:i2iControl.uid];
    }
    [self handleEvent:@"nil"];
}
-(void)handleEmitButton:(id)sender {
    UIButton *btnEmit = (UIButton *)sender;
    for(I2IControls *i2iControl in controls){
        if ([i2iControl.uid isEqualToString:[[@(btnEmit.tag) stringValue] stringByReplacingOccurrencesOfString:@"949" withString:@"Emit"]]) {
            NSArray *arrComponents = [[NSArray alloc] initWithArray:[i2iControl.step componentsSeparatedByString:@";"]];
            for (NSString *str in arrComponents) {
                NSArray *arrMapping = [[NSArray alloc] initWithArray:[str componentsSeparatedByString:@","]];
                NSString *strSource = [arrMapping firstObject];
                NSString *strDestination = [arrMapping lastObject];
                NSString *strSourceValue =[[PlistData getValue] objectForKey:strSource];
                [PlistData setValue:strSourceValue keyForSlider:strDestination];
            }
        }
    }
}

#pragma mark UITextField Delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField.tag!=-1010) {
        accessoryTf.tag = textField.tag;
        accessoryTf.text = textField.text;
    }
    if (isValidInput == YES) {
        textField.inputAccessoryView = accessoryView;
        [accessoryTf becomeFirstResponder];
    }
}
-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (isValidInput == YES) {
        activeInputBox = textField;
        accessoryTf.text = textField.text;
    }
    else{
        [accessoryTf selectAll:nil];
    }
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    for(I2IControls *i2iControl in controls){
        if ([i2iControl.uid isEqualToString:[[@(accessoryTf.tag) stringValue] stringByReplacingOccurrencesOfString:@"919" withString:@"Input"]]) {
            // 919 is tag for Input values
            if ([self validateTextField:accessoryTf.text]==YES) {
                
                NSMutableString *mutableStr = [[NSMutableString alloc] initWithString:accessoryTf.text];
                double fUpdatedString = 0.0;
                fUpdatedString = [[mutableStr stringByReplacingOccurrencesOfString:@"," withString:@""] doubleValue];
                
                if ([i2iControl.suffix isEqualToString:@"%"]) {
                    fUpdatedString = [accessoryTf.text doubleValue]/100;
                }
                
                if (fUpdatedString >= [i2iControl.min doubleValue] && fUpdatedString <= [i2iControl.max doubleValue]) {
                    [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f",fUpdatedString]] forKey:i2iControl.uid];
                    [PlistData setValue:[NSString stringWithFormat:@"%lf",fUpdatedString] keyForSlider:i2iControl.uid];
                    if ([activeInputBox.text isEqualToString:@""]) {
                        accessoryTf.text = activeInputBox.text;
                    }
                    activeInputBox.text = [[self setNumberFormat:[NSString stringWithFormat:@"%lf",fUpdatedString] withFormatCategory:i2iControl.category withFormat:i2iControl.format] mutableCopy];
                    accessoryTf.text = activeInputBox.text;
                    
                    isValidInput = YES;
                    [accessoryTf selectAll:nil];
                    [accessoryTf resignFirstResponder];
                    [activeInputBox resignFirstResponder];
                    
                }
                else {
                    NSString *percentStr = @"%";
                    if ([i2iControl.suffix isEqualToString:@"%"]) {
                        // Message to validate textbox
                        [self showAlertWithMessage:[NSString stringWithFormat:@"Please enter value within %d%@ to %d%@",[i2iControl.min intValue]*100,percentStr,[i2iControl.max intValue]*100,percentStr]];
                    }
                    else{
                        // Message to validate textbox
                        [self showAlertWithMessage:[NSString stringWithFormat:@"Please enter value within %@ to %@",i2iControl.min,i2iControl.max]];
                    }
                    double fDefaultValue = [[[PlistData getValue] valueForKey:i2iControl.uid] doubleValue];
                    accessoryTf.text=[self setNumberFormat:[NSString stringWithFormat:@"%lf",fDefaultValue] withFormatCategory:i2iControl.category withFormat:i2iControl.format];
                    isValidInput = NO;
                    [accessoryTf resignFirstResponder];
                    [activeInputBox resignFirstResponder];
                }
                
            }
            else{
                [self showAlertWithMessage:[NSString stringWithFormat:@"Please enter valid input"]];
                double fDefaultValue = [[[PlistData getValue] valueForKey:i2iControl.uid] doubleValue];
                accessoryTf.text=[self setNumberFormat:[NSString stringWithFormat:@"%lf",fDefaultValue] withFormatCategory:i2iControl.category withFormat:i2iControl.format];
                isValidInput = NO;
                [accessoryTf resignFirstResponder];
                [activeInputBox resignFirstResponder];
            }
        }
    }
    [self updateLabels];
    return YES;
}
-(BOOL)validateTextField: (NSString *)alpha {
    NSString *abnRegex = @"[0-9%,.-]+";
    NSPredicate *abnTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", abnRegex];
    BOOL isValid = [abnTest evaluateWithObject:alpha];
    return isValid;
}
-(NSString *)removeUnwantedString:(NSString *)inputStr {
    NSString *outputStr = [inputStr stringByReplacingOccurrencesOfString:@"(" withString:@""];
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@")" withString:@""];
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@"%" withString:@""];
    return outputStr;
}
-(void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alert=   [UIAlertController alertControllerWithTitle:@"Warning" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:okButton];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark Sets and Gets Default Values
-(void)setDefaultValues:(I2IControls *)objControls {
    NSString *strTempControl = [NSString stringWithFormat:@"%@",[[PlistData getValue] valueForKey:objControls.uid]];
    
    if ([strTempControl isEqualToString:@"(null)"]) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:objControls.defaultCV];
        if (number == nil) {
            objControls.defaultCV = [[eval evaluateFormula:objControls.defaultCV withDictionary:[PlistData getValue]] stringValue];
        }
        if ([objControls.suffix isEqualToString:@"%"]) {
            if ([objControls.step isEqualToString:@"1"]) {
                objControls.defaultCV = [NSString stringWithFormat:@"%.2f",[objControls.defaultCV floatValue] / 100];
            }
            else {
                objControls.defaultCV = [NSString stringWithFormat:@"%.3f",[objControls.defaultCV floatValue] / 100];
            }
        }
        [PlistData setValue:objControls.defaultCV keyForSlider:[NSString stringWithFormat:@"%@",objControls.uid]];
    }
    else {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:objControls.defaultCV];
        if (number == nil) {
            objControls.defaultCV = [[eval evaluateFormula:objControls.defaultCV withDictionary:[PlistData getValue]] stringValue];
            [PlistData setValue:objControls.defaultCV keyForSlider:[NSString stringWithFormat:@"%@",objControls.uid]];
        }
        else {
            objControls.defaultCV = [[PlistData getValue] valueForKey:objControls.uid];
        }
    }
}

#pragma mark Updates Dynamic Labels
-(void)updateLabels {
    for (int i = 0; i < intLabels; i++) {
        
        I2IDynamicLabel *lblTemp = [labels objectAtIndex:i];
        NSString *strCalcValue;
        
        NSMutableString *str = [[NSMutableString alloc]initWithString:lblTemp.formula];
        if ([str hasPrefix:@"#"]) {
            if ([str containsString:@"fn"]) {
                [str deleteCharactersInRange:[str rangeOfString:@"#fn#"]];
                strCalcValue = [NSString stringWithFormat:@"%@",[eval evaluateFormula:str withDictionary:metrics]];
            }
            else{
                [str deleteCharactersInRange:[str rangeOfString:@"#"]];
                strCalcValue = [NSString stringWithFormat:@"%@",[eval evaluateFormula:str withDictionary:metrics]];
            }
            if ([lblTemp.key hasPrefix:@"suffixText"]) {
                [PlistData setValue:[metrics objectForKey:str] keyForSlider:lblTemp.key];
                [metrics setValue:[metrics objectForKey:str] forKey:lblTemp.key];
            }
            else {
                [PlistData setValue:[NSString stringWithFormat:@"%@",strCalcValue] keyForSlider:lblTemp.key];
                [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",strCalcValue]] forKey:lblTemp.key];
            }
        }
        else {
            strCalcValue = [NSString stringWithFormat:@"%@",[eval evaluateFormula:lblTemp.formula withDictionary:metrics]];
        }
        
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d",@"-999",i] integerValue];
        //-999 is tag for Dynamic label
        UILabel *lblTarget = (UILabel *)[self viewWithTag:intTag];
        if ([lblTemp.key containsString:@"suffixText"]) {
            [lblTarget setText:strCalcValue];
        }
        else {
            [lblTarget setText:[self setNumberFormat:strCalcValue withFormatCategory:lblTemp.category withFormat:lblTemp.format]];
        }
    }
}

#pragma mark Sets Number Formatting
-(NSString*)setNumberFormat:(NSString*)strValue withFormatCategory:(NSString*)strCategory withFormat:(NSString*)strFormat {
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    switch ([strCategory intValue]) {
        case 0: // Represents Decimal Formatting
            numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            numFormatter.positiveFormat = strFormat;
            break;
            
        case 1: // Represents Currency Formatting
            numFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
            numFormatter.positiveFormat = strFormat;
            break;
            
        case 4: // Represents Percentage Formatting
            numFormatter.numberStyle = NSNumberFormatterPercentStyle;
            numFormatter.positiveFormat = strFormat;
            break;
            
        default:
            break;
    }
    
    NSString *outputStr = [numFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",strValue]]];
    return outputStr;
}

#pragma mark Keyboard Notification
//  Called when the UIKeyboardDidShowNotification is sent.
-(void)keyboardWasShown:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];
    CGRect endRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (endRect.size.height == 984) {
        accessoryView.frame = CGRectMake(0, -216, 1024, 768);
    }
    else {
        accessoryView.frame = CGRectMake(0, 0, 1024, 768);
    }
    
    [accessoryTf selectAll:nil];
}
//  Called when the UIKeyboardWillHideNotification is sent
-(void)keyboardWillBeHidden:(NSNotification*)aNotification {
}
@end
