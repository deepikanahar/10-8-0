//
//  I2IWFColoredPlot.h
//  c100Benchmarking
//
//
//  Created by Pradeep Yadav on 28/05/15.
//  Modified by Pradeep Yadav on 09/12/15.
//  Copyright (c) 2015 i2iLogic Australia Pty Ltd. All rights reserved.
//

#ifndef c100WorkingCapital_I2IWFColoredPlot_h
#define c100WorkingCapital_I2IWFColoredPlot_h

#import <UIKit/UIKit.h>
#import <ShinobiCharts/ShinobiCharts.h>
#import <Foundation/Foundation.h>


@protocol I2IWFColoredPlot;

@interface CustomColoredWFSeries : SChartCandlestickSeries
    @property (retain, nonatomic) NSMutableArray *arrColors;
    @property (retain, nonatomic) NSMutableArray *wfResultColumns;
@end

@interface CustomColoredNumberXAxisWF : SChartNumberAxis
@end

@interface I2IWFColoredPlot : NSObject <SChartDatasource, SChartDelegate> {
    ShinobiChart *wfChart;
    BOOL isInitialRender;
}
    @property (retain, nonatomic) NSMutableArray *dataForPlot;
    @property (retain, nonatomic) NSMutableArray *arrXLabels;
    @property (retain, nonatomic) NSMutableArray *formulae;
    @property (retain, nonatomic) NSMutableArray *dataLabels;
    @property (retain, nonatomic) NSMutableArray *arrStops;
    @property (retain, nonatomic) NSMutableArray *colors;
    @property (retain, nonatomic) NSString *fFace;
    @property (retain, nonatomic) NSString *fSize;
    @property (retain, nonatomic) NSString *strStopsCounter;

// Render the chart on the hosting view from the view controller with the default theme.
-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier;
// Recreate the waterfall chart by calculating the formulae based on changes.
-(void)refreshWaterFallGraph;
@end
#endif
