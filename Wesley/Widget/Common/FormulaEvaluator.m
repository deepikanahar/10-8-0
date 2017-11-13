//
//  FormulaEvaluator.m
//  c100Benchmarking
//
//  Created by Neha Salankar on 06/05/16.
//  Modified by Pradeep Yadav on 14/03/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import "FormulaEvaluator.h"

@implementation FormulaEvaluator

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
    }
    return self;
    
}

//  This function evaluates formula using NSPredicate and NSExperssion method. It gets all variables values in formula from a dictionary.
- (NSDecimalNumber *)evaluateFormula:(NSString *)formulaToEvaluate withDictionary:(NSDictionary *)metrics {
    
    NSDecimalNumber *evaluatedValue;
    
    formulaToEvaluate = [formulaToEvaluate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([formulaToEvaluate hasPrefix:@"if"]) {
        
        NSString *substring = [formulaToEvaluate substringWithRange:NSMakeRange(3, [formulaToEvaluate length] - 4)];
        NSMutableArray *args = [[NSMutableArray alloc] initWithArray:[substring componentsSeparatedByString:@"?"]];
        
        if ([args count] == 1) {
            
            args = [[NSMutableArray alloc] initWithArray:[substring componentsSeparatedByString:@","]];
            
            if ([args count] == 1) {
                
                args = [[NSMutableArray alloc] initWithArray:[substring componentsSeparatedByString:@";"]];
                
                if ([args count] == 1) {
                    
                    args = [[NSMutableArray alloc] initWithArray:[substring componentsSeparatedByString:@":"]];
                    
                }
                
            }
            
        }
        
        NSPredicate *p = [NSPredicate predicateWithFormat:args[0]];
        BOOL passes = [p evaluateWithObject:metrics];
        
        if (passes) {
            
            evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [self evaluateFormula:args[1]
                                                                                                               withDictionary:metrics]]];
            
        }
        else {
            
            evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [self evaluateFormula:args[2]
                                                                                                               withDictionary:metrics]]];
            
        }
        
    }
    else if ([formulaToEvaluate hasPrefix:@"$"]) {
        
        //  Code to evaluate combinition of formula
        NSMutableString *mutableString = [[NSMutableString alloc] initWithString:formulaToEvaluate];
        [mutableString deleteCharactersInRange:[mutableString rangeOfString:@"$"]];
        
        NSArray *functionsFormulae = [mutableString componentsSeparatedByString:@"#"];
        NSArray *formulae = [[NSArray alloc] initWithArray:[[NSString stringWithFormat:@"%@", [functionsFormulae objectAtIndex:1]] componentsSeparatedByString:@"|"]];
        
        NSMutableArray *arrResults = [[NSMutableArray alloc]init];
        
        for(int i = 0; i < [formulae count]; i++){
            
            [arrResults addObject:[self evaluateFormula:formulae[i]
                                         withDictionary:metrics]];
            
        }
        
        //  Code to get minimum value
        if ([[functionsFormulae objectAtIndex:0] isEqualToString:@"min:"]) {
            
            NSDecimalNumber *minimumVal = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [arrResults objectAtIndex:0]]];
            NSDecimalNumber *currentVal = [NSDecimalNumber decimalNumberWithString:@"0"];
            
            for (NSString *strNum in arrResults) {
                
                currentVal = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",strNum]];
                
                if ([currentVal compare:minimumVal] == NSOrderedAscending) {
                    
                    currentVal = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",strNum]];
                    
                    if ([currentVal compare:minimumVal] == NSOrderedAscending) {
                        
                        minimumVal = currentVal;
                        
                    }
                    
                }
                
            }
            
            evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",minimumVal]];
            
        }
        //  Code to get average value
        else if ([[functionsFormulae objectAtIndex:0] isEqualToString:@"avg:"]) {
            
            NSDecimalNumber *startValue = [NSDecimalNumber decimalNumberWithString:@"0"];
            
            for (NSString *strNum in arrResults) {
                
                startValue  = [startValue decimalNumberByAdding:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", strNum]]];
                
            }
            startValue = [startValue decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%d", (int)arrResults.count]]];
            evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",startValue]];
            
        }
        //  Code to get median value
        else if ([[functionsFormulae objectAtIndex:0] isEqualToString:@"median:"]) {
            
            if (arrResults.count == 1) {
                
                evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", arrResults[0]]];
                
            }
            else {
                
                NSDecimalNumber *result = [NSDecimalNumber decimalNumberWithString:@"0"];
                NSUInteger middle;
                
                NSArray * sorted = [arrResults sortedArrayUsingSelector:@selector(compare:)];
                
                if (arrResults.count % 2 != 0) {
                    
                    middle = (sorted.count / 2);
                    result = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",[sorted objectAtIndex:middle]]];
                    
                }
                else {
                    
                    middle = (sorted.count / 2) - 1;
                    result = [[[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [sorted objectAtIndex:middle]]] decimalNumberByAdding:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [sorted objectAtIndex:middle + 1]]]] decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"2"]];
                    
                }
                
                evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@",result]];
                
            }
            
        }
        
    }
    //  Code to get PV
    else if ([formulaToEvaluate hasPrefix:@"PV#"]) {
        
        NSMutableString *str = [[NSMutableString alloc]initWithFormat:@"%@", formulaToEvaluate];
        NSRange r = [str rangeOfString:@"PV#"];
        [str deleteCharactersInRange:r];
        str = [[self removeUnwantedString:str] mutableCopy];
        NSArray *formulae = [str componentsSeparatedByString:@","];
        
        // Capital
        NSDecimalNumber *capital = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [self evaluateFormula:[formulae objectAtIndex:0]
                                                                                                                     withDictionary:metrics]]];
        
        // Interest
        NSDecimalNumber *interest = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [self evaluateFormula:[formulae objectAtIndex:1]
                                                                                                                      withDictionary:metrics]]];
        
        // Period
        NSUInteger period = [[NSString stringWithFormat:@"%@", [self evaluateFormula:[formulae objectAtIndex:2]
                                                                      withDictionary:metrics]] integerValue];
        NSDecimalNumber *presentValue = [NSDecimalNumber decimalNumberWithString:@"0"];
        
        int loopCount = (int)period;
        for (int i = 0; i <= loopCount; i++) {
            
            if (period > 0) {
                
                presentValue = [presentValue decimalNumberByAdding:[capital decimalNumberByDividingBy:[[interest decimalNumberByAdding:[NSDecimalNumber decimalNumberWithString:@"1"]] decimalNumberByRaisingToPower:period]]];
                period -= 1;
                
            }
            
        }
        
        evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", presentValue]];
        
    }
    //  Code to get evaluate CASE statement
    else if ([formulaToEvaluate hasPrefix:@"CASE#"]) {
        
        NSMutableString *strFormulae = [[NSMutableString alloc]initWithFormat:@"%@", formulaToEvaluate];
        NSRange r = [strFormulae rangeOfString:@"CASE#"];
        [strFormulae deleteCharactersInRange:r];
        NSArray *formulae = [strFormulae componentsSeparatedByString:@"#"];
        
        NSString *strCaseValue = [NSString stringWithFormat:@"%@", [self evaluateFormula:[formulae firstObject]
                                                                          withDictionary:metrics]];
        
        for (int i = 1; i < formulae.count - 1; i++) {
            
            NSArray *radioVariable = [[formulae objectAtIndex:i] componentsSeparatedByString:@":"];
            if ([strCaseValue isEqualToString:[NSString stringWithFormat:@"%@", [self evaluateFormula:[radioVariable objectAtIndex:0]
                                                                                       withDictionary:metrics]]]) {
                
                if ([NSDecimalNumber notANumber] == evaluatedValue) {
                    
                    return evaluatedValue = [NSDecimalNumber decimalNumberWithString:@"0"];
                    
                }
                
                return evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [self evaluateFormula:[NSString stringWithFormat:@"%@", [radioVariable objectAtIndex:1]]
                                                                                                                          withDictionary:metrics]]];
                
            }
            
        }
        
        if ([NSDecimalNumber notANumber] == evaluatedValue) {
            
            return evaluatedValue = [NSDecimalNumber decimalNumberWithString:@"0"];
            
        }
        
        return evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [self evaluateFormula:[NSString stringWithFormat:@"%@", [formulae lastObject]]
                                                                                                                  withDictionary:metrics]]];
        
    }
    else {
        
        NSExpression *expr = [NSExpression expressionWithFormat:formulaToEvaluate];
        evaluatedValue = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", [expr expressionValueWithObject:metrics
                                                                                                                            context:nil]]];
    }
    
    if ([NSDecimalNumber notANumber] == evaluatedValue) {
        
        evaluatedValue = [NSDecimalNumber decimalNumberWithString:@"0"];
        
    }
    
    return evaluatedValue;
    
}

-(NSString *)removeUnwantedString:(NSString *)inputStr {
    
    NSString *outputStr = [inputStr stringByReplacingOccurrencesOfString:@"("
                                                              withString:@""];
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@")"
                                                     withString:@""];
    outputStr = [outputStr stringByReplacingOccurrencesOfString:@"break"
                                                     withString:@""];
    return outputStr;
    
}

@end
