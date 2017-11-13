//
//  I2IFxPort.mm
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 30/03/17.
//  Modified by Pradeep Yadav on 10/04/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2IFxPort.h"
#import "FormulaEvaluator.h"

@implementation I2IFxPort

@synthesize dataModel;

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    
    if (self) {
        
        labels = [[NSMutableArray alloc] init];
        internalControls = [[NSMutableArray alloc] init];
        internalControlInstances = [[NSMutableArray alloc] init];
        internalLabels = [[NSMutableArray alloc] init];
        internalLabelInstances = [[NSMutableArray alloc] init];
        
        eval = [[FormulaEvaluator alloc] init];
        activeInputBox = [[UITextField alloc] init];
        
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
    
    if (spinnerFlag == 1) {
        
        NSArray *arrPosition = [[NSArray alloc] initWithArray:[pickerViewControl.position componentsSeparatedByString:@","]];
        CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
        itemPicker =  [[UIView alloc] initWithFrame:frameRect];
        [self addSubview:[self renderSpinner:pickerViewControl]];
        
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
    
    // Fifth metric is for maximum number of rows to be displayed in the table.
    metricValue = [metricHeader.elements objectAtIndex:4];
    intMaxRows = [metricValue.rawValue intValue];
    
    // Sixth metric is for minimum number of rows to be displayed in the table.
    metricValue = [metricHeader.elements objectAtIndex:5];
    intMinRows = [[[PlistData getValue] valueForKey:metricValue.rawValue] intValue];
    intCurrentRows = intMinRows;
    
    // Seventh metric is a flag to display remove button or not in the table rows..
    metricValue = [metricHeader.elements objectAtIndex:6];
    intRemoveButton = [metricValue.rawValue intValue];
    
#pragma mark Internal Controls
    // Expect eighth metric to be the number of internal controls for the table.
    metricValue = [metricHeader.elements objectAtIndex:7];
    intControls = [metricValue.rawValue intValue];
    int rowID = 0;
    if (intControls > 0) {
        
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
                                                          andRowIndex:rowID+5];
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
            [internalControls addObject:i2iControl];
            
        }
        
    }
    
#pragma mark Internal Labels
    rowID = 8 + (8 * intControls);
    // Always expect this metric to be the number of internal dynamic labels for the table.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    intInternalLabels = [metricValue.rawValue intValue];
    
    if (intInternalLabels > 0) {
        
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
            
            //row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
            //                                                   andRowIndex:rowID];
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
            [internalLabels addObject:i2iLabel];
            
        }
        
    }
    
#pragma mark Spinner Control
    rowID = 9 + (8 * intControls) + (2 * intInternalLabels);
    // Always expect this metric to be the flag for spinner control.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    spinnerFlag = [metricValue.rawValue intValue];
    
    if (spinnerFlag == 1) {
        
        // To get control details from grid.
        rowID = 10 + (8 * intControls) + (2 * intInternalLabels);
        pickerViewControl = [[I2IControls alloc] init];
        
        // This variable stores the unique ID of the control.
        pickerViewControl.uid = [[metricHeader.elements objectAtIndex:rowID] rawValue];
        
        row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                      andRowIndex:rowID];
        MSIMetricValue *metricProperties = [row objectAtIndex:1];
        MSIPropertyGroup *propertyGroup = metricProperties.format;
        
        // These variables store font face and font size for the control labels.
        pickerViewControl.fFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                                              propertyID:FontFormattingName];
        pickerViewControl.fSize = [propertyGroup propertyByPropertySetID:FormattingFont
                                                              propertyID:FontFormattingSize];
        
        pickerViewControl.colors = [[NSMutableArray alloc] init];
        
        // Primary color for the control and its label.
        [pickerViewControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                             propertyID:FontFormattingColor]]];
        
        row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                      andRowIndex:rowID + 1];
        metricProperties = [row objectAtIndex:1];
        propertyGroup = metricProperties.format;
        
        // Secondary color for the control and its label.
        [pickerViewControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                             propertyID:FontFormattingColor]]];
        
        // Default value of the control.
        pickerViewControl.defaultCV = [[metricHeader.elements objectAtIndex:rowID + 2] rawValue];
        
        row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                      andRowIndex:rowID + 2];
        metricProperties = [row objectAtIndex:1];
        propertyGroup = metricProperties.format;
        
        // Tertiary color for the control and its label.
        [pickerViewControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                             propertyID:FontFormattingColor]]];
        
        
        row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                      andRowIndex:rowID + 3];
        metricProperties = [row objectAtIndex:1];
        propertyGroup = metricProperties.format;
        
        // Additional color for the control and its label.
        [pickerViewControl.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                             propertyID:FontFormattingColor]]];
        
        pickerViewControl.step = [[metricHeader.elements objectAtIndex:rowID + 5] rawValue];
        itemListCodes = [[[pickerViewControl.step componentsSeparatedByString:@";"] objectAtIndex:0] componentsSeparatedByString:@","];
        itemListDescriptions = [[[pickerViewControl.step componentsSeparatedByString:@";"] objectAtIndex:1] componentsSeparatedByString:@","];
        
        row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                      andRowIndex:rowID + 5];
        metricProperties = [row objectAtIndex:1];
        propertyGroup = metricProperties.format;
        
        // Horizontal aligment for the control's label.
        pickerViewControl.align = [propertyGroup propertyByPropertySetID:FormattingAlignment
                                                              propertyID:AlignmentFormattingHorizontal];
        
        // Position of the control on the screen.
        // Format is "x,y,width,height". It is relative to the grid position in the document.
        pickerViewControl.position = [[metricHeader.elements objectAtIndex:rowID + 7] rawValue];
        
    }
    
