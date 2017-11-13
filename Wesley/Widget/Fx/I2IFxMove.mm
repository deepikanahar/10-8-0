//
//  I2IFxMove.mm
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 30/03/17.
//  Modified by Pradeep Yadav on 10/04/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2IFxMove.h"
#import "FormulaEvaluator.h"

@implementation I2IFxMove

@synthesize dataModel;

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    
    if (self) {
        
        labels = [[NSMutableArray alloc] init];
        internalControls = [[NSMutableArray alloc] init];
        internalLabels = [[NSMutableArray alloc] init];
        
        eval = [[FormulaEvaluator alloc] init];
        activeInputBox = [[UITextField alloc] init];
        
        isValidInput = YES;
        flagInverseRate = 0;
        
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
    
    for (UIView *view in self.subviews) {
        
        if ([view isKindOfClass:[UIView class]]) {
            
            UIView *v = (UIView *)view;
            [v removeFromSuperview];
            
        }
        
    }
    
}

//  This method is called every time the widget is recreated, which could be during initialization, when a layout or panel changes, or when the widget’s source selector is changed.
-(void)recreateWidget {
    
    [self reInitDataModels];
    
    if (resetFlag == 1) {
        
        // Renders the container for the control.
        NSArray *arrPosition = [[NSArray alloc] initWithArray:[resetControl.position componentsSeparatedByString:@","]];
        CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
        UIView *uivResetButton = [[UIView alloc] initWithFrame:frameRect];
        UIButton *btnReset = [UIButton buttonWithType:UIButtonTypeCustom];
        btnReset.frame = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
        btnReset.tag = [[resetControl.uid stringByReplacingOccurrencesOfString:@"Reset"
                                                                    withString:@"939"] intValue];
        [btnReset addTarget:self
                     action:@selector(handleResetButton:)
           forControlEvents:UIControlEventTouchUpInside];
        btnReset.userInteractionEnabled = YES;
        [btnReset setBackgroundImage:[UIImage imageNamed:@"refresh.png"]
                            forState:UIControlStateNormal];
        [uivResetButton addSubview:btnReset];
        [self addSubview:uivResetButton];
        
    }
    
    int i = 0;
    for (I2IDynamicLabel *i2iLabel in labels) {
        
        NSArray *arrPosition = [[NSArray alloc] initWithArray:[i2iLabel.position componentsSeparatedByString:@","]];
        CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
        
        // -999<i> is tag for Dynamic label.
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d", @"-999", i] integerValue];
        
        [self addSubview:[i2iLabel initializeLabel:frameRect withTag:intTag]];
        
        i++;
        
    }
    
    [self addSubview:i2iTableView];
    
    // Creates an instance of the Input Bar
    accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 768)];
    accessoryView.backgroundColor = [UIColor colorWithRed:0.576 green:0.584 blue:0.592 alpha:0.5];
    // Code for accessory Textbar.
    UIView *modelFxPop = [[UIView alloc] initWithFrame:CGRectMake(192, 488, 640, 225)];
    modelFxPop.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    modelFxPop.layer.cornerRadius = 10.0f;
    
    title = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 640, 25)];
    title.text = @"Input the starting FX rate";
    title.font = [UIFont fontWithName:fontFace
                                 size:fontSize + 4];
    title.textAlignment = NSTextAlignmentCenter;
    [modelFxPop addSubview:title];
    
    UIView *separator = [[UILabel alloc] initWithFrame:CGRectMake(378, 35, 1, 185)];
    separator.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.25];
    [modelFxPop addSubview:separator];
    
    UIButton *btnExchange = [UIButton buttonWithType:UIButtonTypeCustom];
    btnExchange.frame = CGRectMake(355, 80, 50, 50);
    btnExchange.tag = -2000;
    [btnExchange addTarget:self
                    action:@selector(handleExchangeButton:)
          forControlEvents:UIControlEventTouchUpInside];
    btnExchange.userInteractionEnabled = YES;
    [btnExchange setBackgroundImage:[UIImage imageNamed:@"exchange.png"]
                           forState:UIControlStateNormal];
    [modelFxPop addSubview:btnExchange];
    
    rateLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 55, 310, 30)];
    rateLabel.tag = -2001;
    rateLabel.font = [UIFont fontWithName:fontFace
                                 size:fontSize + 8];
    rateLabel.textColor = activeFxColor;
    rateLabel.textAlignment = NSTextAlignmentCenter;
    [modelFxPop addSubview:rateLabel];
    
    inverseRateLabel = [[UILabel alloc] initWithFrame:CGRectMake(430, 60, 150, 25)];
    rateLabel.tag = -2002;
    inverseRateLabel.font = [UIFont fontWithName:fontFace
                                     size:fontSize + 4];
    inverseRateLabel.textColor = inactiveFxColor;
    inverseRateLabel.textAlignment = NSTextAlignmentCenter;
    [modelFxPop addSubview:inverseRateLabel];
    
    accessoryTf = [[UITextField alloc] initWithFrame:CGRectMake(25, 120, 310, 55)];
    accessoryTf.backgroundColor = [UIColor whiteColor];
    accessoryTf.textAlignment = NSTextAlignmentCenter;
    accessoryTf.layer.borderColor = [activeFxColor CGColor];
    accessoryTf.layer.borderWidth = 2.0f;
    accessoryTf.font = [UIFont fontWithName:fontFace
                                       size:fontSize + 16];
    accessoryTf.keyboardType = UIKeyboardTypeDecimalPad;
    accessoryTf.layer.cornerRadius = 10.0f;
    accessoryTf.delegate = self;
    accessoryTf.tag = -1010;
    [modelFxPop addSubview:accessoryTf];
    
    inverseRate = [[UILabel alloc] initWithFrame:CGRectMake(430, 125, 150, 45)];
    inverseRate.tag = -2003;
    inverseRate.font = [UIFont fontWithName:fontFace
                                       size:fontSize + 8];
    inverseRate.textColor = inactiveFxColor;
    inverseRate.textAlignment = NSTextAlignmentCenter;
    [modelFxPop addSubview:inverseRate];
    
    [accessoryView addSubview:modelFxPop];
    
}

