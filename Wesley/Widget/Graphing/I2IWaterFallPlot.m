//
//  I2IWaterFallPlot.m
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 28/05/15.
//  Modified by Pradeep Yadav on 09/12/15.
//  Copyright (c) 2015 i2iLogic Australia Pty Ltd. All rights reserved.
//


#import "I2IWaterFallPlot.h"

@implementation CustomNumberXAxisWF
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

@implementation CustomWaterFallSeries
@synthesize arrColors;
@synthesize wfResultColumns;
-(SChartCandlestickSeriesStyle*)styleForPoint:(id<SChartData>)point previousPoint:(id<SChartData>)prevPoint {
    SChartCandlestickSeriesStyle *newStyle = [super styleForPoint:point previousPoint:prevPoint];
    int waterFallBarIndex = (int)[point sChartDataPointIndex];
    
    if (waterFallBarIndex == 0) {
        newStyle.risingColor = [arrColors firstObject];
        newStyle.fallingColor = [arrColors firstObject];
        newStyle.risingColorGradient = [arrColors firstObject];
        newStyle.fallingColorGradient = [arrColors firstObject];
    }
    else if ([wfResultColumns containsObject:[NSString stringWithFormat:@"%d",waterFallBarIndex]]) {
        newStyle.risingColor = [arrColors lastObject];
        newStyle.fallingColor = [arrColors lastObject];
        newStyle.risingColorGradient = [arrColors lastObject];
        newStyle.fallingColorGradient = [arrColors lastObject];
    }
    else {
        newStyle.risingColor = [arrColors objectAtIndex:1];
        newStyle.fallingColor = [arrColors objectAtIndex:2];
        newStyle.risingColorGradient = [arrColors objectAtIndex:1];
        newStyle.fallingColorGradient = [arrColors objectAtIndex:2];
    }
    newStyle.outlineColor = [UIColor clearColor];
    return newStyle;
}
@end

@implementation I2IWaterFallPlot {
    NSMutableArray* dataPointsForSeries;
}

@synthesize dataForPlot;
@synthesize arrXLabels;
@synthesize colors;
@synthesize formulae;
@synthesize arrStops;
@synthesize dataLabels;
@synthesize fFace;
@synthesize fSize;
@synthesize strStopsCounter;

