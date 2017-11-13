//
//  I2ISendEmail.m
//  c100Benchmarking
//
//  Created by Deepika Nahar on 04/02/17.
//  Copyright © 2017 i2iLogic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MicroStrategyMobileSDK/MSIGeneric.h"
#import "I2ISendEmail.h"
#import "RememberRecipient.h"

@implementation I2ISendEmail
@synthesize picker;
@synthesize rootView;
@synthesize transparentRect;
@synthesize hideCancelButton;
@synthesize txtTo;
@synthesize txtSubject;
@synthesize txtNote;
@synthesize selectedDomain;
@synthesize inputVC;
@synthesize disclaimer;
@synthesize arrDomains;
@synthesize rememberSwitch;

-(void)openMailComposingWindowWithAttachment:(id)contents whichType:(NSString *)type withPath:(NSString *)path withDisclaimer:(NSString *)disclaimerMsg withDomains:(NSString *)emailDomains withCompany:(NSString *)company {
    
    disclaimer = disclaimerMsg;
    
    //Show intermediate view
    [self readInputsWithDomains:emailDomains withImage:contents];
    
    picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    NSDate *todayDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *convertedDateString = [dateFormatter stringFromDate:todayDate];
    
    [picker setSubject:[NSString stringWithFormat:@"%@_%@", company, convertedDateString]];
    
    if ([type isEqualToString:@"Image"]) {
        
        NSData *myData = UIImagePNGRepresentation(contents);
        [picker addAttachmentData:myData
                         mimeType:@"image/png"
                         fileName:@"Image.png"];
        
    }
    else {
        
        [picker addAttachmentData:[NSData dataWithContentsOfFile:contents]
                         mimeType:@""
                         fileName:[path lastPathComponent]];
        
    }
    
    //Code to attach disclaimer as .txt
    
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/disclaimer.txt",
                          documentsDirectory];
    
    //create content - four lines of text
    //NSString *content = @"One\nTwo\nThree\nFour\nFive";

    //save content to the documents directory
    /*BOOL isSuccess = */[disclaimer writeToFile:fileName
              atomically:NO
                encoding:NSUTF16StringEncoding
                   error:nil];
    NSData *noteData = [NSData dataWithContentsOfFile:fileName];
    [picker addAttachmentData:noteData
                     mimeType:@"text/plain"
                     fileName:@"Disclaimer.txt"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //Delete the .txt file from device
    [fileManager removeItemAtPath:fileName error:NULL];
    
    transparentRect = [[UIView alloc] initWithFrame:CGRectMake(0, picker.navigationBar.frame.size.height, picker.view.frame.size.width, picker.view.frame.size.height)];
    transparentRect.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
    
    [picker.view addSubview:transparentRect];
    
    hideCancelButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, picker.view.frame.size.width / 11, picker.navigationBar.frame.size.height)];
    hideCancelButton.backgroundColor = [UIColor colorWithRed:0.97
                                                       green:0.97
                                                        blue:0.97
                                                       alpha:1];
    
    //add a UIButton to hideCancelButton View mimicking the functionality of Delete draft
    UIButton *btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCancel addTarget:self
                  action:@selector(discardDraft:)
        forControlEvents:UIControlEventTouchUpInside];
    [btnCancel setTitle:@"Cancel"
               forState:UIControlStateNormal];
    btnCancel.frame = CGRectMake(0, 0, picker.view.frame.size.width / 11, picker.navigationBar.frame.size.height);
    [btnCancel setBackgroundColor:[UIColor colorWithRed:0.97
                                                  green:0.97
                                                   blue:0.97
                                                  alpha:1]];
    [btnCancel setTitleColor:[UIColor colorWithRed:0.08
                                             green:0.52
                                              blue:1.0
                                             alpha:1]
                    forState:UIControlStateNormal];
    [btnCancel.titleLabel setFont:[UIFont boldSystemFontOfSize:[UIFont buttonFontSize]]];
    
    [hideCancelButton addSubview:btnCancel];
    
    [picker.view addSubview:hideCancelButton];
    
}