//  Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    
    //  Update the widget's data.
    [self.widgetHelper reInitDataModels];
    dataModel = (MSIModelData *)[widgetHelper dataProvider];
    if (dataModel.rowCount > 0) [self readData];
    
}

#pragma mark Data Retrieval Method
-(void)readData {
    
    NSMutableArray *current = dataModel.metricHeaderArray;
    MSIMetricHeader *metricHeader = [current objectAtIndex:0];
    
    // Always expect first metric header to be the unique identifier for the panel / control grid.
    NSMutableArray *row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                  andRowIndex:0];
    MSIHeaderValue *attributeCell = [row objectAtIndex:0];
    panelKey = [[NSString alloc] initWithFormat:@"%@", attributeCell.headerValue];
    
    MSIPropertyGroup *propertyGroup = attributeCell.format;
    fontFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                           propertyID:FontFormattingName];
    fontSize = [[propertyGroup propertyByPropertySetID:FormattingFont
                                            propertyID:FontFormattingSize] intValue];
    
    metrics = [[NSMutableDictionary alloc] init];
    
    // Always expect second metric to be the unique identifier for the table.
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:1];
    i2iTableID = [[NSString alloc] initWithFormat:@"Table%dRows", [metricValue.rawValue intValue]];
    
    //Third metric is for table position
    NSArray *tablePosition = [[[metricHeader.elements objectAtIndex:2] rawValue] componentsSeparatedByString:@","];
    CGRect gridFrame = CGRectMake([[tablePosition objectAtIndex:0] floatValue], [[tablePosition objectAtIndex:1] floatValue], [[tablePosition objectAtIndex:2] floatValue], [[tablePosition objectAtIndex:3] floatValue] - 65);
    i2iTableView = [[UITableView alloc] initWithFrame:gridFrame style:UITableViewStylePlain];
    i2iTableView.delegate = self;
    i2iTableView.dataSource = self;
    
    // Fourth metric is for the row height.
    metricValue = [metricHeader.elements objectAtIndex:3];
    intRowHeight = [metricValue.rawValue intValue];
    
    // Sixth metric is for minimum number of rows to be displayed in the table.
    metricValue = [metricHeader.elements objectAtIndex:4];
    keyFCY = metricValue.rawValue;
    
    // Sixth metric is for maximum number of rows to be displayed in the table.
    metricValue = [metricHeader.elements objectAtIndex:5];
    intMaxRows = [[[PlistData getValue] valueForKey:metricValue.rawValue] intValue];
    
#pragma mark Internal Controls
    // Expect eighth metric to be the number of internal controls for the table.
    metricValue = [metricHeader.elements objectAtIndex:7];
    intControls = [metricValue.rawValue intValue];
    int rowID = 0;
    if (intControls > 0) {
        
        for (int j = 0; j < intMaxRows; j++) {
            
            for (int i = 0; i < intControls; i++) {
                
                // To get control details from grid.
                rowID = 8 + (8 * i);
                
                I2IControls *i2iControl = [[I2IControls alloc] init];
                
                // This variable stores the unique ID of the control.
                i2iControl.uid = [[metricHeader.elements objectAtIndex:rowID] rawValue];
                
                row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                              andRowIndex:rowID];
                MSIMetricValue *metricProperties = [row objectAtIndex:1];
                MSIPropertyGroup *propertyGroup = metricProperties.format;
                
                // These variables store font face and font size for the control labels.
                i2iControl.fFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                                               propertyID:FontFormattingName];
                i2iControl.fSize = [propertyGroup propertyByPropertySetID:FormattingFont
                                                               propertyID:FontFormattingSize];
                
                i2iControl.colors = [[NSMutableArray alloc] init];
                
                // Primary color for the control and its label.
                [i2iControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                              propertyID:FontFormattingColor]]];
                
                // Used to identify the type of control.
                // 1 = Slider, 2 = Textbox, 3 = Toggle/Switch, 4 = Radio Button.
                i2iControl.type = [[[metricHeader.elements objectAtIndex:rowID + 1] rawValue] intValue];
                
                row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                              andRowIndex:rowID + 1];
                metricProperties = [row objectAtIndex:1];
                propertyGroup = metricProperties.format;
                
                // Secondary color for the control and its label.
                [i2iControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                              propertyID:FontFormattingColor]]];
                
                // Default value of the control.
                i2iControl.defaultCV = [[metricHeader.elements objectAtIndex:rowID + 2] rawValue];
                
                row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                              andRowIndex:rowID + 2];
                metricProperties = [row objectAtIndex:1];
                propertyGroup = metricProperties.format;
                
                // Number format and category for the control values and its label.
                i2iControl.category = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                                  propertyID:NumberFormattingCategory];
                i2iControl.format = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                                propertyID:NumberFormattingFormat];
                
                // Tertiary color for the control and its label.
                [i2iControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                              propertyID:FontFormattingColor]]];
                
                // Minimum value that the control can have.
                i2iControl.min = [[metricHeader.elements objectAtIndex:rowID + 3] rawValue];
                
                row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                              andRowIndex:rowID + 3];
                metricProperties = [row objectAtIndex:1];
                propertyGroup = metricProperties.format;
                
                // Additional color for the control and its label.
                [i2iControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                              propertyID:FontFormattingColor]]];
                
                // Maximum value that the control can have.
                i2iControl.max = [[metricHeader.elements objectAtIndex:rowID + 4] rawValue];
                
                // Lowest value by which the control can incerement/decrement it's value. Only applicable to sliders.
                i2iControl.step = [[metricHeader.elements objectAtIndex:rowID + 5] rawValue];
                
                row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                              andRowIndex:rowID + 5];
                metricProperties = [row objectAtIndex:1];
                propertyGroup = metricProperties.format;
                
                // Horizontal aligment for the control's label.
                i2iControl.align = [propertyGroup propertyByPropertySetID:FormattingAlignment
                                                               propertyID:AlignmentFormattingHorizontal];
                
                // Suffix for the control's label.
                i2iControl.suffix = [[metricHeader.elements objectAtIndex:rowID + 6] rawValue];
                
                // Position of the control on the screen.
                // Format is "x,y,width,height". It is relative to the grid position in the document.
                i2iControl.position = [[metricHeader.elements objectAtIndex:rowID + 7] rawValue];
                i2iControl.uid = [i2iControl.uid stringByReplacingOccurrencesOfString:@"x"
                                                                           withString:[NSString stringWithFormat:@"%d", j]];
                i2iControl.defaultCV = [i2iControl.defaultCV stringByReplacingOccurrencesOfString:@"x"
                                                                                       withString:[NSString stringWithFormat:@"%d", j]];
                activeFxColor = [i2iControl.colors objectAtIndex:0];
                inactiveFxColor = [i2iControl.colors objectAtIndex:1];
                [self setDefaultValues:i2iControl];
                [internalControls addObject:i2iControl];
                
            }
            
        }
        
    }
    
