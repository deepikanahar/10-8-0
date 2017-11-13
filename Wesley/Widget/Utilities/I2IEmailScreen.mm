//
//  I2IEmailScreen.mm
//  c100Benchmarking
//
//  Created by Deepika Nahar on 04/02/17.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2iLogic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2IEmailScreen.h"
#import "I2ISendEmail.h"

@implementation I2IEmailScreen

UIImageView *objCapture;

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel
       withCommanderDelegate:_commander
                   withProps:_props];
    
    if (self) {
        
        //  Initialize all widget's subviews as well as any instance variable
        //  Code to add image view
        objCapture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        objCapture.image = [UIImage imageNamed:@"Email.png"];
        objCapture.contentMode = UIViewContentModeScaleAspectFit;
        objCapture.userInteractionEnabled = YES;
        [self addSubview:objCapture];
        
        //  Code to add tap gesture
        UITapGestureRecognizer *objTG = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(buttonTapped)];
        [objCapture addGestureRecognizer:objTG];
        
        [self readData];
        
    }
    return self;
    
}

-(void)buttonTapped {
    
    UIImage *img = [self screenshotOftheView];
    I2ISendEmail *sendEmail = [[I2ISendEmail alloc] init];
    [sendEmail openMailComposingWindowWithAttachment:img
                                           whichType:@"Image"
                                            withPath:nil
                                      withDisclaimer:self.disclaimer
                                         withDomains:self.emailDomains
                                         withCompany:self.companyName];
    
}

-(UIImage *)screenshotOftheView {
    
    /*UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
     CGRect rect = [keyWindow bounds];
     UIGraphicsBeginImageContext(rect.size);
     CGContextRef context = UIGraphicsGetCurrentContext();
     [keyWindow.layer renderInContext:context];
     UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     return img;*/
    
    UIGraphicsBeginImageContext(self.window.bounds.size);
    [self.window drawViewHierarchyInRect:self.window.bounds
                      afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
    
}

-(UIImage *)convertScreenToImage {
    
    UIGraphicsBeginImageContext(self.window.bounds.size);
    [self.window drawViewHierarchyInRect:self.window.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
    
}

//  This method is used to clear all the widget’s views in order to save memory. It is called the first time the widget is loaded, and later if the widget needs to be recreated or deleted.
-(void)cleanViews {
}

//  This method is called every time the widget is recreated, which could be during initialization, when a layout or panel changes, or when the widget’s source selector is changed.
-(void)recreateWidget {
}

//  Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
}

-(void)readData {
    
    self.modelData = (MSIModelData *)[widgetHelper dataProvider];
    
    // Always expect this metric value to be the disclaimer
    NSMutableArray *row = [self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                       andRowIndex:0];
    self.disclaimer = [[row objectAtIndex:0] headerValue];
    
    NSMutableArray *current = self.modelData.metricHeaderArray;
    MSIMetricHeader *metricHeader =[current objectAtIndex:0];
    
    // Always expect first metric value to be disclaimer
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    self.emailDomains = metricValue.rawValue;

    // Always expect second metric value to be company name
    self.companyName = [[[self.modelData arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                      andRowIndex:0] objectAtIndex:3] rawValue];
    
}

@end
