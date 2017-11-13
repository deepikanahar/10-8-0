//
//  IntExpenseGraph.mm
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 03/02/15.
//  Created by Neha Salankar on 06/05/16.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import "IntExpenseGraph.h"

@implementation IntExpenseGraph

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander withProps:(NSString*)_props{
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    
    if(self){
        
        metrics = [[NSMutableDictionary alloc] init];
        graph = [[I2IBarPlotIE alloc] init];
        eval = [[FormulaEvaluator alloc]init];
        //  Initialize all widget's subviews as well as any instance variable
        
    }
    return self;
}

//  This method is used to clear all the widget’s views in order to save memory. It is called the first time the widget is loaded, and later if the widget needs to be recreated or deleted.
-(void)cleanViews {
    [metrics removeAllObjects];
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
    
    hostView = [[UIView alloc] initWithFrame:CGRectMake(0, 17, self.frame.size.width, self.frame.size.height-17)];
    [graph renderChart:hostView identifier:[NSString stringWithFormat:@"%d", graph.gID]];
    
    [self addSubview:hostView];
}

//  Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    //  Update the widget's data
    [self.widgetHelper reInitDataModels];
    [self readConstants];
    [self readDataValues];
    [self readFormattingInfo];
    [self readFormulae];
}

#pragma mark Data Retrieval Methods
-(void)readDataValues {
    
    int metricCount = (int)[self.modelData metricCount];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    
    // Populate the primary data array. Size is equal to number of bars to be displayed i.e. graphData.Bars
    graph.dataForPlot = [[NSMutableArray alloc] init];
    for (int i = 0; i < graph.bars; i++){
        MSIMetricValue *metricValue;
        if (graph.bars == 5) {
            metricValue =[metricHeader.elements objectAtIndex:i+7+graph.bars/2];
        }
        else {
            metricValue =[metricHeader.elements objectAtIndex:i+4+graph.bars/2];
        }
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *myNumber = [f numberFromString:metricValue.rawValue];
        
        NSDecimalNumber *decimalNumber = [NSDecimalNumber decimalNumberWithDecimal:[myNumber decimalValue]];
        
        if ([graph.xLabel isEqualToString:@"%"]) {
            decimalNumber = [decimalNumber decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
        }
        [graph.dataForPlot addObject:decimalNumber];
    }
    
    // Write code here to populate the supporting metrics dictionary. Its size is dynamic so looping till end of metric count.
    for (int i = 5 * (3 + (graph.bars / 5)) - 1 + 3 * ((graph.bars / 5) - 1); i < metricCount; i++) {
        MSIMetricValue *metricValue =[metricHeader.elements objectAtIndex:i];
        MSIHeaderValue *value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i] objectAtIndex:0];
        [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",[metricValue rawValue]]] forKey:value.headerValue];
    }
}
-(void)readConstants{
    NSString *percentSign = @"%";
    // Keep a reference to the grid's data
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    
    // Always expect first metric to be the graph ID
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    graph.gID = [metricValue.rawValue intValue];
    
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
    if (graph.bars == 5) {
        for (int i = 0; i < graph.bars; i++) {
            // The loop run graphData.Bars/2 times, so that as many labels can be expected
            metricValue = [metricHeader.elements objectAtIndex:i+4];
            [graph.yLabels addObject:[NSString stringWithFormat:@"%@%@", metricValue.rawValue,percentSign]];
        }
    }
    else{
        for (int i = 0; i < graph.bars/2; i++) {
            // The loop run graphData.Bars/2 times, so that as many labels can be expected
            metricValue = [metricHeader.elements objectAtIndex:i+4];
            [graph.yLabels addObject:[NSString stringWithFormat:@"%@%@", metricValue.rawValue,percentSign]];
            float blablaVal = [metricValue.rawValue floatValue] + 0.5;
            [graph.yLabels addObject:[NSString stringWithFormat:@"%f%@", blablaVal,percentSign]];
        }
    }
    
}
-(void)readFormattingInfo{
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
    
    // 4 - Populate the bar colors in the array. Size is equal to number of bars to be displayed  i.e. graphData.Bars
    for (int i = 0; i < graph.bars; i++){
        value = [[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS andRowIndex:i+9] objectAtIndex:1];
        propertyGroup = value.format;
        [graph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont propertyID:FontFormattingColor]]];
    }
    
}
-(void)readFormulae{
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    NSString *calcValue = @"";
    [self getSliderValues];
    // Populate the Primary Data array by calculating the formulae.
    for (int i = 0; i < graph.bars; i++){
        MSIMetricValue *metricValue =[metricHeader.elements objectAtIndex:i+graph.bars+9];
        if ([[graph.dataForPlot objectAtIndex:i] floatValue] != 0.0f) {
            calcValue = [NSString stringWithFormat:@"%@",[eval evaluateFormula:metricValue.rawValue withDictionary:metrics]];
            if ([graph.xLabel isEqualToString:@"%"]) {
                calcValue = [NSString stringWithFormat:@"%f",[calcValue floatValue] * 100.0f];
            }
            [graph.dataForPlot replaceObjectAtIndex:i withObject:calcValue];
        }
    }
}

#pragma mark -
#pragma mark handleEvent Methods
//  When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    [self cleanViews];
    [self recreateWidget];
}

#pragma mark Render Widget Container
-(UIView *)renderWidgetContainer:(CGRect)frameRect {
    UIView *uivContainer = [[UIView alloc] initWithFrame:frameRect];
    
    UILabel *graphTitle =[self createLableWithFrame:CGRectMake(0, 0, frameRect.size.width, 16) text:[NSString stringWithFormat:@"%@%d years",title,[[[PlistData getValue] valueForKey:@"Input51"] intValue]] textColor:[graph.colors objectAtIndex:0] font:[UIFont fontWithName:graph.fFace size:[fsTitle intValue]] align:NSTextAlignmentCenter];//Don't remove from Dev iOS project
    
    [uivContainer addSubview:graphTitle];
    
    return uivContainer;
}

#pragma mark Creating formatted labels
- (UILabel *)createLableWithFrame:(CGRect)frmLabel text:(NSString *)txtLabel textColor:(UIColor *)clrLabel font:(UIFont *)fLabel align:(NSTextAlignment)txtAlignment {
    UILabel *uiLabel = [[UILabel alloc] initWithFrame:frmLabel];
    uiLabel.font = fLabel;
    uiLabel.text = txtLabel;
    uiLabel.textAlignment=txtAlignment;
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
@end