#pragma mark Internal Labels
    rowID = 8 + (8 * intControls);
    // Always expect this metric to be the number of internal dynamic labels for the table.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    intInternalLabels = [metricValue.rawValue intValue];
    
    if (intInternalLabels > 0) {
        
        for (int j = 0; j < intMaxRows; j++) {
            
            for (int i = 0; i < intInternalLabels; i++) {
                
                // To get dynamic label details from grid.
                rowID = 9 + (8 * intControls) + (2 * i);
                
                I2IDynamicLabel *i2iLabel = [[I2IDynamicLabel alloc] init];
                
                // Gets the header value of the dynamic label.
                row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                              andRowIndex:rowID];
                attributeCell = [row objectAtIndex:0];
                i2iLabel.key = [[NSString alloc] initWithFormat:@"%@", attributeCell.headerValue];
                
                // Gets the formula used to dynamically evaluate the value of dynamic label.
                i2iLabel.formula = [[metricHeader.elements objectAtIndex:rowID] rawValue];
                MSIMetricValue *metricProperties = [row objectAtIndex:1];
                MSIPropertyGroup *propertyGroup = metricProperties.format;
                
                // Font parameters for the dynamic label.
                i2iLabel.fFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                                             propertyID:FontFormattingName];
                
                i2iLabel.fBold = [propertyGroup propertyByPropertySetID:FormattingFont
                                                             propertyID:FontFormattingBold];
                i2iLabel.fItalic = [propertyGroup propertyByPropertySetID:FormattingFont
                                                               propertyID:FontFormattingItalic];
                i2iLabel.fUnderline = [propertyGroup propertyByPropertySetID:FormattingFont
                                                                  propertyID:FontFormattingUnderline];
                
                i2iLabel.fSize = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                              propertyID:FontFormattingSize] intValue];
                i2iLabel.fColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                   propertyID:FontFormattingColor]];
                
                // Horizontal alignment parameters for the dynamic label.
                i2iLabel.align = [propertyGroup propertyByPropertySetID:FormattingAlignment
                                                             propertyID:AlignmentFormattingHorizontal];
                i2iLabel.wrap = [propertyGroup propertyByPropertySetID:FormattingAlignment
                                                            propertyID:AlignmentFormattingTextWrap];
                
                // Number formatting parameters for the dynamic label.
                i2iLabel.category = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                                propertyID:NumberFormattingCategory];
                i2iLabel.format = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                              propertyID:NumberFormattingFormat];
                i2iLabel.format = [i2iLabel.format stringByReplacingOccurrencesOfString:@"\""
                                                                             withString:@""];
                
                // Padding parameters for the dynamic label.
                i2iLabel.leftPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                               propertyID:PaddingFormattingLeftPadding];
                i2iLabel.rightPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                                propertyID:PaddingFormattingRightPadding];
                i2iLabel.topPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                              propertyID:PaddingFormattingTopPadding];
                i2iLabel.bottomPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                                 propertyID:PaddingFormattingBottomPadding];
                
                // Position of the dynamic label on the screen.
                // Format is "x,y,width,height". It is relative to the grid position in the document.
                i2iLabel.position = [[metricHeader.elements objectAtIndex:rowID + 1] rawValue];
                metricProperties = [metricHeader.elements objectAtIndex:rowID + 1];
                propertyGroup = metricProperties.format;
                i2iLabel.nColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                   propertyID:FontFormattingColor]];
                if (i2iLabel.nColor == [UIColor blackColor]) i2iLabel.nColor = i2iLabel.fColor;
                
                i2iLabel.key = [i2iLabel.key stringByReplacingOccurrencesOfString:@"x"
                                                                       withString:[NSString stringWithFormat:@"%d", j]];
                i2iLabel.formula = [i2iLabel.formula stringByReplacingOccurrencesOfString:@"x"
                                                                               withString:[NSString stringWithFormat:@"%d", j]];
                [internalLabels addObject:i2iLabel];
                
            }
            
        }
        
    }
    
#pragma mark Reset Control
    rowID = 9 + (8 * intControls) + (2 * intInternalLabels);
    // Always expect this metric to be the flag for spinner control.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    resetFlag = [metricValue.rawValue intValue];
    
    if (resetFlag == 1) {
        
        // To get control details from grid.
        rowID = 10 + (8 * intControls) + (2 * intInternalLabels);
        resetControl = [[I2IControls alloc] init];
        
        // This variable stores the unique ID of the control.
        resetControl.uid = [[metricHeader.elements objectAtIndex:rowID] rawValue];
        // Position of the control on the screen.
        // Format is "x,y,width,height". It is relative to the grid position in the document.
        resetControl.position = [[metricHeader.elements objectAtIndex:rowID + 7] rawValue];
        
    }
    
