//
//  I2IBarPlotH.m
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 05/11/14.
//  Modified by Neha on 22/04/16.
//  Copyright (c) 2015 i2iLogic Australia Pty Ltd. All rights reserved.
//

#import "I2IBarPlotH.h"

@implementation CustomBarSeries
@synthesize arrColors;
-(SChartBarSeriesStyle*)styleForPoint:(id<SChartData>)point {
    SChartBarSeriesStyle *newStyle = [super styleForPoint:point];
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

@implementation CustomNumberXAxis
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

@implementation I2IBarPlotH

@synthesize dataForPlot;
@synthesize gID;
@synthesize bars;
@synthesize xLabel;
@synthesize yLabels;
@synthesize colors;
@synthesize fSize;
@synthesize fFace;
@synthesize xMin;
@synthesize xMax;
@synthesize yLongest;
@synthesize type;
#define LABEL_IDENTIFIER 5
-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier {
    // Create the chart
    hChart = [[ShinobiChart alloc] initWithFrame:CGRectMake(0, 0, hostView.bounds.size.width, hostView.bounds.size.height)];
    hChart.autoresizingMask = ~UIViewAutoresizingNone;
    hChart.backgroundColor = [UIColor clearColor];
    
    // Add x-axis
    SChartNumberAxis *xAxis = [[SChartNumberAxis alloc] init];
    xAxis = [CustomNumberXAxis new];
    if ([xLabel isEqualToString:@" "] || xLabel == nil) {
        xAxis.title = @"_";
        xAxis.style.titleStyle.textColor = [UIColor clearColor];
    }
    else {
        xAxis.title = xLabel;
        xAxis.style.titleStyle.textColor = [colors firstObject];
    }
    [xAxis.style setLineWidth:[NSNumber numberWithInt:1]];
    xAxis.style.lineColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelColor = [colors firstObject];
    xAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    xAxis.style.titleStyle.font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    xAxis.enableGesturePanning = NO;
    xAxis.enableGestureZooming = NO;
    if (xMax == 0.0) {
        xAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeTicksAndLabelsPersist;
        xAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeNeitherPersist;
    }
    else if (xMin == 0.0) {
        xAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeNeitherPersist;
        xAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeTicksAndLabelsPersist;
    }
    else {
        xAxis.tickLabelClippingModeHigh = SChartTickLabelClippingModeNeitherPersist;
        xAxis.tickLabelClippingModeLow = SChartTickLabelClippingModeNeitherPersist;
    }
    xAxis.autoCalculateRange = YES;
    hChart.xAxis = xAxis;
    
    // Add y-axis
    SChartCategoryAxis *yAxis = [[SChartCategoryAxis alloc] init];
    [yAxis.style setLineWidth:[NSNumber numberWithInt:1]];
    yAxis.style.lineColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelColor = [colors firstObject];
    yAxis.style.majorTickStyle.tickGap = @1;
    yAxis.style.majorTickStyle.textAlignment = NSTextAlignmentCenter;
    yAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
    yAxis.enableGesturePanning = NO;
    yAxis.enableGestureZooming = NO;
    hChart.yAxis = yAxis;
    hChart.yAxis.axisPositionValue = @0;
    hChart.yAxis.style.interSeriesSetPadding = @(0.5);
    hChart.clipsToBounds = YES;
    
    // add to the view
    [hostView addSubview:hChart];
    hChart.datasource = self;
    hChart.delegate = self;
    
    // hide the legend
    hChart.legend.hidden = YES;
    isInitialRender = YES;
}

#pragma mark - SChartDatasource methods
-(NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
    return 1;
}
-(SChartSeries *)sChart:(ShinobiChart *)chart seriesAtIndex:(NSInteger)index {
    CustomBarSeries *barSeries = [[CustomBarSeries alloc] init];
    barSeries.arrColors = [[NSMutableArray alloc] initWithArray:colors];
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
    return dataForPlot[dataIndex];
}
-(void)sChart:(ShinobiChart *)chart alterTickMark:(SChartTickMark *)tickMark beforeAddingToAxis:(SChartAxis *)axis {
    if (!axis.isXAxis) {
        if (tickMark.value >= 0 && tickMark.value < dataForPlot.count) {
            SChartDataPoint *dataPoint = [dataForPlot objectAtIndex:tickMark.value];
            if ([[NSString stringWithFormat:@"%@",dataPoint.xValue] floatValue] < 0) {
                //  To calculate ticklabel width
                UIFont *font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
                NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
                CGSize textSize = [yLongest sizeWithAttributes: userAttributes];
                
                tickMark.tickLabel.frame = CGRectMake(tickMark.tickLabel.frame.origin.x+tickMark.tickLabel.frame.size.width+10, tickMark.tickLabel.frame.origin.y, textSize.width+10, tickMark.tickLabel.frame.size.height);
                tickMark.tickLabel.textAlignment = NSTextAlignmentLeft;
            }
            else {
                tickMark.tickLabel.textAlignment = NSTextAlignmentRight;
            }
        }
        if ([type isEqualToString:@"x"]) {
            tickMark.tickLabel.text = @"";
        }
    }
    else{
        
        UIFont *font = [UIFont fontWithName:fFace size:[fSize floatValue]-1];
        NSDictionary *userAttributes = @{NSFontAttributeName: font,
                                         NSForegroundColorAttributeName: [UIColor whiteColor]};
        CGSize textSize = [tickMark.tickLabel.text sizeWithAttributes: userAttributes];
        tickMark.tickLabel.frame = CGRectMake(tickMark.tickLabel.frame.origin.x, tickMark.tickLabel.frame.origin.y, textSize.width+10, tickMark.tickLabel.frame.size.height);
    }
}
-(void)sChart:(ShinobiChart *)chart alterDataPointLabel:(SChartDataPointLabel *)label forDataPoint:(SChartDataPoint *)dataPoint inSeries:(SChartSeries *)series {
    
    CGRect newLabelFrame = label.frame;
    
    // The label identifier is used to prevent already customised labels getting customised again.
    if (label.tag != LABEL_IDENTIFIER) {
        label.tag = LABEL_IDENTIFIER;
        if ([xLabel isEqualToString:@"%"]) {
            label.text = [NSString stringWithFormat:@"%.2f",[dataPoint.xValue floatValue]];
        }
        else {
            static const char sUnits[] = { '\0', 'M', '?', 'B'};
            static int sMaxUnits = sizeof sUnits - 1;
            int multiplier =  1000;
            int exponent = 0;
            
            float bytes = [dataPoint.xValue floatValue];
            
            while ((fabs(bytes) >= multiplier) && (exponent < sMaxUnits)) {
                bytes /= multiplier;
                exponent++;
            }
            NSString *convertedStr = [[NSString alloc] init];
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
    if ([dataPoint.xValue floatValue] >= 0.0) {
        newLabelFrame.origin.x = CGRectGetMidX(label.frame) + 2;
        label.textAlignment = NSTextAlignmentLeft;
    }
    else {
        newLabelFrame.origin.x = CGRectGetMidX(label.frame) - newLabelFrame.size.width - 2;
    }
    label.frame = newLabelFrame;
    
}
-(void)sChartRenderFinished:(ShinobiChart *)chart {
    if (isInitialRender) {
        double tickFrequency = [chart.xAxis.currentMajorTickFrequency doubleValue];
        
        if (xMax == 0.0) {
            chart.canvasInset = UIEdgeInsetsMake(0, chart.getPlotAreaFrame.size.width-chart.frame.size.width, 0, chart.frame.size.width-chart.getPlotAreaFrame.size.width);
            chart.xAxis.rangePaddingLow = @(tickFrequency * 2);
            chart.xAxis.rangePaddingHigh = @(tickFrequency * 1.25);
            
        }
        else if (xMin == 0.0) {
            chart.xAxis.rangePaddingLow = @(tickFrequency * 1.25);
            chart.xAxis.rangePaddingHigh = @(tickFrequency * 2);
        }
        else {
            chart.canvasInset = UIEdgeInsetsMake(0, chart.getPlotAreaFrame.size.width-chart.frame.size.width, 0, 0);
            chart.xAxis.rangePaddingHigh = @(tickFrequency * 1.25);
            chart.xAxis.rangePaddingLow = @(tickFrequency * 1.25);
        }
        [chart redrawChartIncludePlotArea:YES];
        isInitialRender = NO;
    }
}
@end