-(void)readInputsWithDomains:(NSString *)emailDomains withImage:(id)contents {
    
    inputVC = [[UIViewController alloc] init];
    UIView *inputView = [[UIView alloc] init];
    
    inputVC.view = inputView;
    
    //Add a subview with screenshot
    UIView *backgroundImageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    UIImage *bgImage = [UIImage imageWithData: UIImagePNGRepresentation(contents)];
    UIImageView *bgImageview = [[UIImageView alloc] initWithImage:bgImage];
    
    [backgroundImageView addSubview: bgImageview];
    [inputView addSubview:backgroundImageView];
    
    //Add a subview with gray bg color and transparency
    UIView *transparentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [transparentView setBackgroundColor: [[UIColor lightGrayColor] colorWithAlphaComponent:0.5f]];
    
    [inputView addSubview:transparentView];
    
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 275, [UIScreen mainScreen].bounds.size.height / 2 - 255, 550, 300)];
    [mainView setBackgroundColor:[UIColor whiteColor]];
    mainView.layer.cornerRadius = 13.0;
    mainView.layer.borderColor = [[UIColor colorWithRed:0.97
                                                 green:0.97
                                                  blue:0.97
                                                 alpha:1] CGColor];
    mainView.layer.borderWidth = 2.0;
    [inputView addSubview:mainView];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 275, [UIScreen mainScreen].bounds.size.height / 2 - 255, 550, 40)];
    
    //To apply rounded corners only to topLeft and topRight of naviation bar
    CALayer *capa = navBar.layer;
    CGRect bounds = capa.bounds;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                         cornerRadii:CGSizeMake(13.0, 13.0)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    
    [capa addSublayer:maskLayer];
    capa.mask = maskLayer;
    
    //To add buttons (Cancel and Next to the navigation bar)
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(cancelClicked:)];
    navItem.leftBarButtonItem = leftButton;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(showEmailPopover:)];
    navItem.rightBarButtonItem = rightButton;
    
    navBar.items = @[ navItem ];
    
    [inputView addSubview:navBar];
    
    //Label 'To:'
    UILabel *lblTo = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 255, [UIScreen mainScreen].bounds.size.height / 2 - 205, 50, 30)];
    lblTo.text = @"To:";
    lblTo.textColor = [UIColor lightGrayColor];
    [lblTo setFont:[UIFont systemFontOfSize:16]];
    [inputView addSubview:lblTo];
    
    //Textfield for email
    txtTo = [[UITextField alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 215, [UIScreen mainScreen].bounds.size.height / 2 - 205, 480, 30)];
    txtTo.delegate = self;
    txtTo.placeholder = @"Enter email";
    txtTo.autocorrectionType = UITextAutocorrectionTypeNo;
    [txtTo setFont:[UIFont systemFontOfSize:16]];
    txtTo.delegate = self;
    [inputView addSubview:txtTo];
    
    //Add a cross button to clear the contents
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2 + 90, [UIScreen mainScreen].bounds.size.height / 2 - 200, 20, 20);
    [clearBtn setBackgroundImage:[UIImage imageNamed:@"Cross.png"]
                        forState:UIControlStateNormal];
    
    [clearBtn addTarget:self
                 action:@selector(clearRecipients:)
       forControlEvents:UIControlEventTouchUpInside];
    [inputView addSubview:clearBtn];
    
    //Add a toggle button here for remember me
    rememberSwitch = [[UISwitch alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 + 130, [UIScreen mainScreen].bounds.size.height / 2 - 205, 40, 15)];
    [rememberSwitch addTarget:self
                       action:@selector(changeSwitch:)
             forControlEvents:UIControlEventValueChanged];
    [inputView addSubview:rememberSwitch];
    
    //Label for Remember
    UILabel *lblRemember = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 + 190, [UIScreen mainScreen].bounds.size.height/2 - 205, 80, 30)];
    lblRemember.text = @"Remember";
    lblRemember.textColor = [UIColor lightGrayColor];
    [lblRemember setFont:[UIFont systemFontOfSize:16]];
    [inputView addSubview:lblRemember];
    
    //Seperator line
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 255, [UIScreen mainScreen].bounds.size.height/2 - 175, 380, 1)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [inputView addSubview:lineView];
    
    arrDomains = [emailDomains componentsSeparatedByString:@","];

    //Radio buttons to indicate domains
    for (int i  = 0; i < arrDomains.count; i++) {
        
        UIButton *radioEmail = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [radioEmail setTag: 444 * 10 + (i + 1)];
        
        radioEmail.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 255 + (183 * i), [UIScreen mainScreen].bounds.size.height / 2 - 165, 30, 30);
        
        if(i == 0) {
            [radioEmail setBackgroundImage:[UIImage imageNamed:@"RadioChecked.png"]
                                   forState:UIControlStateNormal];
            selectedDomain = [arrDomains objectAtIndex:i];
        }
        else {
            [radioEmail setBackgroundImage:[UIImage imageNamed:@"RadioUncheck.png"]
                                   forState:UIControlStateNormal];
        }
        
        
        [radioEmail addTarget:self
                        action:@selector(radiobuttonSelected:)
              forControlEvents:UIControlEventTouchUpInside];
        
        [self.domainsArray addObject:radioEmail];
        [inputView addSubview:radioEmail];
        
        UILabel *lblEmailDomain = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 220 + (183 * i), [UIScreen mainScreen].bounds.size.height / 2 - 165, 148, 30)];
        lblEmailDomain.text = [arrDomains objectAtIndex:i];
        lblEmailDomain.textColor = [UIColor blackColor];
        lblEmailDomain.textAlignment = NSTextAlignmentLeft;
        [lblEmailDomain setFont:[UIFont systemFontOfSize:14]];
        
        [inputView addSubview:lblEmailDomain];
        
     }

    //Seperator line
    lineView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 255, [UIScreen mainScreen].bounds.size.height / 2 - 130, 507, 1)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [inputView addSubview:lineView];
    
    //Label 'Subject:'
    UILabel *lblSubject = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 255, [UIScreen mainScreen].bounds.size.height / 2 - 125, 70, 30)];
    lblSubject.text = @"Subject:";
    lblSubject.textColor = [UIColor lightGrayColor];
    [lblSubject setFont:[UIFont systemFontOfSize:16]];
    [inputView addSubview:lblSubject];
    
    //Textfield for email
    txtSubject = [[UITextField alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 180, [UIScreen mainScreen].bounds.size.height / 2 - 125, 480, 30)];
    txtSubject.placeholder = @"Enter subject";
    txtSubject.autocorrectionType = UITextAutocorrectionTypeNo;
    [txtSubject setFont:[UIFont systemFontOfSize:16]];
    [inputView addSubview:txtSubject];
    
    //Seperator line
    lineView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 255, [UIScreen mainScreen].bounds.size.height / 2 - 90, 507, 1)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [inputView addSubview:lineView];
    
    txtNote = [[UITextView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 255, [UIScreen mainScreen].bounds.size.height / 2 - 85, 480, 100)];
    [txtNote setFont:[UIFont systemFontOfSize:14]];
    [inputView addSubview:txtNote];
    
    //Set the saved values if Remember was clicked
    
    //Check if Remember is 'ON'
    if ([[RememberRecipient sharedGlobalInstance] getAppCheckingCondtion:REMEMBERME]) {
        
        txtTo.text = [NSString stringWithFormat:@"%@", [[RememberRecipient sharedGlobalInstance] getRecipient:RECIPIENT]];
        
        NSString *thisDomain = [[RememberRecipient sharedGlobalInstance] getRecipient:EMAILDOMAIN];
        NSUInteger index = [arrDomains indexOfObject:thisDomain];
        NSString *selectedRadioTag = [NSString stringWithFormat:@"%@%ld", @"444", (long) (index + 1)];
        for (UIView *view in [inputVC.view subviews]) {
            
            NSString *tag = [NSString stringWithFormat:@"%ld", (long) view.tag];
            if([tag isEqualToString:selectedRadioTag]) {
                
                UIButton *radioBtn = (UIButton *) view;
                [radioBtn setBackgroundImage:[UIImage imageNamed:@"RadioChecked.png"]
                                    forState:UIControlStateNormal];
                
                NSString *selectedTag = [[NSString stringWithFormat:@"%ld", (long) [radioBtn tag]] substringFromIndex:3];
                selectedDomain = [arrDomains objectAtIndex:(selectedTag.integerValue - 1)];
                
            }
            else if([tag hasPrefix:@"444"]) {
                
                UIButton *radioBtn = (UIButton *) view;
                [radioBtn setBackgroundImage:[UIImage imageNamed:@"RadioUncheck.png"]
                                    forState:UIControlStateNormal];
                
            }
            
        }
    
        //Set remember toggle to 'ON'
        rememberSwitch.on = YES;
    }
    
    rootView = [[UIApplication sharedApplication].delegate window].rootViewController;
    [[UIApplication sharedApplication].delegate window].rootViewController = self;
    [self presentViewController:inputVC animated:YES completion:nil];
    
}