#pragma mark Dynamic Labels
    rowID = 10 + (8 * intControls) + (2 * intInternalLabels) + (8 * resetFlag);
    // Always expect this metric to be the number of dynamic labels.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    intLabels = [metricValue.rawValue intValue];
    
    if (intLabels > 0) {
        
        for (int i = 0; i < intLabels; i++) {
            
            // To get dynamic label details from grid.
            rowID = 11 + (8 * intControls) + (2 * intInternalLabels) + (8 * resetFlag) + (2 * i);
            
            I2IDynamicLabel *objLabel = [[I2IDynamicLabel alloc] init];
            
            // Gets the header value of the dynamic label.
            row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                          andRowIndex:rowID];
            attributeCell = [row objectAtIndex:0];
            objLabel.key = [[NSString alloc] initWithFormat:@"%@", attributeCell.headerValue];
            
            // Gets the formula used to dynamically evaluate the value of dynamic label.
            objLabel.formula = [[metricHeader.elements objectAtIndex:rowID] rawValue];
            
            row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                          andRowIndex:rowID];
            MSIMetricValue *metricProperties = [row objectAtIndex:1];
            MSIPropertyGroup *propertyGroup = metricProperties.format;
            
            // Font parameters for the dynamic label.
            objLabel.fFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                                         propertyID:FontFormattingName];
            
            objLabel.fBold = [propertyGroup propertyByPropertySetID:FormattingFont
                                                         propertyID:FontFormattingBold];
            objLabel.fItalic = [propertyGroup propertyByPropertySetID:FormattingFont
                                                           propertyID:FontFormattingItalic];
            objLabel.fUnderline = [propertyGroup propertyByPropertySetID:FormattingFont
                                                              propertyID:FontFormattingUnderline];
            
            objLabel.fSize = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                          propertyID:FontFormattingSize] intValue];
            objLabel.fColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                               propertyID:FontFormattingColor]];
            
            // Horizontal alignment parameters for the dynamic label.
            objLabel.align = [propertyGroup propertyByPropertySetID:FormattingAlignment
                                                         propertyID:AlignmentFormattingHorizontal];
            objLabel.wrap = [propertyGroup propertyByPropertySetID:FormattingAlignment
                                                        propertyID:AlignmentFormattingTextWrap];
            
            // Number formatting parameters for the dynamic label.
            objLabel.category = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                            propertyID:NumberFormattingCategory];
            objLabel.format = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                          propertyID:NumberFormattingFormat];
            objLabel.format = [objLabel.format stringByReplacingOccurrencesOfString:@"\""
                                                                         withString:@""];
            
            // Padding parameters for the dynamic label.
            objLabel.leftPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                           propertyID:PaddingFormattingLeftPadding];
            objLabel.rightPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                            propertyID:PaddingFormattingRightPadding];
            objLabel.topPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                          propertyID:PaddingFormattingTopPadding];
            objLabel.bottomPad = [propertyGroup propertyByPropertySetID:FormattingPadding
                                                             propertyID:PaddingFormattingBottomPadding];
            
            // Position of the dynamic label on the screen.
            // Format is "x,y,width,height". It is relative to the grid position in the document.
            objLabel.position = [[metricHeader.elements objectAtIndex:rowID + 1] rawValue];
            metricProperties = [metricHeader.elements objectAtIndex:rowID + 1];
            propertyGroup = metricProperties.format;
            objLabel.nColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                               propertyID:FontFormattingColor]];
            if (objLabel.nColor == [UIColor blackColor]) objLabel.nColor = objLabel.fColor;
            
            [labels addObject:objLabel];
            
        }
        
    }
    
    // Sets the index to the row containing the first supporting/base metric.
    rowID = 11 + (8 * intControls) + (2 * intInternalLabels) + (8 * resetFlag) + (2 * intLabels);
    
    for (NSString *strKey in [[PlistData getValue] allKeys]) {
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]];
        if (number != nil) [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]]
                                      forKey:strKey];
        else [metrics setValue:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]
                        forKey:strKey];
        
    }
    
#pragma mark Supporting Metrics
    // Loop through all the supporting metrics and add to the key-value pair to metrics dictionary.
    for (int i = rowID; i < current.count; i++) {
        
        row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                      andRowIndex:i];
        //Number of columns in grid
        
        attributeCell = [row objectAtIndex:0];
        NSString *attributeValue = attributeCell.headerValue;
        metricValue = [row objectAtIndex:1];
        NSString *strMetricValue = metricValue.rawValue;
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *number = [f numberFromString:strMetricValue];
            
        if (number != nil) [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [metricValue rawValue]]]
                                      forKey:attributeValue];
        else [metrics setValue:[metricValue rawValue]
                        forKey:attributeValue];
        
    }
    
}

#pragma mark handleEvent Methods
//  When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    
    [self cleanViews];
    [labels removeAllObjects];
    resetControl = nil;
    [internalControls removeAllObjects];
    [internalLabels removeAllObjects];
    [metrics removeAllObjects];
    [self recreateWidget];
    
}

#pragma mark Converts BGR value to UIColor object
-(UIColor *)colorConvertor:(NSString *)strColor {
    
    //  We got B G R here, but we need RGB
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF) / 255.0f
                           green:((bgrValue & 0xFF00) >> 8) / 255.0f
                            blue:((bgrValue&0xFF0000) >> 16) / 255.0f
                           alpha:1.0f];
    
}

#pragma mark Implementation of Control objects
-(UIView *)renderControl:(I2IControls*)i2iControl {
    
    // Renders the container for the control.
    NSArray *arrPosition = [[NSArray alloc] initWithArray:[i2iControl.position componentsSeparatedByString:@","]];
    CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
    UIView *uivContainer = [[UIView alloc] initWithFrame:frameRect];
    
    switch (i2iControl.type) {
            
        case 1:
            //  Code for Slider.
            uivContainer = [self createSlider:frameRect
                                   withParams:i2iControl];
            break;
            
        case 9:
            //  Code for FxBox.
            uivContainer = [self createFxBox:frameRect
                                  withParams:i2iControl];
            break;
            
        default:
            break;
            
    }
    return uivContainer;
    
}