#pragma mark Dynamic Labels
    rowID = 10 + (8 * intControls) + (2 * intInternalLabels) + (8 * spinnerFlag);
    // Always expect this metric to be the number of dynamic labels.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    intLabels = [metricValue.rawValue intValue];
    
    if (intLabels > 0) {
        
        for (int i = 0; i < intLabels; i++) {
            
            // To get dynamic label details from grid.
            rowID = 11 + (8 * intControls) + (2 * intInternalLabels) + (8 * spinnerFlag) + (2 * i);
            
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
            [labels addObject:objLabel];
            
        }
        
    }

#pragma mark Variables to Save
    rowID = 11 + (8 * intControls) + (2 * intInternalLabels) + (8 * spinnerFlag) + (2 * intLabels);
    // Always expect this metric to be the number of variables to save.
    metricValue = [metricHeader.elements objectAtIndex:rowID];
    intVariablesToSave = [metricValue.rawValue intValue];
    intFirstVariableIndex = rowID + 1;
    
#pragma mark Supporting Metrics
    // Sets the index to the row containing the first supporting/base metric.
    rowID = 12 + (8 * intControls) + (2 * intInternalLabels) + (8 * spinnerFlag) + (2 * intLabels) + intVariablesToSave;
    
    for (NSString *strKey in [[PlistData getValue] allKeys]) {
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]];
        if (number != nil) [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]]
                                      forKey:strKey];
        else [metrics setValue:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]
                        forKey:strKey];
        
    }
    
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
    pickerViewControl = nil;
    [internalControls removeAllObjects];
    [internalControlInstances removeAllObjects];
    [internalLabels removeAllObjects];
    [internalLabelInstances removeAllObjects];
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
            
        case 2:
            //  Code for Textbox.
            uivContainer = [self createTextBox:frameRect
                                    withParams:i2iControl];
            break;
            
        case 8:
            //  Code for Pop Button to call the Spinner.
            uivContainer = [self createPopButton:frameRect
                                      withParams:i2iControl];
            break;
            
        default:
            break;
            
    }
    return uivContainer;
    
}

-(UIView *)renderSpinner:(I2IControls*)i2iControl {
    
    // Renders the container for the control.
    NSArray *arrPosition = [[NSArray alloc] initWithArray:[i2iControl.position componentsSeparatedByString:@","]];
    CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
    UIView *uivContainer = [[UIView alloc] initWithFrame:frameRect];
    //  Code for Spinner.
    uivContainer = [self createSpinner:frameRect
                            withParams:i2iControl];
    return uivContainer;
    
}

