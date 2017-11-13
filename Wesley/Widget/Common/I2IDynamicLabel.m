//
//  I2IDynamicLabel.m
//  c100Benchmarking
//
//  Created by Neha Salankar on 25/03/15.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "I2IDynamicLabel.h"

@implementation I2IDynamicLabel

@synthesize lblValue;
@synthesize position;
@synthesize key;
@synthesize formula;
// Font parameters
@synthesize fFace;
@synthesize fSize;
@synthesize fColor;
@synthesize nColor;
@synthesize fBold;
@synthesize fItalic;
@synthesize fUnderline;
// Text alignment parameters
@synthesize align;
@synthesize wrap;
// Number format parameters
@synthesize category;
@synthesize format;
// Padding parameters
@synthesize leftPad;
@synthesize rightPad;
@synthesize topPad;
@synthesize bottomPad;

-(UIView*)initializeLabel:(CGRect)frame
                  withTag:(NSInteger)intTag {
    
    UIView *uivContainer = [[UIView alloc] initWithFrame:frame];
    lblValue = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    lblValue.tag = intTag;
    lblValue.font = [UIFont fontWithName:fFace
                                    size:fSize];
    
    if ([fBold isEqualToString:@"-1"]) {
        
        lblValue.font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Bold", fFace]
                                        size:fSize];
        if ([fItalic isEqualToString:@"-1"]) lblValue.font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-BoldItalic", fFace]
                                                                             size:fSize];
    }
    else {
        
        if ([fItalic isEqualToString:@"-1"]) lblValue.font = [UIFont fontWithName:[NSString stringWithFormat:@"%@-Italic", fFace]
                                                                             size:fSize];
        
    }
    
    lblValue.textColor = fColor;
    
    //  Text Alignment Settings
    switch ([align intValue]) {
            
        case 4: lblValue.textAlignment = NSTextAlignmentRight;
            break;
            
        case 3: lblValue.textAlignment = NSTextAlignmentCenter;
            break;
            
        default: lblValue.textAlignment = NSTextAlignmentLeft;
            break;
            
    }
    
    if ([wrap isEqualToString:@"0"]) lblValue.numberOfLines = 1;
    else lblValue.numberOfLines = 0;
    
    lblValue.text = @"0";
    [lblValue sizeToFit];
    lblValue.frame = CGRectMake(0, 0, frame.size.width, lblValue.frame.size.height);
    lblValue.lineBreakMode = NSLineBreakByWordWrapping;
    //  Uncomment the line below for building and validating the label size and position
    //    lblValue.backgroundColor = [UIColor lightGrayColor];
    [uivContainer addSubview:lblValue];
    return uivContainer;
    
}

@end
