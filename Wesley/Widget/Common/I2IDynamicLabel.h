//
//  I2IDynamicLabel.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 25/03/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2IDynamicLabel_h
#define I2IDynamicLabel_h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface I2IDynamicLabel : NSObject {
    
    NSString *key;
    NSString *formula;
    NSString *position;
    UILabel *lblValue;
    //  Font parameters
    NSString *fFace;
    int fSize;
    UIColor *fColor;
    UIColor *nColor;
    NSString *fBold;
    NSString *fItalic;
    NSString *fUnderline;
    //  Text alignment parameters
    NSString *align;
    NSString *wrap;
    //  Number format parameters
    NSString *category;
    NSString *format;
    //  Padding parameters
    NSString *leftPad;
    NSString *rightPad;
    NSString *topPad;
    NSString *bottomPad;
    
}

@property (retain,nonatomic) NSString *key;
@property (strong,nonatomic) NSString *formula;
@property (strong,nonatomic) NSString *position;
@property (strong,nonatomic) UILabel *lblValue;
//  Font parameters
@property (strong,nonatomic) NSString *fFace;
@property (assign,nonatomic) int fSize;
@property (strong,nonatomic) UIColor *fColor;
@property (strong,nonatomic) UIColor *nColor;
@property (strong,nonatomic) NSString *fBold;
@property (strong,nonatomic) NSString *fItalic;
@property (strong,nonatomic) NSString *fUnderline;
//  Text alignment parameters
@property (strong,nonatomic) NSString *align;
@property (strong,nonatomic) NSString *wrap;
//  Number format parameters
@property (strong,nonatomic) NSString *category;
@property (strong,nonatomic) NSString *format;
//  Padding parameters
@property (strong,nonatomic) NSString *leftPad;
@property (strong,nonatomic) NSString *rightPad;
@property (strong,nonatomic) NSString *topPad;
@property (strong,nonatomic) NSString *bottomPad;

-(UIView*)initializeLabel:(CGRect)frame
                  withTag:(NSInteger)intTag;

@end

#endif
