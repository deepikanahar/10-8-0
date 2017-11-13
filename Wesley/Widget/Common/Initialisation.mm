//
//  Initialisation.mm
//  c100Benchmarking
//
//  Created by Neha Salankar on 15/10/15.
//  Modified by Pradeep Yadav on 30/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Initialisation.h"
#import "FormulaEvaluator.h"

@implementation Initialisation

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel
       withCommanderDelegate:_commander
                   withProps:_props];
    
    if (self) [self reInitDataModels];
    return self;
    
}

//  This method is used to clear all the widget’s views in order to save memory. It is called the first time the widget is loaded, and later if the widget needs to be recreated or deleted.
-(void)cleanViews {
}

//  This method is called every time the widget is recreated, which could be during initialization, when a layout or panel changes, or when the widget’s source selector is changed.
-(void)recreateWidget {
}

//  Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    
    //  Update the widget's data.
    [self readData];
    
}

#pragma mark Data Retrieval Method
-(void)readData {
    
    // Keep a reference to the grid's data.
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader = [current objectAtIndex:0];
    
    // Always expect first metric value to be the Company ID.
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    companyID = metricValue.rawValue;
    
    // Always expect first metric header to be the unique identifier for the panel / control grid.
    NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                       andRowIndex:0];
    MSIHeaderValue *attributeCell = [row objectAtIndex:0];
    companyKey = [[NSString alloc]initWithFormat:@"%@", attributeCell.headerValue];
    
    // Always expect second metric to be the number of variables.
    metricValue = [metricHeader.elements objectAtIndex:1];
    intVariables = [metricValue.rawValue intValue];
    
    NSString *strCompany = [NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:companyKey]];
    
    if ([strCompany isEqualToString:@"(null)"] || ![strCompany isEqualToString:companyID]) {
        
        eval = [[FormulaEvaluator alloc]init];
        metrics = [[NSMutableDictionary alloc]init];
        
        // Loop through all the supporting metrics and add to the key-value pair to metrics dictionary.
        for (int i = intVariables + 2; i < current.count; i++) {
            
            row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                               andRowIndex:i];
            attributeCell = [row objectAtIndex:0];
            NSString *attributeValue = attributeCell.headerValue;
            metricValue = [row objectAtIndex:1];
            
            NSString *strMetricValue = metricValue.rawValue;
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            
            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strMetricValue]]
                       forKey:attributeValue];
            
        }
        
        if (intVariables > 0) {
            
            for (int i = 0; i < intVariables; i++) {
                
                // Gets the header value of the dynamic label.
                row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                   andRowIndex:2 + i];
                attributeCell = [row objectAtIndex:0];
                NSString *varKey = [[NSString alloc] initWithFormat:@"%@", attributeCell.headerValue];
                
                // Gets the formula used to dynamically evaluate the value of dynamic label.
                NSString *varFormula = [[metricHeader.elements objectAtIndex:2 + i] rawValue];
                
                if ([varKey hasPrefix:@"array"]) {
                    
                    varKey = [varKey stringByReplacingOccurrencesOfString:@"array" withString:@""];
                    int maxRows = [[[varFormula componentsSeparatedByString:@","] objectAtIndex:1] intValue];
                    varFormula = [[varFormula componentsSeparatedByString:@","] objectAtIndex:0];
                    
                    for (int i = 0; i < maxRows; i++) {
                        
                        NSString *currentKey = [varKey stringByReplacingOccurrencesOfString:@"x"
                                                                                 withString:[NSString stringWithFormat:@"%d", i]];
                        if ([varKey hasPrefix:@"sft"]) {
                        
                            [PlistData setValue:varFormula
                                   keyForSlider:currentKey];
                            [metrics setValue:varFormula forKey:currentKey];
                            
                        }
                        else {
                            
                            NSString *strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:varFormula
                                                                                              withDictionary:metrics]];
                            
                            [PlistData setValue:strCalcValue
                                   keyForSlider:currentKey];
                            [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strCalcValue]]
                                       forKey:currentKey];
                            
                        }
                    }
                    
                }
                else {
                    
                    NSString *strCalcValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:varFormula
                                                                                      withDictionary:metrics]];
                    
                    [PlistData setValue:strCalcValue
                           keyForSlider:varKey];
                    [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strCalcValue]]
                               forKey:varKey];
                    
                }
                
            }
            
        }
        
        // Writes control default values to the plist file.
        [PlistData setValue:companyID
               keyForSlider:companyKey];
        
    }
    
}

@end
