//
//  I2IDynamicText.mm
//  c100Benchmarking
//
//  Created by Neha Salankar on 06/05/16.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PlistData.h"
#import "I2IDynamicText.h"
#import "FormulaEvaluator.h"

@implementation I2IDynamicText

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel
       withCommanderDelegate:_commander
                   withProps:_props];
    if (self) {
        
        metrics = [[NSMutableDictionary alloc] init];
        [self getSliderValues];
        
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
    
}

//  Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    
    //  Update the widget's data
    [self.widgetHelper reInitDataModels];
    [self readData];
    
}

#pragma mark Data Retrieval Methods
-(void)readData{
    
    // Keep a reference to the grid's data
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader = [current objectAtIndex:0];
    
    // Always expect first metric to be the Index Of Supporting Metrics
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    intMetrics = [metricValue.rawValue intValue];
    
    for (NSString *strKey in [[PlistData getValue] allKeys]) {
        
        if ([strKey hasPrefix:@"suffixText"]) {
            
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            NSNumber *number = [f numberFromString:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]];
            if (number!=nil) [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]]
                                        forKey:strKey];
            else [metrics setValue:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]
                            forKey:strKey];
            
        }
        
    }
    
    for (int i = intMetrics; i < current.count; i++) {
        
        NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                           andRowIndex:i];
        
        MSIHeaderValue *attributeCell = [row objectAtIndex:0];
        NSString *attributeValue = attributeCell.headerValue;
        metricValue = [row objectAtIndex:1];
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *number = [f numberFromString:metricValue.rawValue];
        
        if (number != nil) [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", metricValue.headerValue]]
                                      forKey:attributeValue];
        else [metrics setValue:[NSString stringWithFormat:@"%@", metricValue.rawValue]
                        forKey:attributeValue];
        
    }
    
    // Always expect second metric to be the number of texts
    metricValue = [metricHeader.elements objectAtIndex:1];
    intTexts = [metricValue.rawValue intValue];
    
    if (intTexts > 0) {
        
        int indexOfText = 2;
        for (int i = 0; i < intTexts; i++) {
            
            //  Font parameters
            NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                               andRowIndex:indexOfText];
            MSIMetricValue *metricValues = [row objectAtIndex:1];
            MSIPropertyGroup *propertyGroup = metricValues.format;
            
            strFontFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                                      propertyID:FontFormattingName];
            intFontSize = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                       propertyID:FontFormattingSize] intValue];
            fontColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                         propertyID:FontFormattingColor]];
            strTextAlignment = [propertyGroup propertyByPropertySetID:FormattingAlignment
                                                           propertyID:AlignmentFormattingHorizontal];
            
            NSMutableDictionary *dictTextAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[UIFont fontWithName:strFontFace
                                                                                                                          size:intFontSize], NSFontAttributeName, fontColor, NSForegroundColorAttributeName, nil];
            
            //  To get text with #,^,| and image name from specified index
            strFullText = [[NSMutableAttributedString alloc] initWithString:[[metricHeader.elements objectAtIndex:indexOfText] rawValue]
                                                                 attributes:dictTextAttributes];
            NSMutableString *strTempString = [[NSMutableString alloc] initWithString:[[metricHeader.elements objectAtIndex:indexOfText] rawValue]];
            
            //  Condition to check pipe (|) present or not
            if ([[NSString stringWithFormat:@"%@", strTempString] containsString:@"|"]) {
                
                //  To separate one string into two parts from string pipe (|)
                NSArray *arrTextComponents = [[NSString stringWithFormat:@"%@",strTempString] componentsSeparatedByString:@"|"];
                
                //  To replace string having pipe (|) with first part which is text
                [strFullText replaceCharactersInRange:NSMakeRange(0, [strTempString length])
                                           withString:[NSString stringWithFormat:@"%@", [arrTextComponents objectAtIndex:0]]];
                
                strImage = [[NSMutableString alloc] initWithFormat:@"%@", [arrTextComponents objectAtIndex:1]];
                
            }
            else strImage = nil;
            
            indexOfText++;
            
            strPosition = [[NSString alloc] initWithFormat:@"%@", [[metricHeader.elements objectAtIndex:indexOfText++] rawValue]];
            NSArray *arrPosition = [[NSArray alloc] initWithArray:[strPosition componentsSeparatedByString:@","]];
            CGRect frameRect = CGRectMake([[arrPosition objectAtIndex:0] floatValue], [[arrPosition objectAtIndex:1] floatValue], [[arrPosition objectAtIndex:2] floatValue], [[arrPosition objectAtIndex:3] floatValue]);
            
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:frameRect];
            UILabel *lblDynamicText = [[UILabel alloc] initWithFrame:CGRectMake(frameRect.origin.x, frameRect.origin.y, frameRect.size.width, frameRect.size.height - 15)];
            
            intNoFormulae = [[[metricHeader.elements objectAtIndex:indexOfText++] rawValue] intValue];
            
            if (intNoFormulae > 0) {
                
                arrFormulae = [[NSMutableArray alloc] init];
                for (int j = 0; j < intNoFormulae; j++) {
                    
                    row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                       andRowIndex:indexOfText];
                    MSIMetricValue *metricValues = [row objectAtIndex:1];
                    MSIPropertyGroup *propertyGroup = metricValues.format;
                    UIColor *fontDTColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                                            propertyID:FontFormattingColor]];
                    
                    //  Number Format
                    NSString *strFormatCategory = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                                              propertyID:NumberFormattingCategory];
                    NSString *strNumberFormat = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                                            propertyID:NumberFormattingFormat];
                    strNumberFormat = [strNumberFormat stringByReplacingOccurrencesOfString:@"\""
                                                                                 withString:@""];
                    
                    //  Font Format
                    NSString *strFontTypeBold = [propertyGroup propertyByPropertySetID:FormattingFont
                                                                            propertyID:FontFormattingBold];
                    NSString *strFontTypeItalic = [propertyGroup propertyByPropertySetID:FormattingFont
                                                                              propertyID:FontFormattingItalic];
                    
                    NSString *strNewFontFace = @"";
                    
                    if ([strFontTypeBold isEqualToString:@"-1"]) {
                        
                        if ([strFontTypeItalic isEqualToString:@"-1"]) strNewFontFace = [NSString stringWithFormat:@"%@-BoldItalic", strFontFace];
                        else strNewFontFace = [NSString stringWithFormat:@"%@-Bold", strFontFace];
                        
                    }
                    else if ([strFontTypeItalic isEqualToString:@"-1"]) strNewFontFace = [NSString stringWithFormat:@"%@-Italic", strFontFace];
                    else strNewFontFace = strFontFace;
                    
                    [dictTextAttributes setObject:[UIFont fontWithName:strNewFontFace
                                                                  size:intFontSize]
                                           forKey:NSFontAttributeName];
                    
                    [arrFormulae addObject:[[metricHeader.elements objectAtIndex:indexOfText++] rawValue]];
                    FormulaEvaluator *eval = [[FormulaEvaluator alloc] init];
                    
                    //  Attributed String
                    [dictTextAttributes setObject:fontDTColor
                                           forKey:NSForegroundColorAttributeName];
                    NSString *tempValue = [NSString stringWithFormat:@"%@", [eval evaluateFormula:[arrFormulae objectAtIndex:j]
                                                                                   withDictionary:metrics]];
                    if ([tempValue floatValue] < 0) {
                        
                        NSRange rangeDot = [strImage rangeOfString:@"."];
                        [strImage replaceCharactersInRange:rangeDot
                                                withString:@"Alt."];
                        
                    }
                    else {
                        
                        [strImage replaceOccurrencesOfString:@"Alt."
                                                  withString:@"."
                                                     options:0
                                                       range:NSMakeRange(0, strImage.length)];
                        
                    }
                    NSString *str = [self setNumberFormat:tempValue
                                       withFormatCategory:strFormatCategory
                                               withFormat:strNumberFormat];
                    
                    NSRange range;
                    range.length = 0;
                    range.location = 0;
                    
                    //  Code to get range of # and ^ to replace with numbers
                    if ([strTempString containsString:@"#"]) range = [strTempString rangeOfString:@"#"];
                    else if ([strTempString containsString:@"^"]) {
                        
                        range = [strTempString rangeOfString:@"^"];
                        str = [NSString stringWithFormat:@"%@",[metrics objectForKey:[NSString stringWithFormat:@"%@%@", @"suffixText", tempValue]]];
                        if ([str isEqualToString:@" "]) str = @"";
                        
                    }
                    
                    NSMutableAttributedString *strNumber = [[NSMutableAttributedString alloc] initWithString:str
                                                                                                  attributes:dictTextAttributes];
                    [strFullText replaceCharactersInRange:range
                                     withAttributedString:strNumber];
                    [strTempString replaceCharactersInRange:range
                                                 withString:str];
                    
                }
                
                switch ([strTextAlignment intValue]) {
                        
                    case 4: lblDynamicText.textAlignment = NSTextAlignmentRight;
                        break;
                        
                    case 3: lblDynamicText.textAlignment = NSTextAlignmentCenter;
                        break;
                        
                    default: lblDynamicText.textAlignment = NSTextAlignmentLeft;
                        break;
                        
                }
                
                lblDynamicText.attributedText = strFullText;
                lblDynamicText.numberOfLines = 0;
                [lblDynamicText sizeToFit];
                lblDynamicText.frame = CGRectMake(frameRect.origin.x, frameRect.origin.y, frameRect.size.width, lblDynamicText.frame.size.height);
                lblDynamicText.backgroundColor = [UIColor clearColor];
                //  To set background to the label with image name
                if (strImage != nil) {
                    
                    imgView.image = [UIImage imageNamed:strImage];
                    imgView.contentMode = UIViewContentModeScaleAspectFit;
                    [self addSubview:imgView];
                    
                }
                
                if ([strImage isEqualToString:@"Warning.png"]) {
                    
                    NSString *strWarning = [metrics objectForKey:@"Warning"];
                    strFullText = [[NSMutableAttributedString alloc] initWithString:strWarning
                                                                         attributes:dictTextAttributes];
                    UITapGestureRecognizer *popOver = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(displayWarning)];
                    [imgView setUserInteractionEnabled:YES];
                    [imgView addGestureRecognizer:popOver];
                    
                }
                else if ([strImage isEqualToString:@"WarningAlt.png"]) {}
                else [self addSubview:lblDynamicText];
                
            }
            
        }
        
    }
    
}