#define LABEL_IDENTIFIER 5
-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier {
    
    // Create the chart
    wfChart = [[ShinobiChart alloc] initWithFrame:CGRectMake(0, 20, hostView.bounds.size.width, hostView.bounds.size.height-20)];
    wfChart.autoresizingMask =  ~UIViewAutoresizingNone;
    wfChart.backgroundColor = [UIColor clearColor];
    
    // Add x-axis
    SChartCategoryAxis *xAxis = [[SChartCategoryAxis alloc] init];
    [xAxis.style setLineWidth:[NSNumber numberWithInt:0]];
    xAxis.style.lineColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    xAxis.enableGesturePanning = NO;
    xAxis.enableGestureZooming = NO;
    xAxis.style.majorTickStyle.tickLabelOrientation = TickLabelOrientationVertical;
    xAxis.style.majorTickStyle.textAlignment = NSTextAlignmentRight;
    xAxis.labelFormatter.formatter = NSLineBreakByWordWrapping;
    xAxis.style.majorTickStyle.tickGap = @(125);
    wfChart.xAxis = xAxis;
    wfChart.xAxis.style.interSeriesSetPadding = @(0.25);
    
    // Add y-axis
    SChartNumberAxis *yAxis = [[SChartNumberAxis alloc] init];
    yAxis = [CustomNumberXAxisWF new];
    [yAxis.style setLineWidth:[NSNumber numberWithInt:1]];
    yAxis.style.lineColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    yAxis.enableGesturePanning = NO;
    yAxis.enableGestureZooming = NO;
    yAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeTicksAndLabelsPersist;
    yAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeTicksAndLabelsPersist;
    yAxis.anchorPoint = @0;
    yAxis.autoCalculateRange = YES;
    wfChart.yAxis = yAxis;
    
    SChartAnnotation *hrLine = [SChartAnnotation horizontalLineAtPosition:@(0.001) withXAxis:wfChart.xAxis andYAxis:wfChart.yAxis withWidth:1.0f withColor:[colors firstObject]];
    [wfChart addAnnotation:hrLine];
    
    if ([[arrStops firstObject] intValue] > 0) {
        for (id object in arrStops) {
            if ([object intValue] < dataForPlot.count - 1) {
                SChartAnnotation *vLine;
                vLine = [SChartAnnotation verticalLineAtPosition:@([object intValue]+0.5) withXAxis:wfChart.xAxis andYAxis:wfChart.yAxis withWidth:1.0f withColor:[UIColor lightGrayColor]];
                [wfChart addAnnotation:vLine];
            }
        }
    }
    
    [self loadChartData];
    // Adding to the view
    [hostView addSubview:wfChart];
    wfChart.datasource = self;
    wfChart.delegate = self;
    
    // Hiding the legend
    wfChart.legend.hidden = YES;
    isInitialRender = YES;
}
-(void)loadChartData {
    dataPointsForSeries = [NSMutableArray new];
    double prevBarClose = 0;
    double prevBarOpen = 0;
    double barOpen = 0;
    double barClose = 0;
    int seriesStart = 0;
    int seriesStop = 0;
    
    // Outer loop is to cover for number of milestones in the waterfall chart
    for (NSString *strStop in arrStops) {
        seriesStop = [strStop intValue];
        
        // Inner loop to cover each bar for the running milestone
        for (int barIndex = seriesStart; barIndex <= seriesStop; barIndex++) {
            barOpen = 0;
            barClose = [[self.dataForPlot objectAtIndex:barIndex] doubleValue];
            if (barIndex == seriesStop) {
                if (barClose == 0) {
                    barClose = 0;
                }
                else {
                    barClose = prevBarClose;
                }
            }
            else {
                barOpen = prevBarClose;
                barClose = barClose + prevBarClose;
            }
            
            SChartMultiYDataPoint *dataPoint = [SChartMultiYDataPoint new];
            dataPoint.xValue = [NSString stringWithFormat:@"%d", barIndex];
            NSDictionary* yValues = @{SChartCandlestickKeyOpen: [NSNumber numberWithDouble:barOpen],
                                      SChartCandlestickKeyHigh: @0,
                                      SChartCandlestickKeyLow: @0,
                                      SChartCandlestickKeyClose: [NSNumber numberWithDouble:barClose]};
            dataPoint.yValues = [NSMutableDictionary dictionaryWithDictionary:yValues];
            dataPoint.yValue = [NSNumber numberWithDouble:barClose];
            [dataPointsForSeries addObject:dataPoint];
            prevBarClose = barClose;
            prevBarOpen = barOpen;
        }
        seriesStart = seriesStop + 1;
        barOpen = 0;
        barClose = 0;
        prevBarOpen = 0;
    }
}
-(void)refreshWaterFallGraph {
    isInitialRender = YES;
    [self loadChartData];
    [wfChart reloadData];
    [wfChart redrawChart];
}

#pragma mark - SChartDatasource methods
-(NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
    return 1;
}
-(SChartSeries *)sChart:(ShinobiChart *)chart seriesAtIndex:(NSInteger)index {
    CustomWaterFallSeries *candleStickSeries = [[CustomWaterFallSeries alloc] init];
    candleStickSeries.wfResultColumns = [[NSMutableArray alloc] initWithArray:arrStops];
    candleStickSeries.arrColors = [[NSMutableArray alloc] init];
    [candleStickSeries.arrColors addObject:colors[1]];
    [candleStickSeries.arrColors addObject:colors[2]];
    [candleStickSeries.arrColors addObject:colors[3]];
    [candleStickSeries.arrColors addObject:colors[4]];
    
    // Don't display sticks in Candle Series
    candleStickSeries.style.stickColor = [UIColor clearColor];
    // format the bars
    candleStickSeries.style.outlineWidth = @0;
    
    // Display and position data Labels
    candleStickSeries.style.dataPointLabelStyle.showLabels = YES;
    candleStickSeries.style.dataPointLabelStyle.font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    candleStickSeries.style.dataPointLabelStyle.textColor = [colors firstObject];
    candleStickSeries.style.dataPointLabelStyle.position = SChartDataPointLabelPositionAboveData;
    candleStickSeries.style.dataPointLabelStyle.offsetFlippedForNegativeValues = YES;
    candleStickSeries.animationEnabled = NO;
    return candleStickSeries;
}
-(NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)seriesIndex {
    return dataPointsForSeries.count;
}

