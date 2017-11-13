//
//  I2IGraphH.mm
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 30/12/14.
//  Created by Neha Salankar on 06/05/16.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import "I2IGraphH.h"

@implementation I2IGraphH

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander withProps:(NSString*)_props {
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    if(self){
        metrics = [[NSMutableDictionary alloc] init];
        graph = [[I2IBarPlotH alloc] init];
        graph.xMin = (double)0.0;
        graph.xMax = (double)0.0;
        [self getSliderValues];
        eval = [[FormulaEvaluator alloc] init];
        // Initialize all widget's subviews as well as any instance variable
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
    [self addSubview:[self renderWidgetContainer:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)]];
    
    // CGrect offset to account for graph title and subtitles position
    CGRect graphFrame;
    if ([graph.type isEqualToString:@"x"]) {
        graphFrame = CGRectMake(10, 20, self.frame.size.width-20, self.frame.size.height-20);
    }
    else {
        int intSubsDisplayed = 1;
        for (int i = 0; i < graph.bars - 1; i++) {
            if (![[subtitles objectAtIndex:i] isEqualToString:@"-1"]) {
                intSubsDisplayed++;
            }
        }
        graphFrame = CGRectMake(10, ((20*intSubsDisplayed)+(2*(intSubsDisplayed-1))), self.frame.size.width-20, self.frame.size.height-((20*intSubsDisplayed)+(2*(intSubsDisplayed-1))));
    }
    hostView = [[UIView alloc] initWithFrame:graphFrame];
    [graph renderChart:hostView identifier:[NSString stringWithFormat:@"%d", graph.gID]];
    [self addSubview:hostView];
}

// Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    //  Update the widget's data
    [self.widgetHelper reInitDataModels];
    [self readConstants];
    [self readDataValues];
    [self readFormattingInfo];
    [self readFormulae];
}