-(UITextField *)createTextBox:(CGRect)frameRect
                   withParams:(I2IControls*)i2iControl {
    
    UITextField *uitfInput = [[UITextField alloc] initWithFrame:frameRect];
    uitfInput.delegate = self;
    uitfInput.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Input"
                                                               withString:@"919"] integerValue];
    uitfInput.font = [UIFont fontWithName:i2iControl.fFace
                                     size:[i2iControl.fSize intValue]];
    uitfInput.textColor = [i2iControl.colors objectAtIndex:0];
    
    uitfInput.layer.cornerRadius = 0.0f;
    uitfInput.layer.masksToBounds = YES;
    uitfInput.layer.borderColor = [[i2iControl.colors objectAtIndex:1] CGColor];
    uitfInput.layer.borderWidth = 1.0f;
    uitfInput.borderStyle = UITextBorderStyleBezel;
    uitfInput.keyboardType = UIKeyboardTypeDecimalPad;
    uitfInput.text = [self setNumberFormat:i2iControl.defaultCV
                        withFormatCategory:i2iControl.category
                                withFormat:i2iControl.format];
    
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
    uitfInput.userInteractionEnabled = YES;
    return uitfInput;
}

-(UIView *)createSpinner:(CGRect)frameRect
              withParams:(I2IControls*)i2iControl {
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(100, 360, frameRect.size.width - 200, 40.f)];
    toolbar.clipsToBounds = YES;
    
    inputBarFill = [i2iControl.colors objectAtIndex:0];
    inputBarColor = [i2iControl.colors objectAtIndex:1];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(pickerCancel:)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(pickerDone:)];
    UIBarButtonItem *flexibleButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                    target:nil
                                                                                    action:nil];
    
    [toolbar setItems:@[cancelButton, flexibleButton, flexibleButton, doneButton]];
    [itemPicker addSubview:toolbar];
    
    // Init the picker view.
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(100, 400, frameRect.size.width - 200, frameRect.size.height - 400)];
    
    pickerView.clipsToBounds = YES;
    pickerView.backgroundColor = [i2iControl.colors objectAtIndex:0];
    [pickerView setDataSource:self];
    [pickerView setDelegate:self];
    pickerView.showsSelectionIndicator = YES;
    [itemPicker addSubview:pickerView];
    
    itemPicker.hidden = YES;
    return itemPicker;
    
}

-(UIView *)createPopButton:(CGRect)frameRect
                withParams:(I2IControls*)i2iControl {
    
    UIButton *btnPop = [UIButton buttonWithType:UIButtonTypeCustom];
    btnPop.frame = frameRect;
    btnPop.tag = [[i2iControl.uid stringByReplacingOccurrencesOfString:@"Pop"
                                                            withString:@"888"] intValue];
    
    [btnPop addTarget:self
               action:@selector(handlePopButton:)
     forControlEvents:UIControlEventTouchUpInside];
    btnPop.userInteractionEnabled = YES;
    NSMutableDictionary *dictAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[UIFont fontWithName:i2iControl.fFace
                                                                                                              size:[i2iControl.fSize intValue]], NSFontAttributeName, [i2iControl.colors objectAtIndex:0], NSForegroundColorAttributeName, nil];
    
    [btnPop setAttributedTitle:[[NSMutableAttributedString alloc] initWithString:[itemListCodes objectAtIndex:[i2iControl.defaultCV intValue]]
                                                                      attributes:dictAttributes]
                      forState:UIControlStateNormal];
    [btnPop.layer setBorderWidth:1.0f];
    [btnPop.layer setBorderColor:[[i2iControl.colors objectAtIndex:1] CGColor]];
    return btnPop;
    
}