-(void)radiobuttonSelected:(id)sender {
    
    UIButton *radioBtn = (UIButton *) sender;
    [radioBtn setBackgroundImage:[UIImage imageNamed:@"RadioChecked.png"]
                   forState:UIControlStateNormal];
    
    NSString *tag;
    for (UIView *view in [inputVC.view subviews]) {
        tag = [NSString stringWithFormat:@"%ld", (long)view.tag];
        if([tag hasPrefix:@"444"] && view.tag != [sender tag]) {
            UIButton *btn = (UIButton *) view;
            [btn setBackgroundImage:[UIImage imageNamed:@"RadioUncheck.png"]
                           forState:UIControlStateNormal];
        }
    }
    tag = [[NSString stringWithFormat:@"%ld", (long) [sender tag]] substringFromIndex:3];
    selectedDomain = [arrDomains objectAtIndex:(tag.integerValue - 1)];
    
}

-(void)showEmailPopover:(id)sender {
    
    //Check if Remember is ON -> Save to NSUserDefaults
    if ([[RememberRecipient sharedGlobalInstance] getAppCheckingCondtion:REMEMBERME]) {
        
        //Save the recipients in NSUserDefaults
        [[RememberRecipient sharedGlobalInstance] saveRecipient:txtTo.text
                                                        withKey:RECIPIENT];
        [[RememberRecipient sharedGlobalInstance] saveRecipient:selectedDomain
                                                        withKey:EMAILDOMAIN];
        
    }
    
    //Validations for Textfield and Radio buttons
    if (![txtTo hasText]) {
        
        //show alert
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                       message:@"Please enter email id."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
        [alert addAction:ok];
        [inputVC presentViewController:alert
                              animated:YES
                            completion:nil];
        
    }
    else {
        
        //Check if it is valid using RegEx
        NSString *emailRegex = @"[A-Z0-9a-z]+([._%+-]{1}[A-Z0-9a-z]+)*";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        if (![emailTest evaluateWithObject:txtTo.text]) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                           message:@"Please enter a valid email id."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
            [alert addAction:ok];
            [inputVC presentViewController:alert
                                  animated:YES
                                completion:nil];
            
        }
        else {
            
            //Read the text field and radio button values to set the to field and subject
            [picker setToRecipients:@[[NSString stringWithFormat:@"%@%@",txtTo.text,selectedDomain]]];
            
            if([txtNote hasText]) {
            
                NSString *emailBody = [NSString stringWithFormat:@"%@", txtNote.text];
                [picker setMessageBody:emailBody
                                isHTML:YES];
                
            }
            
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
            [self presentViewController:picker
                               animated:YES
                             completion:nil];
            
        }
        
    }
    
    if ([txtSubject hasText]) {
        
        [picker setSubject:txtSubject.text];
        
    }

}

