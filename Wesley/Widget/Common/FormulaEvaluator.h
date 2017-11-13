//
//  FormulaEvaluator.h
//  c100Benchmarking
//
//  Created by Neha Salankar on 30/12/14.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FormulaEvaluator : NSObject

-(NSDecimalNumber *)evaluateFormula:(NSString *)formulaToEvaluate
                     withDictionary:(NSDictionary *)metrics;

@end
