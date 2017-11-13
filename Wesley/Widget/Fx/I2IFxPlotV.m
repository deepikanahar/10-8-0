//
//  I2IFxPlotV.m
//  c100Benchmarking
//
//  Created by Deepika Nahar on 10/03/17.
//  Modified by Pradeep Yadav on 19/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import "I2IFxPlotV.h"

@implementation I2IFxPlotV

@synthesize dataForPlot;
@synthesize xLabels;
@synthesize colors;
@synthesize fontSize;
@synthesize fontSizeXLabels;
@synthesize fontFace;
@synthesize yMin;
@synthesize yMax;
@synthesize numberFormat;

#define LABEL_IDENTIFIER 5

-(void)renderChart:(UIView *)hostView {
    
    // Create the chart
    chart = [[ShinobiChart alloc] initWithFrame:CGRectMake(25, 120, hostView.bounds.size.width - 25, hostView.bounds.size.height - 120)];
    
    chart.autoresizingMask =  ~UIViewAutoresizingNone;
    chart.backgroundColor = [UIColor clearColor];
    
    // Add x-axis
    SChartCategoryAxis *xAxis = [[SChartCategoryAxis alloc] init];
    xAxis.style.majorTickStyle.labelColor = [colors objectAtIndex:1];
    xAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fontFace
                                                           size:fontSizeXLabels - 1];
    [xAxis.style setLineWidth:[NSNumber numberWithInt:0]];
    xAxis.enableGesturePanning = NO;
    xAxis.enableGestureZooming = NO;
    xAxis.style.majorTickStyle.showLabels = YES;
    xAxis.axisPosition = SChartAxisPositionReverse;
    xAxis.style.interSeriesSetPadding = @(0.05);
    xAxis.style.interSeriesPadding = @(0.3);
    
    chart.xAxis = xAxis;
    
    // Add y-axis
    SChartNumberRange *yRange = [[SChartNumberRange alloc] initWithMinimum:[NSNumber numberWithFloat:floor(yMin) - 8]
                                                                andMaximum:[NSNumber numberWithFloat:ceil(yMax) + 8]];
    SChartNumberAxis *yAxis = [[SChartNumberAxis alloc] initWithRange:yRange];
    [yAxis setLabelFormatter:[SChartTickLabelFormatter numberFormatter]];
    yAxis.style.lineColor = [UIColor clearColor];
    [yAxis.style.majorGridLineStyle setLineWidth:[NSNumber numberWithFloat:0.5f]];
    yAxis.style.majorGridLineStyle.lineColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelColor = [colors firstObject];
    yAxis.style.majorTickStyle.labelFont = [UIFont fontWithName:fontFace
                                                           size:fontSize - 1];
    yAxis.majorTickFrequency = @(2.5);
    yAxis.labelFormatString = @"%.1f%%";
    yAxis.enableGesturePanning = NO;
    yAxis.enableGestureZooming = NO;
    yAxis.style.majorGridLineStyle.showMajorGridLines = YES;
    yAxis.style.majorTickStyle.showLabels = YES;
    chart.yAxis = yAxis;
    
    SChartAnnotation *hrLine = [SChartAnnotation horizontalLineAtPosition:@(0.0)
                                                                withXAxis:chart.xAxis
                                                                 andYAxis:chart.yAxis
                                                                withWidth:0.5f
                                                                withColor:[UIColor blackColor]];
    [chart addAnnotation:hrLine];
    
    // Adding to the view
    [hostView addSubview:chart];
    chart.datasource = self;
    chart.delegate = self;
    
    // Hiding the legend
    chart.legend.hidden = YES;
    
}

#pragma mark - SChartDatasource methods
-(NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
    
    return dataForPlot.count;
    
}

-(SChartSeries *)sChart:(ShinobiChart *)chart
          seriesAtIndex:(NSInteger)index {
    
    SChartColumnSeries *columnSeries = [[SChartColumnSeries alloc] init];
    columnSeries.style.dataPointLabelStyle.showLabels = YES;
//    columnSeries.style.dataPointLabelStyle.textColor = [colors objectAtIndex:index + 2];
    columnSeries.style.dataPointLabelStyle.textColor = [colors objectAtIndex:1];
    columnSeries.style.dataPointLabelStyle.font = [UIFont fontWithName:fontFace
                                                                  size:fontSize];
    columnSeries.style.dataPointLabelStyle.position = SChartDataPointLabelPositionAboveData;
    columnSeries.style.dataPointLabelStyle.offsetFromDataPoint = CGPointMake(0, -5);
    columnSeries.style.dataPointLabelStyle.offsetFlippedForNegativeValues = YES;
    columnSeries.animationEnabled = YES;
    columnSeries.entryAnimation.absoluteOriginY = @0;
    columnSeries.style.showArea = YES;
    columnSeries.style.showAreaWithGradient = FALSE;
    columnSeries.style.lineColor = [UIColor clearColor];
    columnSeries.style.lineColorBelowBaseline = [UIColor clearColor];
    columnSeries.style.areaColorGradient = [UIColor clearColor];
    columnSeries.style.areaColor = [colors objectAtIndex:index + 2];
    columnSeries.style.areaColorBelowBaseline = columnSeries.style.areaColor;
    return columnSeries;
    
}

-(NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)seriesIndex {
    
    return [[dataForPlot objectAtIndex:seriesIndex] count];
    
}

-(id<SChartData>)sChart:(ShinobiChart *)chart
       dataPointAtIndex:(NSInteger)dataIndex
       forSeriesAtIndex:(NSInteger)seriesIndex {
    
    SChartDataPoint *dataPoint = [[SChartDataPoint alloc] initWithXValue:[xLabels objectAtIndex:dataIndex]
                                                                  yValue:[[dataForPlot objectAtIndex:seriesIndex] objectAtIndex:dataIndex]];
    return dataPoint;
    
}

@end
