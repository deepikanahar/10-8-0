//
//  I2IWFColoredPlotLabels.h
//  c100Benchmarking
//
//  Created by Deepika Nahar on 20/01/17.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IWFColoredPlotLabels_h
#define I2IWFColoredPlotLabels_h

#import <UIKit/UIKit.h>
#import <ShinobiCharts/ShinobiCharts.h>
#import <Foundation/Foundation.h>


@protocol I2IWFColoredPlotLabels;

@interface CustomColoredLabelsWFSeries : SChartCandlestickSeries
@property (retain, nonatomic) NSMutableArray *arrColors;
@property (retain, nonatomic) NSMutableArray *wfResultColumns;
@end

@interface CustomColoredLabelsNumberXAxisWF : SChartNumberAxis
@end

@interface I2IWFColoredPlotLabels : NSObject <SChartDatasource, SChartDelegate> {
    ShinobiChart *wfChart;
    BOOL isInitialRender;
}
@property (retain, nonatomic) NSMutableArray *dataForPlot;
@property (retain, nonatomic) NSMutableArray *arrXLabels;
@property (retain, nonatomic) NSMutableArray *formulae;
@property (retain, nonatomic) NSMutableArray *dataLabels;
@property (retain, nonatomic) NSMutableArray *arrStops;
@property (retain, nonatomic) NSMutableArray *colors;
@property (retain, nonatomic) NSMutableArray *secondaryLabels;
@property (retain, nonatomic) NSMutableDictionary *secondaryDataLabels;
@property (retain, nonatomic) NSString *fFace;
@property (retain, nonatomic) NSString *fSize;
@property (retain, nonatomic) NSString *strStopsCounter;

// Render the chart on the hosting view from the view controller with the default theme.
-(void)renderChart:(UIView *)hostView identifier:(NSString *)identifier;
// Recreate the waterfall chart by calculating the formulae based on changes.
-(void)refreshWaterFallGraph;
@end
#endif
