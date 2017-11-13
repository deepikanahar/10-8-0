//
//  FxGraph.m
//  c100Benchmarking
//
//  Created by Deepika Nahar on 10/03/17.
//  Modified by Pradeep Yadav on 10/04/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2IFxGraph.h"

@implementation I2IFxGraph

@synthesize dataModel;

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel
       withCommanderDelegate:_commander
                   withProps:_props];
    if (self) {
        
        fxGraph = [[I2IFxPlotV alloc] init];
        fxGraph.yMin = (double)0.0;
        fxGraph.yMax = (double)0.0;
        //Initialize all widget's subviews as well as any instance variable
        
    }
    return self;
    
}

//  This method is used to clear all the widget’s views in order to save memory. It is called the first time the widget is loaded, and later if the widget needs to be recreated or deleted.
-(void)cleanViews {
    
    for (UIView *view in self.subviews) {
        
        if ([view isKindOfClass:[UIView class]]) {
            
            UIView *v = (UIView *)view;
            [v removeFromSuperview];
            
        }
        
    }
    
}

//  This method is called every time the widget is recreated, which could be during initialization, when a layout or panel changes, or when the widget’s source selector is changed.
-(void)recreateWidget {
    
    [self reInitDataModels];
    hostView = [[UIView alloc] initWithFrame:self.frame];
    [fxGraph renderChart:hostView];
    [self addSubview:hostView];
}

//Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    //  Update the widget's data
    [self.widgetHelper reInitDataModels];
    dataModel = (MSIModelData *)[widgetHelper dataProvider];
    if (dataModel.rowCount > 0) [self readData];
    
}

#pragma mark Data Retrieval Methods
-(void)readData {
    
    fxGraph.colors = [[NSMutableArray alloc] init];
    MSIAttributeHeader *attributeHeader = (MSIAttributeHeader *)[dataModel headerObjectByAxisType:COLUMN_AXIS
                                                                                   andColumnIndex:0];
    keySuffix = attributeHeader.attribute.name;
    
    MSIPropertyGroup *propertyGroup = attributeHeader.format;
    fxGraph.fontFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                                   propertyID:FontFormattingName];
    fxGraph.fontSize = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                    propertyID:FontFormattingSize] intValue];
    // Primary Color for axis and data labels
    [fxGraph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                               propertyID:FontFormattingColor]]];
    
    MSIMetricHeader *metricHeader = [dataModel.metricHeaderArray objectAtIndex:0];
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:dataModel.rowCount - 1];
    int noOfSelections = [[[PlistData getValue] objectForKey:[metricValue rawValue]] intValue];
    propertyGroup = metricValue.format;
    fxGraph.fontSizeXLabels = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                           propertyID:FontFormattingSize] intValue];
    // x-axis labels colour
    [fxGraph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                               propertyID:FontFormattingColor]]];
    // Number formatter
    fxGraph.numberFormat = [[NSNumberFormatter alloc] init];
    switch ([[propertyGroup propertyByPropertySetID:FormattingNumber
                                          propertyID:NumberFormattingCategory] intValue]) {
        case 0: fxGraph.numberFormat.numberStyle = NSNumberFormatterDecimalStyle;
            break;
            
        case 1: fxGraph.numberFormat.numberStyle = NSNumberFormatterCurrencyStyle;
            break;
            
        case 4: fxGraph.numberFormat.numberStyle = NSNumberFormatterPercentStyle;
            break;
            
        default:
            break;
    }
    fxGraph.numberFormat.positiveFormat = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                                      propertyID:NumberFormattingFormat];
    
    fxGraph.dataForPlot = [[NSMutableArray alloc] init];
    fxGraph.xLabels = [[NSMutableArray alloc] init];
    
    if (noOfSelections > 0) {
        
        for (int z = 0; z < dataModel.rowCount - 1; z++) {
            
            metricValue = [metricHeader.elements objectAtIndex:z];
            propertyGroup = metricValue.format;
            // Series fill colour
            [fxGraph.colors addObject:[self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                       propertyID:FontFormattingColor]]];
            
            NSMutableArray *dataForSeries = [[NSMutableArray alloc] init];
            for (int y = 0; y < noOfSelections; y++) {
                
                NSString *selectedCurrency = [NSString stringWithFormat:@"%@%d", keySuffix, y];
                selectedCurrency = [[PlistData getValue] objectForKey:selectedCurrency];
                for (int x = 0; x < dataModel.columnCount - 1; x++) {
                    
                    NSString *rowCurrency = [[[dataModel arrayWithHeaderValueOfWholeRowByAxisType:COLUMN_AXIS
                                                                                      andRowIndex:x] objectAtIndex:0] rawValue];
                    if ([selectedCurrency isEqualToString:rowCurrency]) {
                        
                        NSString *rowColumnValue = [[[dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                                             andRowIndex:z] objectAtIndex:x + 1] rawValue];
                        [dataForSeries addObject:rowColumnValue];
                        if ([rowColumnValue doubleValue] >= fxGraph.yMax) {
                            fxGraph.yMax = [rowColumnValue doubleValue];
                        }
                        if ([rowColumnValue doubleValue] <= fxGraph.yMin) {
                            fxGraph.yMin = [rowColumnValue doubleValue];
                        }
                        if (z == 0) [fxGraph.xLabels addObject:selectedCurrency];
                        break;
                        
                    }
                    
                }
                
            }
            [fxGraph.dataForPlot addObject:dataForSeries];
            
        }
        
    }
    
}

#pragma mark handleEvent Methods
//When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    
    [self cleanViews];
    [self recreateWidget];
    
}

#pragma mark Converts BGR value to UIColor object
-(UIColor *)colorConvertor:(NSString *)strColor {
    
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF) / 255.0f
                           green:((bgrValue & 0xFF00) >> 8) / 255.0f
                            blue:((bgrValue & 0xFF0000) >> 16) / 255.0f
                           alpha:1.0f];
    
}

@end