#pragma mark Data Retrieval Methods
-(void)readConstants {
    // Keep a reference to the grid's data
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader = [current objectAtIndex:0];
    
    // Always expect first metric to be the graph ID
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    graph.type = [metricValue.rawValue substringToIndex:1];
    graph.gID = [[metricValue.rawValue substringFromIndex:1] intValue];
    
    // Always expect second metric to be number of bars to be displayed
    metricValue = [metricHeader.elements objectAtIndex:1];
    graph.bars = [metricValue.rawValue intValue];
    
    // Always expect third metric to be the graph title
    metricValue = [metricHeader.elements objectAtIndex:2];
    title = metricValue.rawValue;
    
    // Always expect fourth metric to be the x-axis label
    metricValue = [metricHeader.elements objectAtIndex:3];
    graph.xLabel = metricValue.rawValue;
    
    graph.yLabels = [[NSMutableArray alloc] init];
    int yLabelLength = 0;
    for (int i = 0; i < graph.bars; i++) {
        // Offset the y-axis labels by 4 to account for the order of metrics in the grids
        // The loop run graphData.Bars times, so that as many labels can be expected
        metricValue = [metricHeader.elements objectAtIndex:i+4];
        if ([graph.type isEqualToString:@"x"]) {
            [graph.yLabels addObject:[NSString stringWithFormat:@"%d",i]];
        }
        else{
            [graph.yLabels addObject:metricValue.rawValue];
            if (metricValue.rawValue.length > yLabelLength) {
                yLabelLength = (int)metricValue.rawValue.length;
                graph.yLongest = [[NSString alloc] initWithString:metricValue.rawValue];
            }
        }
    }
    if (yLabelLength == 0) {
        graph.yLongest = [NSString stringWithFormat:@"0"];
    }
    
    // Always expect 4 + graphData.Bars metric to be the start of subtitle array
    subtitles = [[NSMutableArray alloc] init];
    if (![graph.type isEqualToString:@"x"]) {
        for (int j = 0; j < graph.bars - 1; j++) {
            // Offset the y-axis labels by 4 to account for the order of metrics in the grids
            // The loop run graphData.Bars less one times, so that as many labels can be expected
            metricValue = [metricHeader.elements objectAtIndex:j+4+graph.bars];
            // If this value is -1 then the subtitle would be hidden. Logic is implemented in subsequent methods that use this array.
            [subtitles addObject:metricValue.rawValue];
        }
    }
}
-(void)readDataValues {
    
    int metricCount = (int)[self.modelData metricCount];
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    
    // Populate the primary data array. Size is equal to number of bars to be displayed i.e. graphData.Bars
    graph.dataForPlot = [[NSMutableArray alloc] init];
    for (int i = 0; i < graph.bars; i++){
        int intIndex = 0;
        intIndex =  i+3+graph.bars*2;

        MSIMetricValue *metricValue =[metricHeader.elements objectAtIndex:intIndex];
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *myNumber = [f numberFromString:metricValue.rawValue];
        
        if ([graph.xLabel isEqualToString:@"%"]) {
            myNumber = [NSNumber numberWithFloat:[myNumber floatValue] * 100.0f] ;
        }
        if (i == 0) {
            if ([myNumber doubleValue] >= graph.xMax) {
                graph.xMax = [myNumber doubleValue];
            }
            if ([myNumber doubleValue] <= graph.xMin) {
                graph.xMin = [myNumber doubleValue];
            }
        }
        SChartDataPoint *dataPoint = [[SChartDataPoint alloc] init];
        dataPoint.xValue = myNumber;
        dataPoint.yValue = graph.yLabels[i];
        [graph.dataForPlot addObject:dataPoint];
    }
    
    if (![graph.type isEqualToString:@"x"]){
        // Populate the subtitle data array. Size is equal to number of subtitles to be displayed less one i.e. arrSubtitles.count-1
        subtitleData = [[NSMutableArray alloc] init];
        for (int i = 0;i < graph.bars - 1; i++){
            if ([[subtitles objectAtIndex:i] isEqualToString:@"-1"]) {
                [subtitleData addObject:[subtitles objectAtIndex:i]];
            }
            else {
                MSIMetricValue *metricValue =[metricHeader.elements objectAtIndex:i + 3 + graph.bars * 3];
                [subtitleData addObject:metricValue.rawValue];
            }
        }
    }
    
    int intStart = 0;
    if ([graph.type isEqualToString:@"x"]) {
        intStart = graph.bars * 3 + 3;
    }
    else {
        intStart = graph.bars * 6;
    }
    for (int i = intStart; i < metricCount; i++) {
        MSIMetricValue *metricValue =[metricHeader.elements objectAtIndex:i];
        MSIHeaderValue *value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i] objectAtIndex:0];
        [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",metricValue.rawValue]] forKey:value.headerValue];
    }
}
-(void)readFormattingInfo {
    // Keep a reference to the grid's data
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    graph.colors = [[NSMutableArray alloc] init];
    
    // 2 - Get the color, font face and font size for the graph title
    MSIHeaderValue *value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:2] objectAtIndex:1];
    MSIPropertyGroup *propertyGroup = value.format;
    [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    graph.fFace = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingName];
    fsTitle = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
    
    // 3 - Get the color and font size for the axis and data labels
    value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:3] objectAtIndex:1];
    propertyGroup = value.format;
    [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    graph.fSize = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
    
    // 4 to (3+intNoOFBars) - Populate the bar colors in the array. Size is equal to number of bars to be displayed  i.e. graphData.Bars
    for (int i = 0; i < graph.bars; i++){
        value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+4] objectAtIndex:1];
        propertyGroup = value.format;
        [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    }
    
    
    // Populate the subtitle colors in the array. Size is equal to number of bars to be displayed less one i.e. Bars-1
    if (![graph.type isEqualToString:@"x"]) {
        for (int i = 0; i < graph.bars - 1; i++) {
            value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+4+graph.bars] objectAtIndex:1];
            propertyGroup = value.format;
            [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
            fsSubTitle = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
        }
    }
    
}
-(void)readFormulae {
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    NSString *calcValue = @"";
    
    // Populate the Primary Data array by calculating the formulae.
    for (int i = 1; i < graph.bars; i++) {
        int intIndex = 0;
        if ([graph.type isEqualToString:@"x"]) {
            intIndex = i+4+graph.bars*2;
        }
        else {
            intIndex = i+1+graph.bars*4;
        }
        MSIMetricValue *metricValue =[metricHeader.elements objectAtIndex:intIndex];
        NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:intIndex];
        MSIHeaderValue *attributeCell = [row objectAtIndex:0];
        SChartDataPoint *dataPoint = [graph.dataForPlot objectAtIndex:i];
        if ([[NSString stringWithFormat:@"%@",dataPoint.xValue] floatValue] != 0.0f) {
            calcValue = [self handleFormulae:[metricValue.rawValue mutableCopy] storeKey:attributeCell.headerValue];
            if ([graph.xLabel isEqualToString:@"%"]) {
                calcValue = [NSString stringWithFormat:@"%f",[calcValue floatValue] * 100.0f];
            }
            SChartDataPoint *dataPoint = [[SChartDataPoint alloc] init];
            if ([calcValue doubleValue] >= graph.xMax) {
                graph.xMax = [calcValue doubleValue];
            }
            if ([calcValue doubleValue] <= graph.xMin) {
                graph.xMin = [calcValue doubleValue];
            }
            dataPoint.xValue = [NSNumber numberWithDouble:[calcValue doubleValue]];
            dataPoint.yValue = graph.yLabels[i];
            [graph.dataForPlot replaceObjectAtIndex:i withObject:dataPoint];
        }
    }
    
    // Populate the subtitle data array. Size is equal to number of subtitles to be displayed less one i.e. arrSubtiles.count-1
    if (![graph.type isEqualToString:@"x"]) {
        for (int i = 0; i < graph.bars - 1; i++) {
            MSIMetricValue *metricValue =[metricHeader.elements objectAtIndex:i+1+graph.bars*5];
            NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+1+graph.bars*5];
            MSIHeaderValue *attributeCell = [row objectAtIndex:0];
            if ([[subtitleData objectAtIndex:i] floatValue] != 0.0f) {
                if ([[subtitles objectAtIndex:i] isEqualToString:@"-1"]) {
                    [subtitleData replaceObjectAtIndex:i withObject:[subtitles objectAtIndex:i]];
                }
                else {
                    calcValue = [self handleFormulae:[metricValue.rawValue mutableCopy] storeKey:attributeCell.headerValue];
                    [subtitleData replaceObjectAtIndex:i withObject:calcValue];
                }
                
            }
        }
    }
}