-(UIView *)createSlider:(CGRect)frameRect
             withParams:(I2IControls*)i2iControl {
    
    UIView *uivSlider = [[UIView alloc] initWithFrame:frameRect];
    
    CGRect frameLabel = CGRectMake(frameRect.size.width - frameRect.origin.y - 10, 0, frameRect.origin.y + 10, frameRect.size.height);
    UILabel *lblValue = [[UILabel alloc] initWithFrame:frameLabel];
    
    // Tags the label object for reference and updating the value in event handlers.
    lblValue.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Slider"
                                                              withString:@"909"] integerValue];
    lblValue.font = [UIFont fontWithName:i2iControl.fFace
                                    size:[i2iControl.fSize intValue]];
    
    lblValue.text = [self setNumberFormat:[[PlistData getValue] valueForKey:i2iControl.uid]
                       withFormatCategory:i2iControl.category
                               withFormat:i2iControl.format];
    
    // Horizontal alignment for the control's label.
    switch ([i2iControl.align intValue]) {
            
        case 4: lblValue.textAlignment = NSTextAlignmentRight;
            break;
            
        case 3: lblValue.textAlignment = NSTextAlignmentCenter;
            break;
            
        default: lblValue.textAlignment = NSTextAlignmentLeft;
            break;
            
    }
    
    // This color is set on the minimum value para-metric
    lblValue.textColor = [i2iControl.colors objectAtIndex:3];
    lblValue.numberOfLines = 0;
    lblValue.lineBreakMode = NSLineBreakByWordWrapping;
    [uivSlider addSubview:lblValue];
    
    UIButton *btnMinus = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect frameMinusButton = CGRectMake(0, 0, frameRect.size.height, frameRect.size.height);
    btnMinus.frame = frameMinusButton;
    [btnMinus setTitle:@"" forState:UIControlStateNormal];
    btnMinus.titleLabel.font = [UIFont fontWithName:i2iControl.fFace
                                               size:[i2iControl.fSize intValue]];
    btnMinus.backgroundColor = [UIColor clearColor];
    
    [btnMinus addTarget:self
                 action:@selector(handleMinus:)
       forControlEvents:UIControlEventTouchUpInside];
    [btnMinus setBackgroundImage:[UIImage imageNamed:@"minus.png"]
                        forState:UIControlStateNormal];
    [uivSlider addSubview:btnMinus];
    
    CGRect frameSlider = CGRectMake(frameRect.size.height + 10, 0, frameRect.size.width - (frameRect.size.height * 2) - frameRect.origin.y - 35, frameRect.size.height);
    
    UISlider *i2iSlider = [[UISlider alloc] init];
    i2iSlider.frame = frameSlider;
    i2iSlider.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Slider"
                                                               withString:@"999"] integerValue];
    i2iSlider.minimumValue = [i2iControl.min floatValue];
    i2iSlider.maximumValue = [i2iControl.max floatValue];
    
    i2iSlider.value = [lblValue.text floatValue];
    
    i2iSlider.continuous = YES;
    i2iSlider.minimumTrackTintColor = [i2iControl.colors objectAtIndex:0];
    i2iSlider.maximumTrackTintColor = [i2iControl.colors objectAtIndex:2];
    
    [i2iSlider addTarget:self
                  action:@selector(handleSliderChange:)
        forControlEvents:UIControlEventValueChanged];
    [uivSlider addSubview:i2iSlider];
    
    CGRect framePlusButton = CGRectMake(frameRect.size.width - frameRect.origin.y - frameRect.size.height - 15, 0, frameRect.size.height, frameRect.size.height);
    UIButton *btnPlus = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPlus.frame = framePlusButton;
    [btnPlus setTitle:@""
             forState:UIControlStateNormal];
    btnPlus.titleLabel.font = [UIFont fontWithName:i2iControl.fFace
                                              size:[i2iControl.fSize intValue]];
    btnPlus.backgroundColor = [UIColor clearColor] ;
    
    [btnPlus addTarget:self
                action:@selector(handlePlus:)
      forControlEvents:UIControlEventTouchUpInside];
    [btnPlus setBackgroundImage:[UIImage imageNamed:@"plus.png"]
                       forState:UIControlStateNormal];
    [uivSlider addSubview:btnPlus];
    
    return uivSlider;
    
}

-(UIButton *)createFxBox:(CGRect)frameRect
                 withParams:(I2IControls*)i2iControl {
    
    UIButton *btnFx = [UIButton buttonWithType:UIButtonTypeCustom];
    btnFx.frame = frameRect;
    btnFx.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Input"
                                                           withString:@"808"] intValue];
    [btnFx addTarget:self
              action:@selector(handleFxButton:)
    forControlEvents:UIControlEventTouchUpInside];
    btnFx.userInteractionEnabled = YES;
    
    CGRect frameLabel = CGRectMake(0, 0, frameRect.size.width - 20, frameRect.size.height / 2);
    UILabel *lblValue = [[UILabel alloc] initWithFrame:frameLabel];
    
    // Tags the label object for reference and updating the value in event handlers.
    lblValue.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Input" withString:@"818"] integerValue];
    lblValue.font = [UIFont fontWithName:i2iControl.fFace
                                    size:[i2iControl.fSize intValue]];
    
    lblValue.text = [self setNumberFormat:[[PlistData getValue] valueForKey:i2iControl.uid]
                       withFormatCategory:i2iControl.category
                               withFormat:i2iControl.format];
    
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
    
    lblValue.textColor = [i2iControl.colors objectAtIndex:0];
    lblValue.numberOfLines = 0;
    lblValue.lineBreakMode = NSLineBreakByWordWrapping;
    [btnFx addSubview:lblValue];
    
    CGRect frameIcon = CGRectMake(frameRect.size.width - 15, frameRect.size.height / 2 - 7.5, 15, 15);
    
    UIImageView *icon = [[UIImageView alloc] initWithFrame:frameIcon];
    [icon setImage:[UIImage imageNamed:@"pencil.png"]];
    icon.backgroundColor = [UIColor clearColor];
    [btnFx addSubview:icon];
    
    /*UIView * separator = [[UIView alloc] initWithFrame:CGRectMake(0, frameRect.size.height / 2, frameRect.size.width - 20, 0.5)];
    separator.backgroundColor =  [i2iControl.colors objectAtIndex:2];
    [btnFx addSubview:separator];*/
    
    UITextField *dummyInput = [[UITextField alloc] initWithFrame:CGRectMake(frameRect.size.width, frameRect.size.height, 1, 1)];
    dummyInput.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Input"
                                                                withString:@"828"] integerValue];
    dummyInput.delegate = self;
    dummyInput.keyboardType = UIKeyboardTypeDecimalPad;
    if ([[PlistData getValue] valueForKey:i2iControl.uid] != nil) {
        
        double fDefaultValue = [[[PlistData getValue] valueForKey:i2iControl.uid] doubleValue];
        dummyInput.text = [self setNumberFormat:[NSString stringWithFormat:@"%lf", fDefaultValue]
                             withFormatCategory:i2iControl.category
                                     withFormat:i2iControl.format];
        
    }
    else dummyInput.text = [self setNumberFormat:i2iControl.defaultCV
                              withFormatCategory:i2iControl.category
                                      withFormat:i2iControl.format];
    
    dummyInput.userInteractionEnabled = YES;
    [btnFx addSubview:dummyInput];
    return btnFx;
    
}

