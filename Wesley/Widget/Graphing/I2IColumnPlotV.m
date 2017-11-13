//
//  I2IColumnPlotV.m
//  c100Benchmarking
//
//
//  Created by Neha Salankar on 30/12/14.
//  Modified by Pradeep Yadav on 08/12/15.
//  Copyright (c) 2015 i2iLogic Australia Pty Ltd. All rights reserved.
//

#import "I2IColumnPlotV.h"

@implementation CustomColumnSeries
@synthesize arrColors;
-(SChartColumnSeriesStyle*)styleForPoint:(id<SChartData>)point {
    SChartColumnSeriesStyle *newStyle = [super styleForPoint:point];
    newStyle.showArea = YES;
    newStyle.showAreaWithGradient = FALSE;
    newStyle.lineColor = [UIColor clearColor];
    newStyle.lineColorBelowBaseline = [UIColor clearColor];
    newStyle.areaColorGradient = [UIColor clearColor];
    newStyle.areaColor = [arrColors objectAtIndex:[point sChartDataPointIndex]+2];
    newStyle.areaColorBelowBaseline  = [arrColors objectAtIndex:[point sChartDataPointIndex]+2];
    return newStyle;
}
@end

@implementation CustomNumberYAxis
static const char sUnits[] = { '\0', 'M', '?', 'B'};
static int sMaxUnits = sizeof sUnits - 1;
-(NSString *)stringForId:(id)obj {
    int multiplier = 1000;
    int exponent = 0;
    float bytes = [(NSNumber *)obj floatValue];
    while ((fabs(bytes) >= multiplier) && (exponent < sMaxUnits)) {
        bytes /= multiplier;
        exponent++;
    }
    NSString *convertedStr;
    if ([obj floatValue] == 0.0) {
        convertedStr = @"0";
    }
    else if (fabs([obj floatValue]) <= 0.5) {
        if(sUnits[exponent] == '?')
            convertedStr = [NSString stringWithFormat:@"%.2f%@", bytes, @"MM"];
        else
            convertedStr = [NSString stringWithFormat:@"%.2f%c", bytes, sUnits[exponent]];
    }
    else {
        if(sUnits[exponent] == '?')
            convertedStr = [NSString stringWithFormat:@"%.1f%@", bytes, @"MM"];
        else
            convertedStr = [NSString stringWithFormat:@"%.1f%c", bytes, sUnits[exponent]];
    }
    return convertedStr;
}
@end

@implementation I2IColumnPlotV {
    NSMutableArray* dataPointsForSeries;
}

@synthesize dataForPlot;
@synthesize gID;
@synthesize columns;
@synthesize yLabel;
@synthesize xLabels;
@synthesize colors;
@synthesize fSize;
@synthesize fFace;
@synthesize yMin;
@synthesize yMax;
@synthesize formulae;

#define LABEL_IDENTIFIER 5