#pragma mark -
#pragma mark handleEvent Methods
// When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    [self cleanViews];
    [metrics removeAllObjects];
    [self recreateWidget];
}

#pragma mark Render Widget Container
-(UIView *)renderWidgetContainer:(CGRect)frameRect {
    UIView *uivContainer = [[UIView alloc] initWithFrame:frameRect];
    
    // Remove any hardcoding later. Values & properties should be from the data dictionary object
    // Make hieght dynamic based on font size or the hieght of cell
    UILabel *graphTitle =[self createLableWithFrame:CGRectMake(0, 0, frameRect.size.width, 16) text:title textColor:[graph.colors objectAtIndex:0] font:[UIFont fontWithName:graph.fFace size:[fsTitle intValue]] align:NSTextAlignmentCenter];
    
    [uivContainer addSubview:graphTitle];
    
    int intSubsDisplayed = 0;
    
    if (![graph.type isEqualToString:@"x"]){
        //*********** Loop here for multiple sub-titles ************
        for (int i = 0; i < graph.bars - 1; i++) {
            if (![[subtitles objectAtIndex:i] isEqualToString:@"-1"]) {
                NSMutableAttributedString *atrString = [[NSMutableAttributedString alloc] initWithString:@""];
                
                NSDictionary *dictTitleAttr = [[NSDictionary alloc] initWithObjectsAndKeys: [UIFont fontWithName:graph.fFace size:[fsSubTitle intValue]], NSFontAttributeName, [graph.colors objectAtIndex:2+graph.bars], NSForegroundColorAttributeName, nil];
                
                NSAttributedString *word = [[NSAttributedString alloc] initWithString:[subtitles objectAtIndex:i] attributes:dictTitleAttr];
                
                [atrString appendAttributedString:word];
                
                NSDictionary *dictValueAttr = [[NSDictionary alloc] initWithObjectsAndKeys: [UIFont fontWithName:graph.fFace size:[fsSubTitle intValue]], NSFontAttributeName, [graph.colors objectAtIndex:1], NSForegroundColorAttributeName, nil];
                
                word = [[NSAttributedString alloc] initWithString:@" " attributes:dictValueAttr];
                
                [atrString appendAttributedString:word];
                NSNumberFormatter *numFormat = [[NSNumberFormatter alloc] init];
                numFormat.numberStyle = NSNumberFormatterPercentStyle;
                numFormat.positiveFormat = @"#0.0%";
                [numFormat setMaximumFractionDigits:1];
                
                word = [[NSAttributedString alloc] initWithString:[numFormat stringFromNumber:[NSNumber numberWithFloat:[subtitleData[i] floatValue]]] attributes:dictValueAttr];
                
                if (roundf([subtitleData[i] floatValue]*10000) == 0) {
                    word = [[NSAttributedString alloc] initWithString:[numFormat stringFromNumber:[NSNumber numberWithFloat:0.0f]] attributes:dictValueAttr];
                }
                
                [atrString appendAttributedString:word];
                
                UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, (intSubsDisplayed+1)*17, frameRect.size.width, 15)];
                subTitle.attributedText = atrString;
                subTitle.textAlignment = NSTextAlignmentCenter;
                
                [uivContainer addSubview:subTitle];
                intSubsDisplayed++;
            }
        }
        //***********************************************************
    }
    return uivContainer;
}

#pragma mark Creating formatted labels
-(UILabel *)createLableWithFrame:(CGRect)frmLabel text:(NSString *)txtLabel textColor:(UIColor *)clrLabel font:(UIFont *)fLabel align:(NSTextAlignment)txtAlignment {
    UILabel *uiLabel = [[UILabel alloc] initWithFrame:frmLabel];
    uiLabel.font = fLabel;
    uiLabel.text = txtLabel;
    uiLabel.textAlignment = txtAlignment;
    uiLabel.textColor = clrLabel;
    uiLabel.numberOfLines = 0;
    uiLabel.lineBreakMode = NSLineBreakByWordWrapping;
    return uiLabel;
}
-(void)getSliderValues {
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
}
#pragma mark Converts BGR value to UIColor object
-(UIColor *)colorConvertor:(NSString *)strColor {
    //  We got B G R here, but we need RGB
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF)/255.0f green:((bgrValue & 0xFF00)>>8)/255.0f blue:((bgrValue & 0xFF0000) >> 16)/255.0f alpha:1.0f];
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
