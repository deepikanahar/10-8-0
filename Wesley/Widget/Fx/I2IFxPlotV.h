//
//  I2IFxPlotV.h
//  c100Benchmarking
//
//  Created by Deepika Nahar on 10/03/17.
//  Modified by Pradeep Yadav on 19/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IFxPlotV_h
#define I2IFxPlotV_h

#import <Foundation/Foundation.h>
#import <ShinobiCharts/ShinobiCharts.h>

@interface I2IFxPlotV : NSObject <SChartDatasource, SChartDelegate> {
    
    ShinobiChart *chart;
    
}

@property (retain, nonatomic) NSMutableArray *dataForPlot;
@property (retain, nonatomic) NSMutableArray *xLabels;
@property (retain, nonatomic) NSMutableArray *colors;
// Size of font to be displayed on axis labels & data values
@property (assign, nonatomic) int fontSize;
@property (assign, nonatomic) int fontSizeXLabels;
// Font face for all the lables and data values
@property (retain, nonatomic) NSString *fontFace;
// Minimum and maximum value for y-axis
@property (assign, nonatomic) double yMin;
@property (assign, nonatomic) double yMax;
@property (retain, nonatomic) NSNumberFormatter *numberFormat;

-(void)renderChart:(UIView *)hostView;

@end

#endif

/* I2IFxPlotV_h */
