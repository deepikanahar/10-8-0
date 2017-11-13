//
//  I2ICustomBack.mm
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 06/09/17.
//  Modified by Pradeep Yadav on 06/09/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2ICustomBack.h"
#import "MicroStrategyMobileSDK/MSIGeneric.h"
#import "MicroStrategyMobileSDK/MSIAppContext.h"
#import <MicroStrategyMobileSDK/MSIPropertyGroup.h>
#import <MicroStrategyMobileSDK/MSIDisplayInfo.h>
#import <MicroStrategyMobileSDK/AttributeHeader.h>
#import <MicroStrategyMobileSDK/Attribute.h>
#import <MicroStrategyMobileSDK/AttributeElement.h>
#import <MicroStrategyMobileSDK/MSICacheManager.h>
#import <MicroStrategyMobileSDK/MSIProjectInfo.h>

// Constants
NSString *const elementPromptPrefix = @"&elementsPromptAnswers=";
NSString *const valuePromptPrefix = @"&valuePromptAnswers=";
NSString *const semicolonSeparator = @";";
NSString *const colonSeparator = @":";
NSString *const caretSeparator = @"^";
NSString *const commaSeparator = @",";
NSString *const viewTypeImage = @"img";

@implementation I2ICustomBack

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    
    if (self) {
        linkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
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
    customURL = @"";
    
}

//  This method is called every time the widget is recreated, which could be during initialization, when a layout or panel changes, or when the widget’s source selector is changed.
-(void)recreateWidget {
    
    [self reInitDataModels];
    linkView.userInteractionEnabled = YES;
    //  Code to add tap gesture
    UITapGestureRecognizer *linkTapGestureReco = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(handleEvent:)];
    [linkView addGestureRecognizer:linkTapGestureReco];
    [self addSubview:linkView];
    
}

//  Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    
    //  Update the widget's data.
    [self.widgetHelper reInitDataModels];
    // Keep a reference to the grid's data.
    _dataModel = (MSIModelData *)[widgetHelper dataProvider];
    [self readData];
    
}

#pragma mark Data Retrieval Method

-(void)readData {
    
    NSMutableArray *current = _dataModel.metricHeaderArray;
    MSIMetricHeader *metricHeader = [current objectAtIndex:0];
    
    // First metric is the base URL that needs prompt answers to be appended
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    customURL = [[NSMutableString alloc] initWithString:metricValue.rawValue];
    objectId = [[metricValue.rawValue componentsSeparatedByString:@"="] lastObject];
    
    // Second metric indicates the view type, i.e., image or text
    metricHeader = [current objectAtIndex:1];
    metricValue = [metricHeader.elements objectAtIndex:0];
    linkViewType = metricValue.rawValue;
    
    // Third metric is either the URL of the image to be displayed or the formatted text
    metricHeader = [current objectAtIndex:2];
    metricValue = [metricHeader.elements objectAtIndex:0];
    linkViewDisplay = metricValue.rawValue;
    
    if ([linkViewType isEqualToString:viewTypeImage]) {
        
        NSURL *linkImageURL = [[NSURL alloc] initWithString:linkViewDisplay];
        NSData *linkImageData = [[NSData alloc] initWithContentsOfURL:linkImageURL];
        UIImage *linkImage = [[UIImage alloc] initWithData:linkImageData];
        UIImageView *linkImageView = [[UIImageView alloc] initWithFrame:linkView.frame];
        linkImageView.image = linkImage;
        
        [linkView addSubview:linkImageView];
        
    }
    else {
        
        UILabel *linkLabel = [[UILabel alloc] initWithFrame:linkView.frame];
        linkLabel.text = linkViewDisplay;
        
        MSIPropertyGroup *propertyGroup = metricValue.format;
        
        // These variables set font properties for the control labels.
        NSString *fontFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                                         propertyID:FontFormattingName];
        int fontSize = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                   propertyID:FontFormattingSize] intValue];
        linkLabel.font = [UIFont fontWithName:fontFace size:fontSize];
        
        int fontBold = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                   propertyID:FontFormattingBold] intValue];
        int fontItalic = [[propertyGroup propertyByPropertySetID:FormattingFont
                                                     propertyID:FontFormattingItalic] intValue];
        
        if (fontBold == -1) {
            
            linkLabel.font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Bold", fontFace]
                                             size:fontSize];
            if (fontItalic == -1) linkLabel.font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-BoldItalic", fontFace]
                                                                   size:fontSize];
        }
        else {
            
            if (fontItalic == 1) linkLabel.font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Italic", fontFace]
                                                                  size:fontSize];
            
        }
        int horizontalAlign = [[propertyGroup propertyByPropertySetID:FormattingAlignment
                                                          propertyID:AlignmentFormattingHorizontal] intValue];
        
        // Horizontal alignment for the control's label.
        switch (horizontalAlign) {
            case 4:
                linkLabel.textAlignment = NSTextAlignmentRight;
                break;
            case 3:
                linkLabel.textAlignment = NSTextAlignmentCenter;
                break;
            default:
                linkLabel.textAlignment = NSTextAlignmentLeft;
                break;
        }
        
        linkLabel.textColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                              propertyID:FontFormattingColor]];
        linkLabel.numberOfLines = 0;
        linkLabel.lineBreakMode = NSLineBreakByWordWrapping;
        // Uncomment the following line for debugging