#pragma mark Event Handlers for Controls
//  Calls when minus button is pressed
-(void)handlePopButton:(id)sender {
    
    activePopButton = (UIButton *)sender;
    itemPicker.hidden = FALSE;
    [self bringSubviewToFront:itemPicker];
    [itemPicker becomeFirstResponder];
    
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
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (isValidInput == YES) {
        
        activeInputBox = textField;
        accessoryTf.text = textField.text;
        
    }
    else [accessoryTf selectAll:nil];
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSNumber *sum;
    NSDecimalNumber *decNum = [[NSDecimalNumber alloc] initWithInt:0];
    for (I2IControls *i2iControl in internalControlInstances) {
        
        if ([i2iControl.uid isEqualToString:[[@(accessoryTf.tag) stringValue] stringByReplacingOccurrencesOfString:@"919"
                                                                                                        withString:@"Input"]]) {
            
            // 919 is tag for Input values
            if ([self validateTextField:accessoryTf.text] == YES) {
                
                NSMutableString *mutableStr = [[NSMutableString alloc] initWithString:accessoryTf.text];
                double fUpdatedString = 0.0;
                fUpdatedString = [[mutableStr stringByReplacingOccurrencesOfString:@","
                                                                        withString:@""] doubleValue];
                
                if ([i2iControl.suffix isEqualToString:@"%"]) {
                    
                    fUpdatedString = [accessoryTf.text doubleValue] / 100;
                    
                }
                
                if (fUpdatedString >= [i2iControl.min doubleValue] && fUpdatedString <= [i2iControl.max doubleValue]) {
                    
                    
                    //Find the sum of input boxes
                    double sumOfInput = 0;
                    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
                    [fmt setNumberStyle:NSNumberFormatterDecimalStyle];
                    for (UITableViewCell *cell in i2iTableView.visibleCells) {
                        
                        for (UIView *view in [cell.contentView subviews]) {
                            
                            if ([view isKindOfClass:[UITextField class]]) {
                                
                                UITextField *textField = (UITextField *) view;
                                
                                if (view == activeInputBox) {
                                    
                                    sumOfInput += [[NSString stringWithFormat:@"%.3f", fUpdatedString] doubleValue];
                                    
                                    sum = [fmt numberFromString:[NSString stringWithFormat:@"%.3f", fUpdatedString]];
                                    
                                    decNum = [decNum decimalNumberByAdding:[NSDecimalNumber decimalNumberWithDecimal:[sum decimalValue]]];
                                    
                                }
                                else {
                                    
                                    sumOfInput += [[NSString stringWithFormat:@"%.3f", [textField.text doubleValue] / 100] doubleValue];
                                    
                                    sum = [fmt numberFromString:[NSString stringWithFormat:@"%.3f", [textField.text doubleValue] / 100]];
                                    
                                    decNum = [decNum decimalNumberByAdding:[NSDecimalNumber decimalNumberWithDecimal:[sum decimalValue]]];
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                    //Check if sum of input boxes > 100%
                    if ([decNum doubleValue] > 1) {
                        
                        [self showAlertWithMessage:[NSString stringWithFormat:@"Sum of %% of revenues/costs can not be more than 100%%."]];
                        
                        //Reset the value to previous value
                        double fDefaultValue = [[[PlistData getValue] valueForKey:i2iControl.uid] doubleValue];
                        accessoryTf.text = [self setNumberFormat:[NSString stringWithFormat:@"%.3f", fDefaultValue]
                                              withFormatCategory:i2iControl.category
                                                      withFormat:i2iControl.format];
                        isValidInput = NO;
                        [accessoryTf resignFirstResponder];
                        [activeInputBox resignFirstResponder];
                        
                    }
                    else {
                        
                        //Save the value of sumOfInput in Plist for key = Input351 (by removing the last digit from control uid)
                        NSString *uid = i2iControl.uid;
                        uid = [uid substringToIndex:uid.length - 1];
                        [PlistData setValue:[NSString stringWithFormat:@"%.3f", sumOfInput]
                               keyForSlider:uid];
                        [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3f", sumOfInput]]
                                   forKey:uid];
                        
                        [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3f",fUpdatedString]]
                                   forKey:i2iControl.uid];
                        [PlistData setValue:[NSString stringWithFormat:@"%.3f",fUpdatedString]
                               keyForSlider:i2iControl.uid];
                        if ([activeInputBox.text isEqualToString:@""]) accessoryTf.text = activeInputBox.text;
                        activeInputBox.text = [[self setNumberFormat:[NSString stringWithFormat:@"%.3f", fUpdatedString]
                                                  withFormatCategory:i2iControl.category
                                                          withFormat:i2iControl.format] mutableCopy];
                        accessoryTf.text = activeInputBox.text;
                        
                        isValidInput = YES;
                        [accessoryTf selectAll:nil];
                        [accessoryTf resignFirstResponder];
                        [activeInputBox resignFirstResponder];
                        
                        if ([decNum doubleValue] == 1)
                            i2iTableView.sectionFooterHeight = 0.1f;
                        
                    }
                    
                }
                else {
                    
                    [self showAlertWithMessage:[NSString stringWithFormat:@"Please enter value within %d%@ to %d%@", [i2iControl.min intValue] * 100, @"%%", [i2iControl.max intValue] * 100, @"%%"]];
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
        objControls.defaultCV = [NSString stringWithFormat:@"%.3f", [objControls.defaultCV floatValue] / 100];
        [PlistData setValue:objControls.defaultCV
               keyForSlider:[NSString stringWithFormat:@"%@", objControls.uid]];
        
    }
    else {
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:objControls.defaultCV];
        if (number == nil) {
            
            objControls.defaultCV = [[eval evaluateFormula:objControls.defaultCV
                                            withDictionary:[PlistData getValue]] stringValue];
            [PlistData setValue:objControls.defaultCV
                   keyForSlider:[NSString stringWithFormat:@"%@", objControls.uid]];
            
        }
        else objControls.defaultCV = [[PlistData getValue] valueForKey:objControls.uid];
        
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
        
        if ([lblTemp.key containsString:@"suffixText"]) [lblTarget setText:strCalcValue];
        else [lblTarget setText:[self setNumberFormat:strCalcValue
                                   withFormatCategory:lblTemp.category
                                           withFormat:lblTemp.format]];
        
    }
    
}

-(void)updateInternalLabels {
    
    for (int i = 0; i < internalLabelInstances.count; i++) {
        
        I2IDynamicLabel *lblTemp = [internalLabelInstances objectAtIndex:i];
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
        else strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:lblTemp.formula
                                                                     withDictionary:metrics]];
        
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d", @"-777", i] integerValue];
        //-999 is tag for Dynamic label
        UILabel *lblTarget = (UILabel *)[self viewWithTag:intTag];
        
        if ([lblTemp.key hasPrefix:@"sft"]) {
            
            [lblTarget setText:[metrics objectForKey:str]];
            
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
    
    if (intRemoveButton == 1) return 25.0f;
    else return 0.1f;
    
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    /*UIView *footerView = [[UIView alloc] init];
    if (intRemoveButton == 1) {
        
        if (intCurrentRows < intMaxRows) {
            
            UIButton *addCurrency = [UIButton buttonWithType:UIButtonTypeCustom];
            [addCurrency addTarget:self
                            action:@selector(addItem:)
                  forControlEvents:UIControlEventTouchUpInside];
            [addCurrency setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            addCurrency.frame = CGRectMake(10, 0, 25, 25);
            [addCurrency setBackgroundImage:[UIImage imageNamed:@"AddFCY.png"]
                                   forState:UIControlStateNormal];
            [footerView addSubview:addCurrency];
            
        }
        
    }
    [self updateInternalLabels];
    [self updateLabels];
    return footerView;*/
    
    UIView *footerView = [[UIView alloc] init];
    if (intRemoveButton == 1) {
        
        if (intCurrentRows < intMaxRows) {
            
            double sumOfInputValues = 0.0;
            for (I2IControls *control in internalControls) {
                
                if (control.type == 2) sumOfInputValues = [[metrics valueForKey:[control.uid substringToIndex:control.uid.length - 1]] doubleValue];
                
            }
            
            if (sumOfInputValues < 1) {
                UIButton *addCurrency = [UIButton buttonWithType:UIButtonTypeCustom];
                [addCurrency addTarget:self
                                action:@selector(addItem:)
                      forControlEvents:UIControlEventTouchUpInside];
                [addCurrency setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                addCurrency.frame = CGRectMake(10, 0, 25, 25);
                [addCurrency setBackgroundImage:[UIImage imageNamed:@"AddFCY.png"]
                                       forState:UIControlStateNormal];
                [footerView addSubview:addCurrency];
            }
            
        }
        
    }
    [self updateInternalLabels];
    [self updateLabels];
    return footerView;
    
}

#pragma mark - UITableView DataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int intPreviousRows = [[[PlistData getValue] valueForKey:i2iTableID] intValue];
    if (intPreviousRows < intCurrentRows) [PlistData setValue:@"0"
                                                 keyForSlider:[NSString stringWithFormat:@"Flag%@", i2iTableID]];
    [PlistData setValue:[NSString stringWithFormat:@"%d", (int)intCurrentRows]
           keyForSlider:i2iTableID];
    return intCurrentRows;
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"portCell"];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"portCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    else for (UIView *subview in [cell.contentView subviews]) [subview removeFromSuperview];
    
    for (I2IControls *i2iControl in internalControls) {
        
        I2IControls *newControl = [[I2IControls alloc] init];
        newControl.uid = [i2iControl.uid stringByReplacingOccurrencesOfString:@"x"
                                                                   withString:[NSString stringWithFormat:@"%d", (int)indexPath.row]];
        newControl.defaultCV = [i2iControl.defaultCV stringByReplacingOccurrencesOfString:@"x"
                                                                               withString:[NSString stringWithFormat:@"%d", (int)indexPath.row]];
        newControl.type = i2iControl.type;
        newControl.min = i2iControl.min;
        newControl.max = i2iControl.max;
        newControl.step = i2iControl.step;
        newControl.suffix = i2iControl.suffix;
        newControl.position = i2iControl.position;
        newControl.fFace = i2iControl.fFace;
        newControl.fSize = i2iControl.fSize;
        newControl.colors = i2iControl.colors;
        newControl.category = i2iControl.category;
        newControl.format = i2iControl.format;
        newControl.align = i2iControl.align;
        
        [self setDefaultValues:newControl];
        [internalControlInstances addObject:newControl];
        [cell.contentView addSubview:[self renderControl:newControl]];
        
    }
    
    int i = 0;
    for (I2IDynamicLabel *i2iLabel in internalLabels) {
        
        I2IDynamicLabel *newLabel = [[I2IDynamicLabel alloc] init];
        newLabel.key = [i2iLabel.key stringByReplacingOccurrencesOfString:@"x"
                                                               withString:[NSString stringWithFormat:@"%d", (int)indexPath.row]];
        newLabel.formula = [i2iLabel.formula stringByReplacingOccurrencesOfString:@"x"
                                                                       withString:[NSString stringWithFormat:@"%d", (int)indexPath.row]];
        newLabel.fFace = i2iLabel.fFace;
        newLabel.fBold = i2iLabel.fBold;
        newLabel.fItalic = i2iLabel.fItalic;
        newLabel.fUnderline = i2iLabel.fUnderline;
        newLabel.fSize = i2iLabel.fSize;
        newLabel.fColor = i2iLabel.fColor;
        newLabel.align = i2iLabel.align;
        newLabel.wrap = i2iLabel.wrap;
        newLabel.category = i2iLabel.category;
        newLabel.format = i2iLabel.format;
        newLabel.leftPad = i2iLabel.leftPad;
        newLabel.rightPad = i2iLabel.rightPad;
        newLabel.topPad = i2iLabel.topPad;
        newLabel.bottomPad = i2iLabel.bottomPad;
        newLabel.position = i2iLabel.position;
        
        NSArray *arrPosition = [[NSArray alloc] initWithArray:[newLabel.position componentsSeparatedByString:@","]];
        CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
        
        // -999<i> is tag for Dynamic label.
        NSInteger intTag = [[NSString stringWithFormat:@"%@%d", @"-777", (int)indexPath.row * intInternalLabels + i] integerValue];
    
        [internalLabelInstances addObject:newLabel];
        [cell.contentView addSubview:[newLabel initializeLabel:frameRect withTag:intTag]];
        i++;
        
    }
    
    if ((intRemoveButton == 1) && (intCurrentRows == indexPath.row + 1) && intCurrentRows != 1) {
        
        UIButton *btnRemove = [UIButton buttonWithType:UIButtonTypeCustom];
        btnRemove.frame = CGRectMake(tableView.frame.size.width - 35, 10, 25, 25);
        btnRemove.tag =  indexPath.row;
        [btnRemove addTarget:self
                      action:@selector(removeItem:)
            forControlEvents:UIControlEventTouchUpInside];
        btnRemove.userInteractionEnabled = YES;
        [btnRemove setBackgroundImage:[UIImage imageNamed:@"RemoveFCY.png"]
                             forState:UIControlStateNormal];
        [cell.contentView addSubview:btnRemove];
        
    }
        
    [self updateInternalLabels];
    [self updateLabels];
    
    return cell;

}

#pragma mark - UIPickerView DataSource
// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
    
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return [itemListCodes count];
    
}


#pragma mark - UIPickerView Delegate
-(NSAttributedString *)pickerView:(UIPickerView *)pickerView
            attributedTitleForRow:(NSInteger)row
                     forComponent:(NSInteger)component {
    
    NSMutableString *itemTitle = [[NSMutableString alloc] initWithString:[itemListCodes objectAtIndex:row]];
    [itemTitle appendString:@" - "];
    [itemTitle appendString:[itemListDescriptions objectAtIndex:row]];
    
    NSAttributedString *itemAttrTitle = [[NSAttributedString alloc] initWithString:itemTitle attributes:@{NSForegroundColorAttributeName:[pickerViewControl.colors objectAtIndex:1]}];
    return itemAttrTitle;
    
}

// Display each row's data.
/*-(NSString *)pickerView:(UIPickerView *)pickerView
            titleForRow:(NSInteger)row
           forComponent:(NSInteger)component {
    
    NSMutableString *itemTitle = [[NSMutableString alloc] initWithString:[itemListCodes objectAtIndex:row]];
    [itemTitle appendString:@" - "];
    [itemTitle appendString:[itemListDescriptions objectAtIndex:row]];
    return [itemTitle mutableCopy];
    
}*/

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView
     didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component {
    
    pickedItemIndex = (NSInteger)row;
    
}

#pragma mark - Toolbar Buttons

-(void)pickerDone:(id)sender {
    
    NSMutableAttributedString *btnPopItem = [[NSMutableAttributedString alloc] initWithAttributedString:activePopButton.currentAttributedTitle];
    [btnPopItem.mutableString setString:[itemListCodes objectAtIndex:pickedItemIndex]];
    
    [activePopButton setAttributedTitle:btnPopItem
                               forState:UIControlStateNormal];
    
    NSString *activePopKey = [[@(activePopButton.tag) stringValue] stringByReplacingOccurrencesOfString:@"888" withString:@"Pop"];
    [PlistData setValue:[NSString stringWithFormat:@"%d", (int)pickedItemIndex]
           keyForSlider:activePopKey];
    [metrics setObject:[NSNumber numberWithInt:(int)pickedItemIndex]
                forKey:activePopKey];
    
    [PlistData setValue:[itemListCodes objectAtIndex:pickedItemIndex]
           keyForSlider:[NSString stringWithFormat:@"sft%@", activePopKey]];
    [metrics setValue:[itemListCodes objectAtIndex:pickedItemIndex]
               forKey:[NSString stringWithFormat:@"sft%@", activePopKey]];
    
    NSString *selectedCurrency = [itemListCodes objectAtIndex:pickedItemIndex];
    int selectionRowIndex = 0;
    if ([selectedCurrency isEqualToString:@"PFX"]
        || [selectedCurrency isEqualToString:@"OC1"]
        || [selectedCurrency isEqualToString:@"OC2"]) selectedCurrency = [[PlistData getValue] objectForKey:@"sftLCY"];
    
    for (int x = 0; x < dataModel.columnCount; x++) {
        
        NSString *rowCurrency = [[[dataModel arrayWithHeaderValueOfWholeRowByAxisType:COLUMN_AXIS
                                                                          andRowIndex:x] objectAtIndex:0] rawValue];
        if ([selectedCurrency isEqualToString:rowCurrency]) {
            
            selectionRowIndex = x;
            break;
            
        }
        
    }
    NSString *dependentMoveID = [[[activePopKey substringToIndex:activePopKey.length - 2] stringByAppendingString:@"3"] stringByAppendingString:[activePopKey substringFromIndex:activePopKey.length - 1]];
    [PlistData removeKey:[dependentMoveID stringByReplacingOccurrencesOfString:@"Pop"
                                                                    withString:@"Input"]];
    [PlistData removeKey:[dependentMoveID stringByReplacingOccurrencesOfString:@"Pop"
                                                                    withString:@"Slider"]];
    
    for (int i = 0; i < intVariablesToSave; i++) {
        
        NSMutableArray *row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                      andRowIndex:i + intFirstVariableIndex];
        NSString *variableKey = [[row objectAtIndex:0] headerValue];
        variableKey = [variableKey stringByReplacingOccurrencesOfString:@"x"
                                                             withString:[activePopKey substringFromIndex:activePopKey.length - 1]];
        NSString *variableValue = [NSString stringWithFormat:@"%f", [[[row objectAtIndex:selectionRowIndex + 1] rawValue] doubleValue]];
        
        [PlistData setValue:variableValue
               keyForSlider:variableKey];
        
    }
    
    itemPicker.hidden = TRUE;
    [itemPicker resignFirstResponder];
    
}

-(void)pickerCancel:(id)sender {
    
    itemPicker.hidden = TRUE;
    [itemPicker resignFirstResponder];
    
}

-(void)addItem:(id)sender {
    
    intCurrentRows++;
    [internalControlInstances removeAllObjects];
    [internalLabelInstances removeAllObjects];
    [i2iTableView reloadData];
    [self updateInternalLabels];
    [self updateLabels];
    
}

-(void)removeItem:(id)sender {
    
    UIButton *btnRemove = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:btnRemove.tag inSection:0];
    
    int selectionRowIndex = 0;
    
    for (int x = 0; x < dataModel.columnCount; x++) {
        
        NSMutableArray *row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:COLUMN_AXIS
                                                                      andRowIndex:x];
        NSString *rowCurrency = [[row objectAtIndex:0] rawValue];
        
        if ([rowCurrency isEqualToString:@"USD"]) {
            
            selectionRowIndex = x;
            break;
            
        }
        
    }
    
    int k = 0;
    for (I2IControls *i2iControl in internalControls) {
        
        NSString *targetID = [i2iControl.uid stringByReplacingOccurrencesOfString:@"x"
                                                                       withString:[NSString stringWithFormat:@"%d", (int)btnRemove.tag]];
        NSString *dependentMoveID = [[[targetID substringToIndex:targetID.length - 2] stringByAppendingString:@"3"] stringByAppendingString:[targetID substringFromIndex:targetID.length - 1]];
        [PlistData removeKey:dependentMoveID];
        [PlistData removeKey:[dependentMoveID stringByReplacingOccurrencesOfString:@"Input"
                                                                        withString:@"Slider"]];
        double sumOfInputValues = 0.0;
        double inputValue = [[metrics valueForKey:targetID] doubleValue];
        if (i2iControl.type == 2) {
            
            sumOfInputValues = [[metrics valueForKey:[targetID substringToIndex:targetID.length - 1]] doubleValue];
            sumOfInputValues -= inputValue;
            
            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.3f", sumOfInputValues]]
                       forKey:[targetID substringToIndex:targetID.length - 1]];
            [PlistData setValue:[NSString stringWithFormat:@"%.3f", sumOfInputValues]
                   keyForSlider:[targetID substringToIndex:targetID.length - 1]];
            
            for (int i = 0; i < intVariablesToSave; i++) {
                
                NSMutableArray *row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                              andRowIndex:i + intFirstVariableIndex];
                NSString *variableKey = [[row objectAtIndex:0] headerValue];
                variableKey = [variableKey stringByReplacingOccurrencesOfString:@"x"
                                                                     withString:[NSString stringWithFormat:@"%d", (int)btnRemove.tag]];
                NSString *variableValue = [NSString stringWithFormat:@"%f", [[[row objectAtIndex:selectionRowIndex + 1] rawValue] doubleValue]];
                
                [PlistData setValue:variableValue
                       keyForSlider:variableKey];
                
            }
            
        }
        else {
            
            [PlistData setValue:[itemListCodes objectAtIndex:0]
                   keyForSlider:[NSString stringWithFormat:@"sft%@", targetID]];
            [metrics setValue:[itemListCodes objectAtIndex:0]
                       forKey:[NSString stringWithFormat:@"sft%@", targetID]];
            
        }
        
        [metrics setValue:[NSDecimalNumber numberWithInt:0]
                   forKey:targetID];
        [PlistData setValue:@"0"
               keyForSlider:targetID];
        
        k++;
        
    }
    
    [internalControlInstances removeAllObjects];
    [internalLabelInstances removeAllObjects];
    
    intCurrentRows -= 1;
    [i2iTableView beginUpdates];
    [i2iTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    [i2iTableView reloadData];
    [i2iTableView endUpdates];
    
    [self updateInternalLabels];
    [self updateLabels];
    
}

@end