#pragma mark - SChartDelegate methods
-(id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(NSInteger)dataIndex forSeriesAtIndex:(NSInteger)seriesIndex {
    return dataPointsForSeries[dataIndex];
}
-(void)sChart:(ShinobiChart *)chart alterTickMark:(SChartTickMark *)tickMark beforeAddingToAxis:(SChartAxis *)axis {
    if (axis.isXAxis) {
        if (tickMark.value >= 0 && tickMark.value < dataForPlot.count) {
            tickMark.tickLabel.frame = CGRectMake(tickMark.tickLabel.frame.origin.x-(tickMark.tickLabel.frame.size.width/2), tickMark.tickLabel.frame.origin.y-125, tickMark.tickLabel.frame.size.width*2, 125);
            tickMark.tickLabel.text = [arrXLabels objectAtIndex:tickMark.value];
            tickMark.tickLabel.numberOfLines = 2;
            tickMark.tickLabel.lineBreakMode = NSLineBreakByWordWrapping;
        }
    }
    else {
        
        UIFont *font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
        NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                         NSForegroundColorAttributeName: [UIColor whiteColor]};
        CGSize textSize = [tickMark.tickLabel.text sizeWithAttributes: userAttributes];
        
        tickMark.tickLabel.frame = CGRectMake(tickMark.tickLabel.frame.origin.x+tickMark.tickLabel.frame.size.width-textSize.width, tickMark.tickLabel.frame.origin.y, textSize.width, tickMark.tickLabel.frame.size.height);
        tickMark.tickLabel.textAlignment = NSTextAlignmentRight;
    }
}
-(void)sChart:(ShinobiChart *)chart alterDataPointLabel:(SChartDataPointLabel *)label forDataPoint:(SChartDataPoint *)dataPoint inSeries:(CustomWaterFallSeries *)series {
    
    CGRect newLabelFrame = label.frame;
    
    // The label identifier is used to prevent already customised labels getting customised again.
    if (label.tag != LABEL_IDENTIFIER) {
        label.tag = LABEL_IDENTIFIER;
        
        static const char sUnits[] = { '\0', 'M', '?', 'B'};
        static int sMaxUnits = sizeof sUnits - 1;
        int multiplier =  1000;
        int exponent = 0;
        
        float bytes = [[dataForPlot objectAtIndex:dataPoint.index] floatValue];
        
        while ((fabs(bytes) >= multiplier) && (exponent < sMaxUnits)) {
            bytes /= multiplier;
            exponent++;
        }
        NSString *convertedStr = [[NSString alloc] init];
        if(sUnits[exponent] == '?')
            convertedStr = [NSString stringWithFormat:@"%.2f%@", bytes, @"MM"];
        else
        convertedStr = [NSString stringWithFormat:@"%.2f%c", bytes, sUnits[exponent]];
        if (fabs([convertedStr floatValue]) == 0.0f) {
            convertedStr = [NSString stringWithFormat:@"0"];
        }
        label.text = convertedStr;
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
    newLabelFrame.origin.x = CGRectGetMidX(label.frame) - newLabelFrame.size.width/2;
    
    CGFloat yAxisValInPixel = [chart.yAxis pixelValueForDataValue:0];
    
    if ([[dataForPlot objectAtIndex:dataPoint.index] floatValue] >= 0.0) {
        if ((CGRectGetMidY(label.frame) - yAxisValInPixel < 15 && CGRectGetMidY(label.frame) - yAxisValInPixel >= 0)) {
            newLabelFrame.origin.y = CGRectGetMidY(label.frame) - newLabelFrame.size.height - 15;
        }
        else {
            newLabelFrame.origin.y = CGRectGetMidY(label.frame) - newLabelFrame.size.height - 5;
        }
    }
    else {
        if (yAxisValInPixel-CGRectGetMidY(label.frame) < 15 && yAxisValInPixel-CGRectGetMidY(label.frame) >= 0) {
            newLabelFrame.origin.y = CGRectGetMidY(label.frame) + 15;
        }
        else {
            newLabelFrame.origin.y = CGRectGetMidY(label.frame) + 5;
        }
    }
    label.frame = newLabelFrame;
    label.textAlignment = NSTextAlignmentCenter;
}
-(void)sChartRenderFinished:(ShinobiChart *)chart {
    if (isInitialRender) {
        double tickFrequency = [chart.yAxis.currentMajorTickFrequency doubleValue];
        chart.yAxis.rangePaddingHigh = @(tickFrequency*2);
        chart.yAxis.rangePaddingLow = @(tickFrequency*2);
        // Y-axis scale from top was cropping, by adding this line that issue is fixed now.
        chart.canvasInset = UIEdgeInsetsMake(10, 10, 10, 10);
        [chart redrawChartIncludePlotArea:YES];
        isInitialRender = NO;
    }
}
@end