-(void)clearRecipients:(id)sender {
    
    txtTo.text = @"";
    
}

-(void)cancelClicked:(id)sender {
    
    //Reset NSUserDefaults
    [[RememberRecipient sharedGlobalInstance] saveAppCheckingCondition:NO
                                                               withKey:REMEMBERME];
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
    [[UIApplication sharedApplication].delegate window].rootViewController = rootView;
    
}

//-(void) discardDraft:(id)sender {
-(void)discardDraft:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
    [[UIApplication sharedApplication].delegate window].rootViewController = rootView;
    
}

-(void)changeSwitch:(id)sender {
    
    if ([sender isOn]) {
        
        //TO DO - Call to: Separate Module to Validate email id -> if valid then only save in NSUserDefaults
        [[RememberRecipient sharedGlobalInstance] saveAppCheckingCondition:YES
                                                                   withKey:REMEMBERME];
        
        //Save the bool value
        /*[[RememberRecipients sharedGlobalInstance] save_appCheckingConditionPreferenceWithValue:YES withKey:REMEMBER_ME];
      
        //Save the recipients in NSUserDefaults
        [[RememberRecipients sharedGlobalInstance] save_recipients:txtTo.text withKey:RECIPIENTS];
        [[RememberRecipients sharedGlobalInstance] save_recipients:selectedDomain withKey:EMAIL_DOMAIN];
         */
        
    }
    else {
        
        [[RememberRecipient sharedGlobalInstance] saveAppCheckingCondition:NO
                                                                   withKey:REMEMBERME];
        //Delete the recipients from NSUserDefaults
        
    }
    
}

#pragma mark - MFMailComposeViewController delegate
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    switch (result) {
            
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
            
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
            
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
            
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
            
        default:
            break;
            
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES
                             completion:nil];
    [[UIApplication sharedApplication].delegate window].rootViewController = rootView;
    
}

#pragma mark - UITextField delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField {
    
    rememberSwitch.on = NO;
    [[RememberRecipient sharedGlobalInstance] saveAppCheckingCondition:NO
                                                               withKey:REMEMBERME];
    
}

@end