#pragma mark Event Handlers for Controls
//  Calls when slider value changes
-(void)handleSliderChange:(id)sender {
    
    [activeInputBox resignFirstResponder];
    UISlider *slider = (UISlider *)sender;
    NSString *strSliderVal;
    
    for (I2IControls *i2iControl in internalControls) {
        
        if ([i2iControl.uid isEqualToString:[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999"
                                                                                                   withString:@"Slider"]]) {
            
            UILabel *lblTarget = (UILabel *)[self viewWithTag:[[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999"
                                                                                                                      withString:@"909"] integerValue]];
            // 909 is tag for Slider Label
            if ([i2iControl.suffix isEqualToString:@"%"]) {
                
                if ([i2iControl.step isEqualToString:@"1"]) {
                    
                    slider.value = (int)slider.value;
                    strSliderVal = [NSString stringWithFormat:@"%.2f", slider.value / 100];
                    
                }
                else {
                    
                    if (roundf(slider.value / [i2iControl.step floatValue]) * [i2iControl.step floatValue] == 0) strSliderVal = @"0";
                    else strSliderVal = [NSString stringWithFormat:@"%.3f", slider.value / 100];
                    
                }
                
            }
            else {
                
                if ([i2iControl.step isEqualToString:@"1"]) strSliderVal = [NSString stringWithFormat:@"%d", (int)slider.value];
                else {
                    
                    if (roundf(slider.value / [i2iControl.step floatValue]) * [i2iControl.step floatValue] == 0) strSliderVal = @"0";
                    else strSliderVal = [NSString stringWithFormat:@"%.1f", slider.value];
                    
                }
                
            }
            
            lblTarget.text = [self setNumberFormat:strSliderVal
                                withFormatCategory:i2iControl.category
                                        withFormat:i2iControl.format];
            
            if ([i2iControl.suffix isEqualToString:@"Days"]) {
                
                if ([lblTarget.text isEqualToString:@"1"] || [lblTarget.text isEqualToString:@"-1"]) lblTarget.text = [NSString stringWithFormat:@"%@ Day", lblTarget.text];
                else lblTarget.text = [NSString stringWithFormat:@"%@ %@", lblTarget.text, i2iControl.suffix];
                
            }
            
            [PlistData setValue:strSliderVal
                   keyForSlider:i2iControl.uid];
            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strSliderVal]]
                       forKey:i2iControl.uid];
            break;
            
        }
        
    }
    [self updateInternalLabels];
    [self updateLabels];
    
}

