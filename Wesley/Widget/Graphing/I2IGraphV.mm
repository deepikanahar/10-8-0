//
//  I2IGraphV.mm
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 30/12/14.
//  Created by Neha Salankar on 06/05/16.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import "I2IGraphV.h"

@implementation I2IGraphV

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander withProps:(NSString*)_props {
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    if(self) {
        metrics = [[NSMutableDictionary alloc] init];
        graph = [[I2IColumnPlotV alloc] init];
        graph.yMin = (double)0.0;
        graph.yMax = (double)0.0;
        [self getSliderValues];
        eval = [[FormulaEvaluator alloc]init];
        //Initialize all widget's subviews as well as any instance variable
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
    
    //CGrect offset to account for graph title
    CGRect graphFrame = CGRectMake(0, 20, self.frame.size.width-10, self.frame.size.height-20);
    hostView = [[UIView alloc] initWithFrame:graphFrame];
    [graph renderChart:hostView identifier:[NSString stringWithFormat:@"%d", graph.gID]];
    [self addSubview:hostView];
}

//Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    //  Update the widget's data
    [self.widgetHelper reInitDataModels];
    [self readConstants];
    [self readFormattingInfo];
    [self readDataValues];
}

#pragma mark Data Retrieval Methods
-(void)readConstants {
    //Keep a reference to the grid's data
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader = [current objectAtIndex:0];
    
    // Always expect first metric to be the graph ID
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    graph.gID = [metricValue.rawValue intValue];
    
    MSIPropertyGroup *propertyGroup = metricValue.format;
    
    graph.colors = [[NSMutableArray alloc] init];
    
    [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    graph.fFace = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingName];
    graph.fSize = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
    
    // Always expect second metric to be number of columns to be displayed
    metricValue = [metricHeader.elements objectAtIndex:1];
    graph.columns = [metricValue.rawValue intValue];
    
    // Always expect third metric to be the graph title
    metricValue = [metricHeader.elements objectAtIndex:2];
    title = metricValue.rawValue;
}
-(void)readDataValues {
    graph.xLabels = [[NSMutableArray alloc] init];
    graph.dataForPlot = [[NSMutableArray alloc] init];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    // Loop through supporting metrics and add to dictionary
    for (int i = graph.columns + 4; i < current.count; i++){
        NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i];
        
        MSIHeaderValue *header = [row objectAtIndex:0];
        MSIMetricValue *value = [row objectAtIndex:1];
        if ([NSNumber numberWithDouble:[value.rawValue doubleValue]]!=nil) {
            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",value.rawValue]] forKey:header.headerValue];
        }
    }
    
    // Loop through bar metrics headers and fill colors + labels
    for (int i = 0; i < graph.columns; i++) {
        MSIHeaderValue *header = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+4] objectAtIndex:0];
        MSIMetricValue *val = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+4] objectAtIndex:1];
        NSString *calcValue = @"";
        MSIPropertyGroup *propertyGroup = header.format;
        calcValue = [self handleFormulae:[val.rawValue mutableCopy] storeKey:header.headerValue];
        if ([graph.yLabel isEqualToString:@"%"]) {
            calcValue = [NSString stringWithFormat:@"%f",[calcValue floatValue] * 100.0f];
        }
        if ([calcValue doubleValue] >= graph.yMax) {
            graph.yMax = [calcValue doubleValue];
        }
        if ([calcValue doubleValue] <= graph.yMin) {
            graph.yMin = [calcValue doubleValue];
        }
        [graph.xLabels addObject:header.headerValue];
        [graph.dataForPlot addObject:calcValue];
        [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    }
}
-(void)readFormattingInfo {
    //Keep a reference to the grid's data
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    // 2 - Get the color, font face and font size for the graph title
    MSIHeaderValue *value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:2] objectAtIndex:1];
    MSIPropertyGroup *propertyGroup = value.format;
    [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    graph.fFace = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingName];
    fsTitle = [propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingSize];
}

#pragma mark handleEvent Methods
//When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    [self cleanViews];
    [metrics removeAllObjects];
    [self recreateWidget];
}

#pragma mark Render Widget Container
-(UIView *)renderWidgetContainer:(CGRect)frameRect {
    // Make hieght dynamic based on font size or the hieght of cell
    UILabel *graphTitle =[self createLableWithFrame:CGRectMake(0, 0, frameRect.size.width, 15) text:title textColor:[graph.colors objectAtIndex:0] font:[UIFont fontWithName:graph.fFace size:[fsTitle intValue]] align:NSTextAlignmentCenter];
    return graphTitle;
}

#pragma mark Creating formatted labels
-(UILabel *)createLableWithFrame:(CGRect)frmLabel text:(NSString *)txtLabel textColor:(UIColor *)clrLabel font:(UIFont *)fLabel align:(NSTextAlignment)txtAlignment; {
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
    int bgrValue = [strColor intValue]; //  We got B G R here, but we need RGB
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
