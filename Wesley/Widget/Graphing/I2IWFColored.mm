//
//  I2IWFColored.mm
//  c100Benchmarking
//
//  Created by Pratik Rewanwar on 5/22/15.
//  Created by Neha Salankar on 06/05/16.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2IWFColored.h"

@implementation I2IWFColored

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander withProps:(NSString*)_props{
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    if(self){
        controls = [[NSMutableArray alloc] init];
        
        eval = [[FormulaEvaluator alloc]init];
        activeInputBox = [[UITextField alloc] init];
        
        wfGraph = [[I2IWFColoredPlot alloc] init];
        metrics = [[NSMutableDictionary alloc] init];
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
    //  CGrect offset to account for graph title and subtitles position
    NSArray *arrPosition = [[NSArray alloc] initWithArray:[chartPosition componentsSeparatedByString:@","]];
    CGRect graphFrame = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
    wfGraph.strStopsCounter = [[NSString alloc] initWithFormat:@"0"];
    
    //hostView = [[CPTGraphHostingView alloc] initWithFrame:graphFrame];
    hostView = [[UIView alloc] initWithFrame:graphFrame];
    //[wfGraph renderInLayerForYAxis:hostView identifier:gID];
    [wfGraph renderChart:hostView identifier:gID];
    
    [self addSubview:hostView];
    
    for (I2IControls *i2iControl in controls) {
        [self addSubview:[self renderControl:i2iControl]];
    }
    
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
    //  Update the widget's data
    [self.widgetHelper reInitDataModels];
    [self readConstants];
    [self readData];
}
#pragma mark Data Retrieval Methods
-(void)readConstants {
    //  Keep a reference to the grid's data
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    
    // Always expect first metric value to be the Company ID.
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    companyID = [metricValue.rawValue intValue];
    
    wfGraph.colors = [[NSMutableArray alloc] init];
    MSIPropertyGroup *propertyGroup = metricValue.format;
    // Primary Color for axis and labels
    [wfGraph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    
    // Always expect first metric header to be the unique identifier for the panel / control grid.
    NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:0];
    MSIHeaderValue *attributeCell = [row objectAtIndex:0];
    panelKey = [[NSString alloc] initWithFormat:@"%@",attributeCell.headerValue];
    
    // Always expect second metric to be the graph ID
    metricValue = [metricHeader.elements objectAtIndex:1];
    gID = metricValue.rawValue;
    
    propertyGroup = metricValue.format;
    wfGraph.fFace = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingName];
    wfGraph.fSize = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
    
    // Always expect third metric to be the number of bars
    metricValue = [metricHeader.elements objectAtIndex:2];
    intBars = [metricValue.rawValue intValue];
    
    // Always expect fourth metric to be the graph position
    metricValue = [metricHeader.elements objectAtIndex:3];
    chartPosition = metricValue.rawValue;
    
    // Always expect fifth metric to be the bars where the waterfall graph would restart
    wfGraph.arrStops = [[NSMutableArray alloc] init];
    metricValue = [metricHeader.elements objectAtIndex:4];
    if ([metricValue.rawValue containsString:@","]) {
        wfGraph.arrStops = [[NSMutableArray alloc] initWithArray:[metricValue.rawValue componentsSeparatedByString:@","]];
    }
    else {
        [wfGraph.arrStops addObject:metricValue.rawValue];
    }
    
    // Always expect sixth metric to be the number of countrols
    metricValue = [metricHeader.elements objectAtIndex:intBars + 5];
    intControls = [metricValue.rawValue intValue];
    
    int rowID = 0;
    if (intControls > 0) {
        for (int i = 0; i < intControls; i++) {
            // To get control details from grid
            
            rowID = 6 + (8 * i) + intBars;
            
            I2IControls *objControls = [[I2IControls alloc]init];
            
            objControls.uid = [[metricHeader.elements objectAtIndex:rowID] rawValue];
            
            NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID];
            MSIMetricValue *metricProperties = [row objectAtIndex:1];
            MSIPropertyGroup *propertyGroup = metricProperties.format;
            
            objControls.fFace = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingName];
            objControls.fSize = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
            
            objControls.colors = [[NSMutableArray alloc] init];
            
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            objControls.type = [[[metricHeader.elements objectAtIndex:rowID+1] rawValue] intValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+1];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            objControls.defaultCV = [[metricHeader.elements objectAtIndex:rowID+2] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+2];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            
            //  Number Format
            objControls.category = [propertyGroup propertyByPropertySetID:FormattingNumber propertyID:NumberFormattingCategory];
            objControls.format = [propertyGroup propertyByPropertySetID:FormattingNumber propertyID:NumberFormattingFormat];
            
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            objControls.min = [[metricHeader.elements objectAtIndex:rowID+3] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+3];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            [objControls.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            
            objControls.max = [[metricHeader.elements objectAtIndex:rowID+4] rawValue];
            objControls.step = [[metricHeader.elements objectAtIndex:rowID+5] rawValue];
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:rowID+5];
            metricProperties = [row objectAtIndex:1];
            propertyGroup = metricProperties.format;
            objControls.align = [propertyGroup propertyByPropertySetID:FormattingAlignment propertyID:AlignmentFormattingHorizontal];
            
            objControls.suffix = [[metricHeader.elements objectAtIndex:rowID+6] rawValue];
            objControls.position = [[metricHeader.elements objectAtIndex:rowID+7] rawValue];
            
            // Adds default values of the controls to the metrics dictionary.
            [self setDefaultValues:objControls];
            [controls addObject:objControls];
        }
    }
}
-(void)readData {
    wfGraph.arrXLabels = [[NSMutableArray alloc] init];
    wfGraph.dataForPlot = [[NSMutableArray alloc] init];
    wfGraph.formulae = [[NSMutableArray alloc] init];
    wfGraph.dataLabels = [[NSMutableArray alloc] init];
    
    int rowID = 6 + 8 * intControls + intBars;
    
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
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    // Loop through supporting metrics and add to dictionary
    for (int i = rowID; i < current.count; i++){
        NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i];//Number of columns in grid
        
        MSIHeaderValue *attributeCell = [row objectAtIndex:0];
        NSString *attributeValue = attributeCell.headerValue;
        MSIMetricValue *metricValue = [row objectAtIndex:1];
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
                [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",metricValue.rawValue]] forKey:attributeValue];
            }
            else {
                [metrics setValue:metricValue.rawValue forKey:attributeValue];
            }
            
        }
    }
    
    // Writes control default values to the plist file.
    [PlistData setValue:[NSString stringWithFormat:@"%d",companyID] keyForSlider:panelKey];
    
    // Loop through bar metrics headers and fill colors + labels + formulae + variable names
    for (int i = 0; i < intBars; i++){
        MSIHeaderValue *cell = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+5] objectAtIndex:0];
        MSIMetricValue *val = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+5] objectAtIndex:1];
        MSIPropertyGroup *propGroup = cell.format;
        // Postive Bar Color
        [wfGraph.colors addObject:[self colorConvertor:[propGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
        propGroup = val.format;
        // Negative Bar Color
        [wfGraph.colors addObject:[self colorConvertor:[propGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
        [wfGraph.formulae addObject:val.rawValue];
        
        NSString *strVariable = cell.headerValue;
        strVariable = [strVariable stringByReplacingOccurrencesOfString:@" " withString:@""];
        strVariable = [strVariable stringByReplacingOccurrencesOfString:@"(" withString:@""];
        strVariable = [strVariable stringByReplacingOccurrencesOfString:@")" withString:@""];
        [wfGraph.dataLabels addObject:strVariable];
        [wfGraph.dataForPlot addObject:[self handleFormulae:[val.rawValue mutableCopy] storeKey:strVariable]];
        [wfGraph.arrXLabels addObject:cell.headerValue];
    }
    
}
#pragma mark Implementation of Control objects
-(UIView *)renderControl:(I2IControls*)i2iControl {
    
    NSArray *arrPosition = [[NSArray alloc] initWithArray:[i2iControl.position componentsSeparatedByString:@","]];
    CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
    UIView *uivContainer = [[UIView alloc]initWithFrame:frameRect];
    
    switch (i2iControl.type) {
        case 1:
            // Code for Slider
            uivContainer = [self createSlider:frameRect withParams:i2iControl];
            break;
        case 2:
            // Code for Textbox
            uivContainer = [self createTextBox:frameRect withParams:i2iControl];
            break;
        case 3:
            // Code for Toggle.
            uivContainer = [self createToggle:frameRect withParams:i2iControl];
            break;
        case 5:
            // Code for Reset Button.
            if ([i2iControl.defaultCV isEqualToString:@"1"]) {
                uivContainer = [self createResetButton:frameRect withParams:i2iControl];
            }
            break;
        case 6:
            // Code for Emit Button.
            uivContainer = [self createEmitButton:frameRect withParams:i2iControl];
            break;
        default:
            break;
    }
    
    return uivContainer;
}
-(UIView *)createSlider:(CGRect)frameRect withParams:(I2IControls*)i2iControl {
    UIView *uivSlider = [[UIView alloc] initWithFrame:frameRect];
    
    CGRect frameLabel = CGRectMake(0, 0, frameRect.size.width, 20);
    UILabel *lblValue = [[UILabel alloc] initWithFrame:frameLabel];
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
    
    // Text Alignment Settings
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
-(UITextField *)createTextBox:(CGRect)frameRect withParams:(I2IControls*)i2iControl {
    
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
    if ([[PlistData getValue] valueForKey:i2iControl.uid] != nil) {
        
        double fDefaultValue = [[NSString stringWithFormat:@"%@",[eval evaluateFormula:[[PlistData getValue] valueForKey:i2iControl.uid] withDictionary:metrics]] doubleValue];
        uitfInput.text = [self setNumberFormat:[NSString stringWithFormat:@"%lf",fDefaultValue] withFormatCategory:i2iControl.category withFormat:i2iControl.format];
    }
    else {
        uitfInput.text = [self setNumberFormat:[NSString stringWithFormat:@"%@",[eval evaluateFormula:i2iControl.defaultCV withDictionary:metrics]] withFormatCategory:i2iControl.category withFormat:i2iControl.format];
    }
    uitfInput.textAlignment = NSTextAlignmentRight;
    uitfInput.userInteractionEnabled=YES;
    return uitfInput;
}
-(UIView *)createToggle:(CGRect)frameRect withParams:(I2IControls*)i2iControl{
    
    UIView *uivToggle = [[UIView alloc] initWithFrame:frameRect];
    UISwitch *uisToggle  = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)];
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

#pragma mark -
#pragma mark handleEvent Methods
//  When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    [self cleanViews];
    [controls removeAllObjects];
    [metrics removeAllObjects];
    [self recreateWidget];
}
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
    [self refreshGraphRedoNumbers];
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
    [self refreshGraphRedoNumbers];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
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
                    else {
                        //Message to validate textbox
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
                // Message to validate textbox
                [self showAlertWithMessage:[NSString stringWithFormat:@"Please enter valid input"]];
                double fDefaultValue = [[[PlistData getValue] valueForKey:i2iControl.uid] doubleValue];
                accessoryTf.text=[self setNumberFormat:[NSString stringWithFormat:@"%lf",fDefaultValue] withFormatCategory:i2iControl.category withFormat:i2iControl.format];
                isValidInput = NO;
                [accessoryTf resignFirstResponder];
                [activeInputBox resignFirstResponder];
            }
        }
    }
    [self refreshGraphRedoNumbers];
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

#pragma mark Converts BGR value to UIColor object
-(UIColor *)colorConvertor:(NSString *)strColor {
    //  We got B G R here, but we need RGB
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF)/255.0f green:((bgrValue & 0xFF00)>>8)/255.0f blue:((bgrValue & 0xFF0000) >> 16)/255.0f alpha:1.0f];
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
    return [numFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",strValue]]];
}

