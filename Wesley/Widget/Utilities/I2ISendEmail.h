//
//  I2ISendEmail.h
//  c100Benchmarking
//
//  Created by Deepika Nahar on 04/02/17.
//  Copyright © 2017 i2iLogic (Australia) Pty Ltd. All rights reserved.
//

#ifndef I2ISendEmail_h
#define I2ISendEmail_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface I2ISendEmail : UIViewController <MFMailComposeViewControllerDelegate, UITextFieldDelegate>

@property(nonatomic,strong) MFMailComposeViewController *picker;
@property(nonatomic,strong) UIViewController *rootView;
@property(nonatomic,strong) UIView *transparentRect;
@property(nonatomic,strong) UIView *hideCancelButton;
@property(nonatomic,strong) UITextField *txtTo;
@property(nonatomic,strong) UITextField *txtSubject;
@property(nonatomic,strong) UITextView *txtNote;
@property(nonatomic,strong) NSString *selectedDomain;
@property(nonatomic,strong) NSString *disclaimer;
@property(nonatomic,strong) UIViewController *inputVC;
@property(nonatomic,strong) NSArray *arrDomains;
@property(nonatomic,strong) UISwitch *rememberSwitch;
@property(nonatomic,strong) NSMutableArray *domainsArray;

-(void)openMailComposingWindowWithAttachment:(id)contents
                                   whichType:(NSString *)type
                                    withPath:(NSString *)path
                              withDisclaimer:(NSString *)disclaimer
                                 withDomains:(NSString *)emailDomains
                                 withCompany:(NSString *)company;

@end

#endif /* I2ISendEmail_h */