//        linkLabel.backgroundColor = [UIColor lightGrayColor];
        [linkView addSubview:linkLabel];
        
    }
    
    elementPromptAnswers = @"";
    valuePromptAnswers = @"";
    int outerLoopCounter = 0;
    // Para-metrics for the prompts start at from fourth metric in the grid
    for (int i = 3; i < current.count; i+=2) {
        
        int promptType = [[[[[current objectAtIndex:i] elements] objectAtIndex:0] rawValue] intValue];
        int maxAnswers = [[[[[current objectAtIndex:i + 1] elements] objectAtIndex:0] rawValue] intValue];
        
        if (maxAnswers > self.dataModel.rowCount)
            maxAnswers = (int) self.dataModel.rowCount;
        
        if (promptType == 0) {
            
            MSIAttributeHeader *attributeHeader = [_dataModel.rowHeaderArray objectAtIndex:outerLoopCounter];
            MSIAttribute *attribute = [attributeHeader attribute];
            NSString *attributeGUID = attribute.displayInfoID;
            // Element Prompt
            //
            // Each individual prompt answer is in the form of GUID;ElementID[;ElementID]^DisplayName
            // ElementID consists of two identifiers, GUID:value, and value can be either the element ID or description
            // The DisplayName for an element prompt is optional, but without it,
            // the element name does not show up in the prompt details pane in the report page.
            //
            // The following example represents a URL that answers two element prompts.
            // The URL provides three different elements to answer the first prompt
            // and only one element to answer the second prompt:
            // GUID1;ElemID1a%5eDisplayName1a;ElemID1b%5eDisplayName1b;ElemID1c%5eDisplayName1c,GUID2;ElemID2%5eDisplayName2
            //
            elementPromptAnswers = [elementPromptAnswers stringByAppendingString:attributeGUID];
            for (int j = 0; j < maxAnswers; j++) {
                
                // When there are multiple answers to the same prompt, each answer is separated by a semi-colon.
                elementPromptAnswers = [elementPromptAnswers stringByAppendingString:semicolonSeparator];
                
                MSIAttributeElement *attributeElement = (MSIAttributeElement *)[[attributeHeader elements] objectAtIndex:j];
                NSString *elementID = [[attributeElement.elementID componentsSeparatedByString:colonSeparator] lastObject];
                elementID = [[attributeGUID stringByAppendingString:colonSeparator] stringByAppendingString:elementID];
                elementPromptAnswers = [elementPromptAnswers stringByAppendingString:elementID];
                
                // When the display for an element is included, it is separated from the GUID:value by the caret.
                elementPromptAnswers = [elementPromptAnswers stringByAppendingString:caretSeparator];
                NSString *elementDisplay = attributeElement.rawValue;
                elementPromptAnswers = [elementPromptAnswers stringByAppendingString:elementDisplay];
            }
            // When there are multiple element prompts, each prompt answer is separated by a comma.
            elementPromptAnswers = [elementPromptAnswers stringByAppendingString:commaSeparator];
            
        }
        else {
            
            // Value Prompt
            //
            // Because value prompt answers do not have an identifier that allows them to be matched with
            // the actual prompts, the order of the prompt answers is very important.
            // It determines the order in which prompts are answered.
            //
            // If you want to skip an object prompt answer when there are multiple object prompts,
            // simply use the caret character, without anything else, to signify an unfurnished prompt answer.
            // An unfurnished prompt answer for the first prompt would be represented by a single caret character,
            // while an unfurnished prompt answer for subsequent prompts would be represented by two caret character
            //      — one delimiting the previous furnished prompt answer
            //      - one delimiting the unfurnished prompt answer.
            //
            MSIAttributeHeader *attributeHeader = [_dataModel.rowHeaderArray objectAtIndex:outerLoopCounter];
            for (int j = 0; j < maxAnswers; j++) {
                
                if (![valuePromptAnswers isEqualToString:@""]) {
                    valuePromptAnswers = [valuePromptAnswers stringByAppendingString:commaSeparator];
                }
                NSString *valueElement = [[[attributeHeader elements] objectAtIndex:j] rawValue];
                valuePromptAnswers = [valuePromptAnswers stringByAppendingString:valueElement];
            }
            // When there are multiple value prompt answers, each individual answer is separated by a caret.
            valuePromptAnswers = [valuePromptAnswers stringByAppendingString:caretSeparator];
            
        }
        outerLoopCounter++;
        
    }
    // Remove last characters from the prompt strings
    if (![elementPromptAnswers isEqualToString:@""]) {
        elementPromptAnswers = [elementPromptAnswers substringToIndex:elementPromptAnswers.length - 1];
        customURL = [customURL stringByAppendingString:elementPromptPrefix];
        customURL = [customURL stringByAppendingString:elementPromptAnswers];
    }
    
    if (![valuePromptAnswers isEqualToString:@""]) {
        valuePromptAnswers = [valuePromptAnswers substringToIndex:valuePromptAnswers.length - 1];
        customURL = [customURL stringByAppendingString:valuePromptPrefix];
        customURL = [customURL stringByAppendingString:valuePromptAnswers];
    }
    
}

