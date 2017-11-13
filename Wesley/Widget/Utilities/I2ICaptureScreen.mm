//
//  I2ICaptureScreen.mm
//  c100Benchmarking
//
//  Created by Neha Salankar on 04/05/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2ICaptureScreen.h"

@implementation I2ICaptureScreen

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel
       withCommanderDelegate:_commander
                   withProps:_props];
    
    if (self) {
        
        //  Initialize all widget's subviews as well as any instance variable
        objCapture = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        objCapture.image = [UIImage imageNamed:@"Capture.png"];
        objCapture.contentMode = UIViewContentModeScaleAspectFit;
        objCapture.userInteractionEnabled = YES;
        [self addSubview:objCapture];
        
        //  Code to add tap gesture
        UITapGestureRecognizer *objTG = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(buttonTapped)];
        [objCapture addGestureRecognizer:objTG];
        
    }
    return self;
    
}

-(void)buttonTapped {
    
    UIImage *image = [self convertScreenToImage];
    UIGraphicsEndImageContext();
    NSData * data = UIImagePNGRepresentation(image);
    UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:data], nil, nil, nil);
    objCapture.image = [UIImage imageNamed:@"Captured.png"];
    [NSTimer scheduledTimerWithTimeInterval:2.5f
                                     target:self
                                   selector:@selector(handleTimer)
                                   userInfo:nil
                                    repeats:NO];
    
}

-(UIImage *)convertScreenToImage {
    
    UIGraphicsBeginImageContext(self.window.bounds.size);
    [self.window drawViewHierarchyInRect:self.window.bounds
                      afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
    
}

-(void)handleTimer {
    
    objCapture.image = [UIImage imageNamed:@"Capture.png"];
    
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

@end