-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier {
    
    // Create the chart
    vChart = [[ShinobiChart alloc] initWithFrame:CGRectMake(0, 0, hostView.bounds.size.width, hostView.bounds.size.height)];
    
    vChart.autoresizingMask =  ~UIViewAutoresizingFlexibleHeight;
    vChart.backgroundColor = [UIColor clearColor];
    
    // Add x-axis
    SChartCategoryAxis *xAxis = [[SChartCategoryAxis alloc] init];
    [xAxis.style setLineWidth:[NSNumber numberWithInt:1]];
    xAxis.style.lineColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    xAxis.style.titleStyle.font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    xAxis.style.titleStyle.textColor = [colors firstObject];
    xAxis.enableGesturePanning = NO;
    xAxis.enableGestureZooming = NO;
    vChart.xAxis = xAxis;
    vChart.xAxis.axisPositionValue = @0;
    vChart.xAxis.style.interSeriesSetPadding = @(0.5);

    // Add y-axis
    SChartNumberAxis *yAxis = [[SChartNumberAxis alloc] init];
    yAxis = [CustomNumberYAxis new];
    if ([yLabel isEqualToString:@" "] || yLabel == nil) {
        yAxis.title = @"_";
        yAxis.style.titleStyle.textColor = [UIColor clearColor];
    }
    else {
        yAxis.title = yLabel;
        yAxis.style.titleStyle.textColor = [colors firstObject];
    }
    [yAxis.style setLineWidth:[NSNumber numberWithInt:1]];
    yAxis.style.lineColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    yAxis.style.titleStyle.font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    yAxis.enableGesturePanning = NO;
    yAxis.enableGestureZooming = NO;
    if (yMax == 0.0) {
        yAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeTicksAndLabelsPersist;
        yAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeNeitherPersist;
    }
    else if (yMin == 0.0) {
        yAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeNeitherPersist;
        yAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeTicksAndLabelsPersist;
    }
    else {
        yAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeNeitherPersist;
        yAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeNeitherPersist;
    }
    yAxis.autoCalculateRange = YES;
    vChart.yAxis = yAxis;

    [self loadChartData];
    // Adding to the view
    [hostView addSubview:vChart];
    vChart.datasource = self;
    vChart.delegate = self;
    
    // Hiding the legend
    vChart.legend.hidden = YES;
    isInitialRender = YES;
}
-(void)loadChartData {
    dataPointsForSeries = [NSMutableArray new];
    double barValue;
    NSMutableArray *isXLabelEmpty = [[NSMutableArray alloc] init];
    
    for (int barIndex = 0; barIndex < columns; barIndex++) {
        SChartDataPoint *dataPoint = [[SChartDataPoint alloc] init];
        
        if (xLabels[barIndex] == nil || [xLabels[barIndex]  isEqual: @" "]) {
            dataPoint.xValue = @(barIndex);
        }
        else {
            dataPoint.xValue = xLabels[barIndex];
            [isXLabelEmpty addObject:@(barIndex)];
        }
        barValue = [[dataForPlot objectAtIndex:barIndex] doubleValue];
        dataPoint.yValue = [NSNumber numberWithDouble:barValue];
        [dataPointsForSeries addObject:dataPoint];
    }
    
    if (!isXLabelEmpty.count) {
        vChart.xAxis.style.majorTickStyle.showLabels = NO;
    }
}
#pragma mark - SChartDatasource methods
-(NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
    return 1;
}
-(SChartSeries *)sChart:(ShinobiChart *)chart seriesAtIndex:(NSInteger)index {
    CustomColumnSeries *columnSeries = [[CustomColumnSeries alloc] init];
    columnSeries.arrColors = [[NSMutableArray alloc] initWithArray:colors];
    columnSeries.style.dataPointLabelStyle.showLabels = YES;
    columnSeries.style.dataPointLabelStyle.textColor = [colors firstObject];
    columnSeries.style.dataPointLabelStyle.font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    columnSeries.style.dataPointLabelStyle.position = SChartDataPointLabelPositionAboveData;
    columnSeries.style.dataPointLabelStyle.offsetFlippedForNegativeValues = YES;
    columnSeries.animationEnabled = YES;
    columnSeries.entryAnimation.absoluteOriginY = @0;
    return columnSeries;
}
-(NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)seriesIndex {
    return dataForPlot.count;
}
-(id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(NSInteger)dataIndex forSeriesAtIndex:(NSInteger)seriesIndex {
    return dataPointsForSeries[dataIndex];
}
-(void)sChart:(ShinobiChart *)chart alterTickMark:(SChartTickMark *)tickMark beforeAddingToAxis:(SChartAxis *)axis {
    if (axis.isXAxis) {
        if (tickMark.value >= 0 && tickMark.value < dataForPlot.count) {
            if ([[NSString stringWithFormat:@"%@",[dataForPlot objectAtIndex:tickMark.value]] floatValue] < 0) {
                //  To calculate tick label width
                UIFont *font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
                NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
                CGSize textSize = [tickMark.tickLabel.text sizeWithAttributes: userAttributes];
                
                tickMark.tickLabel.frame = CGRectMake(tickMark.tickLabel.frame.origin.x, tickMark.tickLabel.frame.origin.y-tickMark.tickLabel.frame.size.height-20, tickMark.tickLabel.frame.size.width, textSize.height);
            }
        }
    }
    else{
        
        UIFont *font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
        NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                         NSForegroundColorAttributeName: [UIColor whiteColor]};
        CGSize textSize = [tickMark.tickLabel.text sizeWithAttributes: userAttributes];
        tickMark.tickLabel.frame = CGRectMake(tickMark.tickLabel.frame.origin.x, tickMark.tickLabel.frame.origin.y, textSize.width, tickMark.tickLabel.frame.size.height);
    }
}
-(void)sChart:(ShinobiChart *)chart alterDataPointLabel:(SChartDataPointLabel *)label forDataPoint:(SChartDataPoint *)dataPoint inSeries:(SChartSeries *)series {
    
    CGRect newLabelFrame = label.frame;
    
    // The label identifier is used to prevent already customised labels getting customised again.
    if (label.tag != LABEL_IDENTIFIER) {
        label.tag = LABEL_IDENTIFIER;
        
        if ([yLabel isEqualToString:@"%"]) {
            label.text = [NSString stringWithFormat:@"%.2f",[dataPoint.yValue floatValue]];
        }
        else {
            static const char sUnits[] = { '\0', 'M', '?', 'B'};
            static int sMaxUnits = sizeof sUnits - 1;
            int multiplier =  1000;
            int exponent = 0;
            
            float bytes = [dataPoint.yValue floatValue];
            
            while ((fabs(bytes) >= multiplier) && (exponent < sMaxUnits)) {
                bytes /= multiplier;
                exponent++;
            }
            NSString *convertedStr = [[NSString alloc] init];
            if(sUnits[exponent] == '?')
                convertedStr = [NSString stringWithFormat:@"%.2f%@", bytes, @"MM"];
            else
                convertedStr = [[NSString alloc] init];
            if(sUnits[exponent] == '?')
                convertedStr = [NSString stringWithFormat:@"%.2f%@", bytes, @"MM"];
            else
                convertedStr = [[NSString alloc] init];
            
            if(sUnits[exponent] == '?')
                convertedStr = [NSString stringWithFormat:@"%.2f%@", bytes, @"MM"];
            else
                convertedStr = [NSString stringWithFormat:@"%.2f%c", bytes, sUnits[exponent]];
            label.text = convertedStr;
        }
        
        // Calculate the size of the string label with the supplied font, and no existing constraints on size.
        NSDictionary *attributes = @{NSFontAttributeName:label.font};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:label.text attributes:attributes];
        CGFloat labelWidth = [attributedString boundingRectWithSize:CGSizeZero
                                                            options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                            context:nil].size.width;
        // Update label frame's size
        newLabelFrame.size.width = labelWidth;
    }
    
    // We need to reposition the label by updating its origin values.
    if ([dataPoint.yValue floatValue] < 0.0) {
        newLabelFrame.origin.y = newLabelFrame.origin.y + newLabelFrame.size.height;
    }
    else {
        newLabelFrame.origin.y = newLabelFrame.origin.y - newLabelFrame.size.height;
    }
    newLabelFrame.origin.x = CGRectGetMidX(label.frame) - newLabelFrame.size.width / 2;
    label.frame = newLabelFrame;
}
-(void)sChartRenderFinished:(ShinobiChart *)chart {
    if (isInitialRender) {
        double span = [chart.yAxis.dataRange.maximum doubleValue];
        chart.yAxis.rangePaddingHigh = @(span * 0.2);
        [chart redrawChartIncludePlotArea:YES];
        isInitialRender = NO;
    }
}
@end