#pragma mark Converts BGR value to UIColor object
-(UIColor *)colorConvertor:(NSString *)strColor {
    
    //  We got B G R here, but we need RGB
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF) / 255.0f
                           green:((bgrValue & 0xFF00) >> 8) / 255.0f
                            blue:((bgrValue & 0xFF0000) >> 16) / 255.0f
                           alpha:1.0f];
    
}

#pragma mark handleEvent Methods
//  When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    
//    MSIProjectInfo *projectInfo = [MSIProjectInfo defaultProjectInfo];
//    [[MSICacheManager manager] retrieveCacheForObjectId:objectId
//                                           withPriority:MSMCachePriorityHigh
//                              withElementsPromptAnswers:elementPromptAnswers
//                                  andValuePromptAnswers:nil
//                                         andProjectInfo:projectInfo
//                                      completionHandler:^(MSIDocumentCache *documentCache, NSError *error) {
//                                          if (documentCache == nil) {
//                                              vcRetriever = [[MSTRVCRetriever alloc] initWithURLString:customURL
//                                                                                              errorRef:nil];
//                                              [vcRetriever setDelegate:self];
//                                              [vcRetriever start];
//                                          }
//                                          else {
//                                              NSLog(@"Works!");
//                                              vcRetriever = [[MSTRVCRetriever alloc] initWithURLString:@"i2idev://?evt=3124"
//                                                                                              errorRef:nil];
//                                              [vcRetriever setDelegate:self];
//                                              [vcRetriever start];
//                                          }
//                                      }];
    vcRetriever = [[MSTRVCRetriever alloc] initWithURLString:@"i2idev://?evt=3124"
                                                    errorRef:nil];
    [vcRetriever setDelegate:self];
    [vcRetriever start];
}

#pragma mark MSTRVCRetrieverDelegates
/**
 This method is called when the VCRetriever has fetched a VC
 */
- (void)retriever:(MSTRVCRetriever *)retriever didFetchVC:(UIViewController *)viewController {
    
    [[MSIGeneric applicationNavigationController] pushViewController:viewController
                                                            animated:YES];
    vcRetriever = nil;
    
}

/**
 This method is called when the VCRetriever encountered an Error while fetching the VC
 */
- (void)retriever:(MSTRVCRetriever *)retriever didFailWithError:(MSTRError *)error {
    
    [[MSIGeneric getMSTRAppContext] displayErrorInAlertViewWithTitle:@"Error Retrieving VC"
                                                             message:[error localizedDescription]
                                                            delegate:nil];
    vcRetriever = nil;
    
}

@end
