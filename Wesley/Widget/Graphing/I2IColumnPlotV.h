//
//  I2IColumnPlotV.h
//  c100Benchmarking
//
//
//  Created by Neha Salankar on 30/12/14.
//  Modified by Pradeep Yadav on 08/12/15.
//  Copyright (c) 2015 i2iLogic Australia Pty Ltd. All rights reserved.
//

#ifndef c100WorkingCapital_I2IColumnPlotV_h
#define c100WorkingCapital_I2IColumnPlotV_h

#import <Foundation/Foundation.h>
#import <ShinobiCharts/ShinobiCharts.h>

@interface CustomColumnSeries : SChartColumnSeries
    @property (retain, nonatomic) NSMutableArray *arrColors;
@end
@interface CustomNumberYAxis : SChartNumberAxis
@end
@interface I2IColumnPlotV : NSObject <SChartDatasource, SChartDelegate> {
    ShinobiChart *vChart;
    BOOL isInitialRender;
}
    @property (retain, nonatomic) NSMutableArray *dataForPlot;
    // Unique ID of the graph
    @property (assign, nonatomic) int gID;
    // How many columns to display in the graph
    @property (assign, nonatomic) int columns;
    // Label to be displayed on y-axis
    @property (retain, nonatomic) NSString *yLabel;
    // Labels to be displayed on x-axis. Array size to be equal to columns
    @property (retain, nonatomic) NSMutableArray *xLabels;
    // Fill colors for the columns. Array size to be equal to columns
    @property (retain, nonatomic) NSMutableArray *colors;
    // Size of font to be displayed on x & y axis labels & data values
    @property (retain, nonatomic) NSString *fSize;
    // Font face for all the lables and data values
    @property (retain, nonatomic) NSString *fFace;
    // Minimum and maximum value for y-axis
    @property (assign, nonatomic) double yMin;
    @property (assign, nonatomic) double yMax;
    // Formulae for each column
    @property (retain, nonatomic) NSMutableArray *formulae;
// Render the chart on the hosting view from the view controller with the default theme.
-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier;
@end
#endif
