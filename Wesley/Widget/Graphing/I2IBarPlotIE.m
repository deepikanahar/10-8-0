//
//  I2IBarPlotIE.m
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 03/02/15.
//  Modified by Pradeep Yadav on 21/12/15.
//  Copyright (c) 2015 i2iLogic Australia Pty Ltd. All rights reserved.
//

#import "I2IBarPlotIE.h"

@implementation CustomIEBarSeries
@synthesize arrColors;
@synthesize noOFBars;
-(SChartBarSeriesStyle*)styleForPoint:(id<SChartData>)point {
    SChartBarSeriesStyle *newStyle = [super styleForPoint:point];
    newStyle.showArea = YES;
    newStyle.showAreaWithGradient = FALSE;
    newStyle.lineColor = [UIColor clearColor];
    newStyle.lineColorBelowBaseline = [UIColor clearColor];
    newStyle.areaColorGradient = [UIColor clearColor];
    if (noOFBars == 5) {
        newStyle.areaColor = [arrColors objectAtIndex:2];
        newStyle.areaColorBelowBaseline = [arrColors objectAtIndex:2];
    }
    else {
        int barIndex = (int)[point sChartDataPointIndex];
        if (barIndex % 2 == 0) {
            newStyle.areaColor = [arrColors objectAtIndex:2];
            newStyle.areaColorBelowBaseline  = [arrColors objectAtIndex:2];
        }
        else {
            newStyle.areaColor = [arrColors objectAtIndex:1];
            newStyle.areaColorBelowBaseline  = [arrColors objectAtIndex:1];
        }
    }
    return newStyle;
}
@end

@implementation CustomNumberIEXAxis
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
    else {
        if(sUnits[exponent] == '?')
            convertedStr = [NSString stringWithFormat:@"%.1f%@", bytes, @"MM"];
        else
            convertedStr = [NSString stringWithFormat:@"%.1f%c", bytes, sUnits[exponent]];
    }
    return convertedStr;
}
@end

@implementation CustomNumberIEYAxis
-(NSString *)stringForId:(id)obj {
    double isDecimal = fmod([obj doubleValue],1.0);
    if (isDecimal == 0) {
        return [NSString stringWithFormat:@"%.0f%@", [obj doubleValue], @"%"];
    }
    else {
        return @" ";
    }
}
@end

@implementation I2IBarPlotIE {
    NSMutableArray* dataPointsForSeries;
}

@synthesize dataForPlot;
@synthesize gID;
@synthesize bars;
@synthesize xLabel;
@synthesize yLabels;
@synthesize colors;
@synthesize fSize;
@synthesize fFace;

