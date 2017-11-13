//
//  I2ICaptureScreen.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 04/05/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2ICaptureScreen_h
#define I2ICaptureScreen_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MicroStrategyMobileSDK/MSIWidgetViewer.h>
#import <MicroStrategyMobileSDK/MSIWidgetHelper.h>

@interface I2ICaptureScreen : MSIWidgetViewer {
    
    UIImageView *objCapture;
    
}

@end

#endif
