//
//  I2IControls.h
//  c100Benchmarking
//
//  Created by Pradeep Yadav on 05/03/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IControls_h
#define I2IControls_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PlistData.h"

@interface I2IControls : NSObject {

    UILabel *lblValue;
    // Unique ID of the control
    NSString *uid;
    // Type of the control i.e Slider = 1, Textbox = 2, Toggle = 3, Radio = 4 , Reset = 5, Emit = 6 etc...
    int type;
    // Default value of the control
    NSString *defaultCV;
    // Minimum value that the control can take.
    NSString *min;
    // Maximum value of the control.
    NSString *max;
    // Value for increments/decrements of control
    NSString *step;
    // Suffix for the labels.
    NSString *suffix;
    // Position for control
    NSString *position;
    // Font face for the label.
    NSString *fFace;
    // Font size of the label.
    NSString *fSize;
    NSMutableArray *colors;
    // Number Formatting for display
    NSString *category;
    NSString *format;
    NSString *align;
    
}
@property (retain,nonatomic) NSString *uid;
@property (assign,nonatomic) int type;
@property (retain,nonatomic) NSString *defaultCV;
@property (retain,nonatomic) NSString *min;
@property (retain,nonatomic) NSString *max;
@property (retain,nonatomic) NSString *step;
@property (retain,nonatomic) NSString *suffix;
@property (retain,nonatomic) NSString *position;
@property (retain,nonatomic) NSString *fFace;
@property (retain,nonatomic) NSString *fSize;
@property (retain,nonatomic) NSMutableArray *colors;
@property (retain,nonatomic) NSString *category;
@property (retain,nonatomic) NSString *format;
@property (retain,nonatomic) NSString *align;

@end

#endif
