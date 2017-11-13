//
//  I2IBarPlotH.h
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 05/11/14.
//  Modified by Neha on 22/04/16.
//  Copyright (c) 2015 i2iLogic Australia Pty Ltd. All rights reserved.
//

#ifndef c100WorkingCapital_I2IBarPlotH_h
#define c100WorkingCapital_I2IBarPlotH_h

#import <UIKit/UIKit.h>
#import <ShinobiCharts/ShinobiCharts.h>

@interface CustomBarSeries : SChartBarSeries
    @property (retain, nonatomic) NSMutableArray *arrColors;
@end
@interface CustomNumberXAxis : SChartNumberAxis
@end
@interface I2IBarPlotH : NSObject <SChartDatasource, SChartDelegate> {
    ShinobiChart *hChart;
    BOOL isInitialRender;
}
    @property (retain, nonatomic) NSMutableArray *dataForPlot;
    // Unique ID of the graph
    @property (assign, nonatomic) int gID;
    // How many bars to display in the graph
    @property (assign, nonatomic) int bars;
    // Label to be displayed on x-axis
    @property (retain, nonatomic) NSString *xLabel;
    // Labels to be displayed on y-axis. Array size to be equal to bars
    @property (retain, nonatomic) NSMutableArray *yLabels;
    // Fill colors for the bars. Array size to be equal to bars
    @property (retain, nonatomic) NSMutableArray *colors;
    // Size of font to be displayed on x & y axis labels & data values
    @property (retain, nonatomic) NSString *fSize;
    // Font face for all the lables and data values
    @property (retain, nonatomic) NSString *fFace;
    // Minimum and maximum value for x-axis
    @property (assign, nonatomic) double xMin;
    @property (assign, nonatomic) double xMax;
    // Length of the longest string on y-axis
    @property (retain, nonatomic) NSString *yLongest;
    // Type of the graph
    @property (retain, nonatomic) NSString *type;
// Render the chart on the hosting view from the view controller with the default theme.
-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier;
@end
#endif