-(void)refreshGraphRedoNumbers {
    // Loop through bar formulae and update the numbers to be plotted
    for (int i = 0; i < intBars; i++){
        [wfGraph.dataForPlot replaceObjectAtIndex:i withObject:[self handleFormulae:[[wfGraph.formulae objectAtIndex:i] mutableCopy] storeKey:[wfGraph.dataLabels objectAtIndex:i]]];
    }
    [wfGraph refreshWaterFallGraph];
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

-(NSString *)handleFormulae:(NSMutableString *)Formula storeKey:(NSString *)Key {
    NSString *strCalcValue;
    if ([Formula hasPrefix:@"#"]) {
        if ([Formula containsString:@"fn"]) {
            [Formula deleteCharactersInRange:[Formula rangeOfString:@"#fn#"]];
            strCalcValue = [NSString stringWithFormat:@"%@",[eval evaluateFormula:Formula withDictionary:metrics]];
        }
        else{
            [Formula deleteCharactersInRange:[Formula rangeOfString:@"#"]];
            strCalcValue = [NSString stringWithFormat:@"%@",[eval evaluateFormula:Formula withDictionary:metrics]];
        }
        if ([Key hasPrefix:@"suffixText"]) {
            [PlistData setValue:[metrics objectForKey:Formula] keyForSlider:Key];
            [metrics setValue:[metrics objectForKey:Formula] forKey:Key];
        }
        else {
            [PlistData setValue:[NSString stringWithFormat:@"%@",strCalcValue] keyForSlider:Key];
            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",strCalcValue]] forKey:Key];
        }
    }
    else {
        strCalcValue = [NSString stringWithFormat:@"%@",[eval evaluateFormula:Formula withDictionary:metrics]];
    }
    return strCalcValue;
}
@end