#define LABEL_IDENTIFIER 5
-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier{
    
    // Create the chart
    ieChart = [[ShinobiChart alloc] initWithFrame:CGRectMake(0, 0, hostView.bounds.size.width, hostView.bounds.size.height)];
    ieChart.autoresizingMask =  ~UIViewAutoresizingNone;
    ieChart.backgroundColor = [UIColor clearColor];
    
    double max = 0;
    double min = 0;
    for (NSNumber *num in dataForPlot) {
        double x = num.doubleValue;
        if (x < min) min = x;
        if (x > max) max = x;
    }
    max = max * 1.5;
    min = min * 1.5;
    
    SChartNumberRange *range = [[SChartNumberRange alloc]
                                initWithMinimum:[NSNumber numberWithDouble:min]
                                andMaximum:[NSNumber numberWithDouble:max]];
    
    // Add x-axis
    SChartNumberAxis *xAxis = [[CustomNumberIEXAxis alloc] initWithRange:range];
    [xAxis.style setLineWidth:[NSNumber numberWithInt:1]];
    xAxis.style.lineColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    xAxis.enableGesturePanning = NO;
    xAxis.enableGestureZooming = NO;
    xAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeTicksAndLabelsPersist;
    xAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeTicksAndLabelsPersist;
    
    ieChart.xAxis = xAxis;
    
    SChartCategoryAxis *yAxis = [[SChartCategoryAxis alloc] init];
    yAxis = [CustomNumberIEYAxis new];
    [yAxis.style setLineWidth:[NSNumber numberWithInt:1]];
    yAxis.style.lineColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelColor = [colors firstObject];
    yAxis.style.majorTickStyle.tickGap = @1;
    yAxis.style.majorTickStyle.textAlignment = NSTextAlignmentCenter;
    yAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    yAxis.enableGesturePanning = NO;
    yAxis.enableGestureZooming = NO;
    ieChart.yAxis = yAxis;
    ieChart.yAxis.axisPositionValue = @0;
    ieChart.yAxis.style.interSeriesSetPadding = @(0.4);
    
    ieChart.clipsToBounds = YES;
    
    [self loadChartData];
    
    // add to the view
    [hostView addSubview:ieChart];
    ieChart.datasource = self;
    ieChart.delegate = self;
    
    // hide the legend
    ieChart.legend.hidden = YES;
    isInitialRender = YES;
}
-(void)loadChartData {
    dataPointsForSeries = [NSMutableArray new];
    for (int barIndex = 0; barIndex < bars; barIndex++) {
        SChartDataPoint *dataPoint = [[SChartDataPoint alloc] init];
        if (dataForPlot.count > 5) {
            if ([[dataForPlot objectAtIndex:barIndex] doubleValue] == 0) {
                NSNumber *calcXValue = [[NSNumber alloc] initWithFloat: (float)barIndex/1000000];
                dataPoint.xValue = [calcXValue stringValue];
            }
            else {
                dataPoint.xValue = [dataForPlot objectAtIndex:barIndex];
            }
        }
        else {
            dataPoint.xValue = [dataForPlot objectAtIndex:barIndex];
        }
        dataPoint.yValue = [yLabels objectAtIndex:barIndex];
        [dataPointsForSeries addObject:dataPoint];
    }
}
#pragma mark - SChartDatasource methods
-(NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
    return 1;
}
-(SChartSeries *)sChart:(ShinobiChart *)chart seriesAtIndex:(NSInteger)index {
    CustomIEBarSeries *barSeries = [[CustomIEBarSeries alloc] init];
    barSeries.arrColors = [[NSMutableArray alloc] initWithArray:colors];
    barSeries.noOFBars = bars;
    barSeries.style.dataPointLabelStyle.showLabels = YES;
    barSeries.style.dataPointLabelStyle.textColor = [colors firstObject];
    barSeries.style.dataPointLabelStyle.font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    barSeries.style.dataPointLabelStyle.offsetFlippedForNegativeValues = YES;
    barSeries.animationEnabled = YES;
    barSeries.entryAnimation.absoluteOriginX = @0;
    return barSeries;
}
-(NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)seriesIndex {
    return dataForPlot.count;
}
-(id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(NSInteger)dataIndex forSeriesAtIndex:(NSInteger)seriesIndex {
    return dataPointsForSeries[dataIndex];
}
-(void)sChart:(ShinobiChart *)chart alterTickMark:(SChartTickMark *)tickMark beforeAddingToAxis:(SChartAxis *)axis {
    if (!axis.isXAxis) {
        if (tickMark.value >= 0 && tickMark.value < dataForPlot.count) {
            if ([[NSString stringWithFormat:@"%@",[dataForPlot objectAtIndex:tickMark.value]] floatValue] < 0) {
                //  To calculate ticklabel width
                UIFont *font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
                NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
                CGSize textSize = [tickMark.tickLabel.text sizeWithAttributes: userAttributes];
                
                tickMark.tickLabel.frame = CGRectMake(tickMark.tickLabel.frame.origin.x+tickMark.tickLabel.frame.size.width+15, tickMark.tickLabel.frame.origin.y, textSize.width, tickMark.tickLabel.frame.size.height);
                tickMark.tickLabel.textAlignment = NSTextAlignmentLeft;
            }
            else {
                tickMark.tickLabel.textAlignment = NSTextAlignmentRight;
            }
        }
    }
}
-(void)sChart:(ShinobiChart *)chart alterDataPointLabel:(SChartDataPointLabel *)label forDataPoint:(SChartDataPoint *)dataPoint inSeries:(SChartSeries *)series {
    
    CGRect newLabelFrame = label.frame;
    
    // The label identifier is used to prevent already customised labels getting customised again.
    if (label.tag != LABEL_IDENTIFIER) {
        label.tag = LABEL_IDENTIFIER;
        
        static const char sUnits[] = { '\0', 'M', '?', 'B'};
        static int sMaxUnits = sizeof sUnits - 1;
        int multiplier =  1000;
        int exponent = 0;
        
        float bytes = [dataPoint.xValue floatValue];
        
        while ((fabs(bytes) >= multiplier) && (exponent < sMaxUnits)) {
            bytes /= multiplier;
            exponent++;
        }
        if(sUnits[exponent] == '?')
            label.text = [NSString stringWithFormat:@"%.2f%@", bytes, @"MM"];
        else
            label.text = [NSString stringWithFormat:@"%.2f%c", bytes, sUnits[exponent]];
        
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
    if ([dataPoint.xValue floatValue] > 0) {
        newLabelFrame.origin.x = CGRectGetMidX(label.frame) + 2;
        label.textAlignment = NSTextAlignmentLeft;
    }
    else {
        newLabelFrame.origin.x = CGRectGetMidX(label.frame) - newLabelFrame.size.width - 2;
        label.textAlignment = NSTextAlignmentRight;
    }
    if ([label.text isEqualToString:@"0.00"]) {
        label.textColor = [UIColor clearColor];
    }
    label.frame = newLabelFrame;
}
-(void)sChartRenderFinished:(ShinobiChart *)chart {
    if (isInitialRender) {
        double span = [chart.xAxis.dataRange.maximum doubleValue];
        chart.xAxis.rangePaddingHigh = @(span * 0.2);
        span = [chart.xAxis.dataRange.minimum doubleValue];
        chart.xAxis.rangePaddingLow = @(span * 0.2);
        [chart redrawChartIncludePlotArea:YES];
        isInitialRender = NO;
    }
}
@end
