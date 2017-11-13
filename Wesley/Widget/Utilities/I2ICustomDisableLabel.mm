//
//  I2ICustomURL.mm
//  c100CapitalStructure
//
//  Created by Deepika Nahar on 12/07/17.
//  Modified by Deepika Nahar on 1/10/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2ICustomDisableLabel.h"
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

@implementation I2ICustomDisableLabel

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel withCommanderDelegate:_commander withProps:_props];
    
    if (self) {
        linkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 30)];
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
    
    //NSMutableArray *current = _dataModel.metricHeaderArray;
    NSNumber *rowCount = [NSNumber numberWithInteger:_dataModel.rowCount];
    
    if(rowCount.intValue == 0) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"You must select a least 1 peer before proceeding to the Peer Portfolio screen.  Failure to select at least 1 peer may cause the app to crash."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        /*UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning"
                                                                                 message:@"You must select a least 1 peer before proceeding to the Peer Portfolio screen.  Failure to select at least 1 peer may cause the app to crash."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        */
        [linkView addSubview:alert];
        [alert show];
        
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
    
    [self recreateWidget];
    if(ipEventName != nil) {
        MSIProjectInfo *projectInfo = [MSIProjectInfo defaultProjectInfo];
        [[MSICacheManager manager] deleteCachesForObjectId:objectId
                                               projectInfo:projectInfo];
    }
    
}
@end