//  Calls when minus button is pressed
-(void)handleMinus:(id)sender {
    
    UISlider *slider;
    for (UIView *view in [[sender superview] subviews]) {
        
        if ([view isKindOfClass:[UISlider class]]) {
            
            slider = (UISlider *)view;
            break;
            
        }
        
    }
    for (I2IControls *i2iControl in internalControls) {
        
        if ([i2iControl.uid isEqualToString:[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999"
                                                                                                   withString:@"Slider"]]) {
            
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
        
        if ([view isKindOfClass:[UISlider class]]) {
            
            slider = (UISlider *)view;
            break;
            
        }
        
    }
    for (I2IControls *i2iControl in internalControls) {
        
        if ([i2iControl.uid isEqualToString:[[@(slider.tag) stringValue] stringByReplacingOccurrencesOfString:@"999"
                                                                                                   withString:@"Slider"]]) {
            
            slider.value += [i2iControl.step floatValue];
            break;
            
        }
        
    }
    [self handleSliderChange:slider];
    
}

-(void)handleResetButton:(id)sender {
    
    [PlistData removeKey:panelKey];
    for (I2IControls *i2iControl in internalControls) [PlistData removeKey:i2iControl.uid];
    [self handleEvent:@"nil"];
    
}

-(void)handleExchangeButton:(id)sender {
    
    inverseRate.text = [NSString stringWithFormat:@"%f", 1.000000 * [accessoryTf.text doubleValue]];
    accessoryTf.text = [NSString stringWithFormat:@"%f", 1.000000 / [accessoryTf.text doubleValue]];
    [accessoryTf selectAll:nil];
    if (flagInverseRate == 0) {
        
        flagInverseRate = 1;
        
        
        rateLabel.text = [NSString stringWithFormat:@"%@ versus %@", [metrics objectForKey:keyFCY], [metrics objectForKey:@"sftLCY"]];
        inverseRateLabel.text = [NSString stringWithFormat:@"%@ versus %@", [metrics objectForKey:@"sftLCY"], [metrics objectForKey:keyFCY]];
        
    }
    else {

        flagInverseRate = 0;
        rateLabel.text = [NSString stringWithFormat:@"%@ versus %@", [metrics objectForKey:@"sftLCY"], [metrics objectForKey:keyFCY]];
        inverseRateLabel.text = [NSString stringWithFormat:@"%@ versus %@", [metrics objectForKey:keyFCY], [metrics objectForKey:@"sftLCY"]];
        
    }
    
}

-(void)handleFxButton:(id)sender {
    
    UITextField *textField;
    UIButton *fxCaller = (UIButton *)sender;
    for (UIView *view in [fxCaller subviews]) {
        
        if ([view isKindOfClass:[UITextField class]]) {
            
            textField = (UITextField *)view;
            break;
            
        }
        
    }
    flagInverseRate = 0;
    NSString *textFieldID = [NSString stringWithFormat:@"%d", (int)textField.tag];
    keyFCY = [[keyFCY substringToIndex:keyFCY.length - 1] stringByAppendingString:[textFieldID substringFromIndex:textFieldID.length - 1]];
    [textField becomeFirstResponder];
    
}

#pragma mark UITextField Delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    if (textField.tag != -1010) {
        
        accessoryTf.tag = textField.tag;
        accessoryTf.text = textField.text;
        
    }
    if (isValidInput == YES) {
        
        textField.inputAccessoryView = accessoryView;
        [accessoryTf becomeFirstResponder];
        
    }
    inverseRate.text = [NSString stringWithFormat:@"%f", 1.0 / [textField.text doubleValue]];
    rateLabel.text = [NSString stringWithFormat:@"%@ versus %@", [metrics objectForKey:@"sftLCY"], [metrics objectForKey:keyFCY]];
    inverseRateLabel.text = [NSString stringWithFormat:@"%@ versus %@", [metrics objectForKey:keyFCY], [metrics objectForKey:@"sftLCY"]];
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (isValidInput == YES) {
        
        activeInputBox = textField;
        accessoryTf.text = textField.text;
        
    }
    else [accessoryTf selectAll:nil];
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    for (I2IControls *i2iControl in internalControls) {
        
        if ([i2iControl.uid isEqualToString:[[@(accessoryTf.tag) stringValue] stringByReplacingOccurrencesOfString:@"828"
                                                                                                        withString:@"Input"]]) {
            
            // 919 is tag for Input values
            if ([self validateTextField:accessoryTf.text] == YES) {
                
                NSMutableString *mutableStr = [[NSMutableString alloc] initWithString:accessoryTf.text];
                double fUpdatedString = 0.0;
                fUpdatedString = [[mutableStr stringByReplacingOccurrencesOfString:@","
                                                                        withString:@""] doubleValue];
                
                if (fUpdatedString >= [i2iControl.min doubleValue] && fUpdatedString <= [i2iControl.max doubleValue]) {
                    
                    if (flagInverseRate == 1) fUpdatedString = 1 / fUpdatedString;
                    [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", fUpdatedString]]
                               forKey:i2iControl.uid];
                    [PlistData setValue:[NSString stringWithFormat:@"%f", fUpdatedString]
                           keyForSlider:i2iControl.uid];
                    i2iControl.defaultCV = [NSString stringWithFormat:@"%f", fUpdatedString];
                    if ([activeInputBox.text isEqualToString:@""]) accessoryTf.text = activeInputBox.text;
                    activeInputBox.text = [[self setNumberFormat:[NSString stringWithFormat:@"%lf", fUpdatedString]
                                              withFormatCategory:i2iControl.category
                                                      withFormat:i2iControl.format] mutableCopy];
                    accessoryTf.text = activeInputBox.text;
                    
                    UILabel *lblTarget = (UILabel *)[self viewWithTag:[[[@(accessoryTf.tag) stringValue] stringByReplacingOccurrencesOfString:@"828" withString:@"818"] integerValue]];
                    lblTarget.text = [[self setNumberFormat:[NSString stringWithFormat:@"%lf", fUpdatedString]
                                         withFormatCategory:i2iControl.category
                                                 withFormat:i2iControl.format] mutableCopy];
                    accessoryTf.text = activeInputBox.text;;
                    
                    isValidInput = YES;
                    [accessoryTf selectAll:nil];
                    [accessoryTf resignFirstResponder];
                    [activeInputBox resignFirstResponder];
                    
                }
                else {
                    
                    [self showAlertWithMessage:[NSString stringWithFormat:@"Please enter value within %@ to %@", i2iControl.min, i2iControl.max]];
                    double fDefaultValue = [[[PlistData getValue] valueForKey:i2iControl.uid] doubleValue];
                    accessoryTf.text = [self setNumberFormat:[NSString stringWithFormat:@"%lf", fDefaultValue]
                                          withFormatCategory:i2iControl.category
                                                  withFormat:i2iControl.format];
                    isValidInput = NO;
                    [accessoryTf resignFirstResponder];
                    [activeInputBox resignFirstResponder];
                    
                }
                
            }
            else {
                
                [self showAlertWithMessage:[NSString stringWithFormat:@"Please enter valid input."]];
                double fDefaultValue = [[[PlistData getValue] valueForKey:i2iControl.uid] doubleValue];
                accessoryTf.text=[self setNumberFormat:[NSString stringWithFormat:@"%lf", fDefaultValue]
                                    withFormatCategory:i2iControl.category
                                            withFormat:i2iControl.format];
                isValidInput = NO;
                [accessoryTf resignFirstResponder];
                [activeInputBox resignFirstResponder];
                
            }
            
        }
        
    }
    
    [self updateInternalLabels];
    [self updateLabels];
    
    return YES;
    
}

-(BOOL)validateTextField: (NSString *)alpha {
    
    NSString *abnRegex = @"[0-9%,.]+";
    NSPredicate *abnTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", abnRegex];
    BOOL isValid = [abnTest evaluateWithObject:alpha];
    return isValid;
    
}

-(NSString *)removeUnwantedString:(NSString *)inputStr {
    
    NSString *outputStr = [inputStr stringByReplacingOccurrencesOfString:@"("
                                                              withString:@""];
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@")"
                                                     withString:@""];
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@"%"
                                                     withString:@""];
    return outputStr;
    
}

-(void)showAlertWithMessage:(NSString *)message {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alert addAction:okButton];
    [self.window.rootViewController presentViewController:alert
                                                 animated:YES
                                               completion:nil];
    
}

#pragma mark Sets and Gets Default Values
-(void)setDefaultValues:(I2IControls *)objControls {
    
    NSString *strTempControl = [NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:objControls.uid]];
    
    if ([strTempControl isEqualToString:@"(null)"]) {
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:objControls.defaultCV];
        if (number == nil) objControls.defaultCV = [[eval evaluateFormula:objControls.defaultCV
                                                           withDictionary:[PlistData getValue]] stringValue];
        [PlistData setValue:objControls.defaultCV
               keyForSlider:objControls.uid];
        
    }
    else {
        
        objControls.defaultCV = [[PlistData getValue] valueForKey:objControls.uid];
        
    }
    
}