#pragma mark handleEvent Methods
// When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    
    [self cleanViews];
    [metrics removeAllObjects];
    [self recreateWidget];
    
}

-(void)getSliderValues {
    
    for (NSString *strKey in [[PlistData getValue] allKeys]) {
        
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        NSNumber *number = [f numberFromString:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]];
        if (number != nil) [metrics setValue:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",[[PlistData getValue] valueForKey:strKey]]]
                                      forKey:strKey];
        else [metrics setValue:[NSString stringWithFormat:@"%@", [[PlistData getValue] valueForKey:strKey]]
                        forKey:strKey];
        
    }
    
}

#pragma mark Converts BGR value to UIColor object
-(UIColor*)colorConvertor:(NSString *)strColor {
    
    //  We got B G R here, but we need RGB
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF) / 255.0f
                           green:((bgrValue & 0xFF00) >> 8) / 255.0f
                            blue:((bgrValue & 0xFF0000) >> 16) / 255.0f
                           alpha:1.0f];
    
}

#pragma mark Number Formatter
-(NSString*)setNumberFormat:(NSString*)strValue withFormatCategory:(NSString*)strCategory withFormat:(NSString*)strFormat {
    
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    switch ([strCategory intValue]) {
            
            // Represents Decimal Formatting
        case 0:
            numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            numFormatter.positiveFormat = strFormat;
            break;
            
            // Represents Currency Formatting
        case 1:
            numFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
            numFormatter.positiveFormat = strFormat;
            break;
            
            // Represents Percentage Formatting
        case 4:
            numFormatter.numberStyle = NSNumberFormatterPercentStyle;
            numFormatter.positiveFormat = strFormat;
            break;
            
        default:
            break;
    }
    return [numFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strValue]]];
    
}

#pragma mark Popover for Warnings
-(void)displayWarning {
    
    UIViewController *uivcPopOver = [[UIViewController alloc] init];
    uivcPopOver.view.frame = CGRectMake(0, 0, 300, 70);
    uivcPopOver.modalPresentationStyle = UIModalPresentationPopover;
    UILabel *lblWarning = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 300, 65)];
    lblWarning.attributedText = strFullText;
    lblWarning.numberOfLines = 0;
    lblWarning.textAlignment = NSTextAlignmentCenter;
    [uivcPopOver.view addSubview:lblWarning];
    [self.window.rootViewController presentViewController:uivcPopOver
                                                 animated:YES
                                               completion:nil];
    
}

@end