#pragma mark Updates Dynamic Labels
-(void)updateLabels {
    
    for (int i = 0; i < intLabels; i++) {
        
        I2IDynamicLabel *lblTemp = [labels objectAtIndex:i];
        NSString *strCalcValue;
        
        NSMutableString *str = [[NSMutableString alloc] initWithString:lblTemp.formula];
        if ([str hasPrefix:@"#"]) {
            
            if ([str containsString:@"fn"]) {
                
                [str deleteCharactersInRange:[str rangeOfString:@"#fn#"]];
                strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:str
                                                                        withDictionary:metrics]];
            }
            else {
                
                [str deleteCharactersInRange:[str rangeOfString:@"#"]];
                strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:str
                                                                        withDictionary:metrics]];
                
            }
            if ([lblTemp.key hasPrefix:@"suffixText"]) {
                
                [PlistData setValue:[metrics objectForKey:str]
                       keyForSlider:lblTemp.key];
                [metrics setValue:[metrics objectForKey:str]
                           forKey:lblTemp.key];
                
            }
            else {
                
                [PlistData setValue:[NSString stringWithFormat:@"%@", strCalcValue]
                       keyForSlider:lblTemp.key];
                [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strCalcValue]]
                           forKey:lblTemp.key];
                
            }
            
        }
        else strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:lblTemp.formula
                                                                     withDictionary:metrics]];
        
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d", @"-999", i] integerValue];
        //-999 is tag for Dynamic label
        UILabel *lblTarget = (UILabel *)[self viewWithTag:intTag];
        
        if ([strCalcValue doubleValue] < 0) lblTarget.textColor = lblTemp.nColor;
        else lblTarget.textColor = lblTemp.fColor;
        
        if ([lblTemp.key containsString:@"suffixText"]) [lblTarget setText:strCalcValue];
        else [lblTarget setText:[self setNumberFormat:strCalcValue
                                   withFormatCategory:lblTemp.category
                                           withFormat:lblTemp.format]];
        
    }
    
}

-(void)updateInternalLabels {
    
    for (int i = 0; i < internalLabels.count; i++) {
        
        I2IDynamicLabel *lblTemp = [internalLabels objectAtIndex:i];
        NSString *strCalcValue;
        
        NSMutableString *str = [[NSMutableString alloc] initWithString:lblTemp.formula];
        if ([str hasPrefix:@"#"]) {
            
            if ([str containsString:@"fn"]) {
                
                [str deleteCharactersInRange:[str rangeOfString:@"#fn#"]];
                strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:str
                                                                        withDictionary:metrics]];
            }
            else {
                
                [str deleteCharactersInRange:[str rangeOfString:@"#"]];
                strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:str
                                                                        withDictionary:metrics]];
                
            }
            if ([lblTemp.key hasPrefix:@"sft"]) {
                    
                [PlistData setValue:[metrics objectForKey:str]
                       keyForSlider:lblTemp.key];
                [metrics setValue:[metrics objectForKey:str]
                           forKey:lblTemp.key];
                
            }
            else {
                
                [PlistData setValue:[NSString stringWithFormat:@"%@", strCalcValue]
                       keyForSlider:lblTemp.key];
                [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strCalcValue]]
                           forKey:lblTemp.key];
                
            }
            
        }
        else if (!([lblTemp.key hasPrefix:@"sft"] && [lblTemp.formula containsString:@"+"]))  strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:lblTemp.formula
                                                                                                                                                      withDictionary:metrics]];
        
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d", @"-777", i] integerValue];
        //-999 is tag for Dynamic label
        UILabel *lblTarget = (UILabel *)[self viewWithTag:intTag];
        
        if ([strCalcValue doubleValue] < 0) lblTarget.textColor = lblTemp.nColor;
        else lblTarget.textColor = lblTemp.fColor;
        
        if ([lblTemp.key hasPrefix:@"sft"]) {
            
            if ([lblTemp.formula containsString:@"+"]) {
                
                [lblTarget setText:[metrics objectForKey:[[str componentsSeparatedByString:@"+"] firstObject]]];
                [lblTarget setText:[lblTarget.text stringByAppendingString:@":"]];
                [lblTarget setText:[lblTarget.text stringByAppendingString:[metrics objectForKey:[[str componentsSeparatedByString:@"+"] lastObject]]]];
                
            }
            else [lblTarget setText:[metrics objectForKey:str]];
            
        }
        else [lblTarget setText:[self setNumberFormat:strCalcValue
                                   withFormatCategory:lblTemp.category
                                           withFormat:lblTemp.format]];
        
    }
    
}

#pragma mark Sets Number Formatting
-(NSString*)setNumberFormat:(NSString*)strValue
         withFormatCategory:(NSString*)strCategory
                 withFormat:(NSString*)strFormat {
    
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
    
    NSString *outputStr = [numFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strValue]]];
    return outputStr;
    
}

#pragma mark Keyboard Notification
//  Called when the UIKeyboardDidShowNotification is sent.
-(void)keyboardWasShown:(NSNotification *)aNotification {
    
    NSDictionary *info = [aNotification userInfo];
    CGRect endRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (endRect.size.height == 984) accessoryView.frame = CGRectMake(0, -216, 1024, 768);
    else accessoryView.frame = CGRectMake(0, 0, 1024, 768);
    [accessoryTf selectAll:nil];
    
}

//  Called when the UIKeyboardWillHideNotification is sent
-(void)keyboardWillBeHidden:(NSNotification*)aNotification {
}

#pragma mark UITableView Delegates
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return (CGFloat)intRowHeight;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    return 0.1f;
    
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    UIView *footerView = [[UIView alloc] init];
    [self updateInternalLabels];
    [self updateLabels];
    return footerView;
    
}

#pragma mark - UITableView DataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return intMaxRows;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"moveCell"];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"moveCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    else for (UIView *subview in [cell.contentView subviews]) [subview removeFromSuperview];
    
    for (int ic = 0; ic < intControls; ic++) {
        
        [cell.contentView addSubview:[self renderControl:[internalControls objectAtIndex:(int)indexPath.row * intControls + ic]]];
        
    }
    
    int i = 0;
    for (int il = 0; il < intInternalLabels; il++) {
        
        I2IDynamicLabel *newLabel = [internalLabels objectAtIndex:(int)indexPath.row * intInternalLabels + il];
        
        NSArray *arrPosition = [[NSArray alloc] initWithArray:[newLabel.position componentsSeparatedByString:@","]];
        CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
        
        // -999<i> is tag for Dynamic label.
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d", @"-777", (int)indexPath.row * intInternalLabels + i] integerValue];
    
        [cell.contentView addSubview:[newLabel initializeLabel:frameRect withTag:intTag]];
        i++;
        
    }
    
    [self updateInternalLabels];
    [self updateLabels];
    
    return cell;

}

@end
