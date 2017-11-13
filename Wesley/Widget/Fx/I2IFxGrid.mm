//
//  I2IFxGrid.m
//  c100Benchmarking
//
//  Created by Deepika Nahar on 14/03/17.
//  Modified by Pradeep Yadav on 10/04/17.
//  Copyright © 2017 i2i Logic (Australia) Pty Ltd. All rights reserved.
//

#import "I2IFxGrid.h"
#import <QuartzCore/QuartzCore.h>

@implementation I2IFxGrid

@synthesize dataModel;

//  This is the initialization method of the widget. It is called only once, when MicroStrategy Mobile creates the widget the first time a document is rendered (i.e., it is not called when a user changes a selector in the document). This method should include the code to perform any initialization tasks that need to be done only once, such as initializing variables and preparing external data.
-(id)initViewer:(ViewerDataModel*)_viewerDataModel withCommanderDelegate:(id<MSICommanderDelegate>)_commander
      withProps:(NSString*)_props {
    
    self = [super initViewer:_viewerDataModel
       withCommanderDelegate:_commander
                   withProps:_props];
    if (self) {
        
        //Initialize all widget's subviews as well as any instance variable
        
    }
    return self;
    
}

//  This method is used to clear all the widget’s views in order to save memory. It is called the first time the widget is loaded, and later if the widget needs to be recreated or deleted.
-(void)cleanViews {
    
    for (UIView *view in self.subviews) {
        
        if ([view isKindOfClass:[UIView class]]) {
            
            UIView *v = (UIView *)view;
            [v removeFromSuperview];
            
        }
        
    }
    
}

//  This method is called every time the widget is recreated, which could be during initialization, when a layout or panel changes, or when the widget’s source selector is changed.
-(void)recreateWidget {
    
    [self reInitDataModels];
    [self addSubview:i2iGridView];
    
}

//Method that refreshes the data from the widget from MicroStrategy and that builds the widget's internal data models.
-(void)reInitDataModels {
    
    //  Update the widget's data
    [self.widgetHelper reInitDataModels];
    dataModel = (MSIModelData *)[widgetHelper dataProvider];
    if (dataModel.rowCount > 0) [self readData];
    
}

#pragma mark Data Retrieval Methods
-(void)readData {
    
    MSIAttributeHeader *attributeHeader = (MSIAttributeHeader *)[dataModel headerObjectByAxisType:ROW_AXIS
                                                                                   andColumnIndex:0];
    keySuffix = attributeHeader.attribute.name;
    
    MSIPropertyGroup *propertyGroup = attributeHeader.format;
    fontFace = [propertyGroup propertyByPropertySetID:FormattingFont
                                           propertyID:FontFormattingName];
    fontSize = [[propertyGroup propertyByPropertySetID:FormattingFont
                                            propertyID:FontFormattingSize] intValue];
    // Primary Color for axis and data labels
    gridColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                 propertyID:FontFormattingColor]];
    
    MSIMetricHeader *metricHeader = [dataModel.metricHeaderArray objectAtIndex:0];
    MSIMetricValue *metricValue = [metricHeader.elements objectAtIndex:0];
    rowPrefix = [metricValue rawValue];
    
    propertyGroup = metricValue.format;
    textColor = [self colorConvertor:[propertyGroup propertyByPropertySetID:FormattingFont
                                                                 propertyID:FontFormattingColor]];
    
    metricHeader = [dataModel.metricHeaderArray objectAtIndex:1];
    metricValue = [metricHeader.elements objectAtIndex:0];
    noOfRows = [[[PlistData getValue] objectForKey:[metricValue rawValue]] intValue];
    
    // Reference to selection variables
    noOfColumns = (int)dataModel.columnCount - 2;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0.0f;
    layout.minimumLineSpacing = 0.0f;
    layout.sectionInset = UIEdgeInsetsMake(0, 0, 1, 0);
    layout.itemSize = CGSizeMake(100.0f, 40.0f);
    i2iGridView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
                                     collectionViewLayout:layout];
    [i2iGridView registerClass:[UICollectionViewCell class]
    forCellWithReuseIdentifier:@"Tuple"];
    i2iGridView.delegate = self;
    i2iGridView.dataSource = self;
    i2iGridView.backgroundColor = [UIColor clearColor];
    
}

#pragma mark handleEvent Methods
//When a selector changes its selection, this widget will reload its data and update its views.
-(void)handleEvent:(NSString*)ipEventName {
    
    [self cleanViews];
    [self recreateWidget];
    
}

#pragma mark Converts BGR value to UIColor object
-(UIColor *)colorConvertor:(NSString *)strColor {
    
    int bgrValue = [strColor intValue];
    return [UIColor colorWithRed:(bgrValue & 0xFF) / 255.0f
                           green:((bgrValue & 0xFF00) >> 8) / 255.0f
                            blue:((bgrValue & 0xFF0000) >> 16) / 255.0f
                           alpha:1.0f];
    
}

#pragma mark UICollectionView DataSource Methods
-(NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section {
    
    return noOfColumns;
    
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Tuple"
                                                                           forIndexPath:indexPath];
    
    cell.layer.borderWidth = 1.0f;
    cell.layer.borderColor = gridColor.CGColor;
    
    NSString *cellText = [[NSString alloc] init];
    NSString *cellInverseText = [[NSString alloc] init];
    int rowOffset = 2;
    int contentAlignment = 3;
    int selectionRowIndex = 0;
    int otherCurrency = 0;
    CGRect cellContentFrame = CGRectMake(0, 0, 90.0f, 20.0f);
    
    if (cell != nil) for (UIView *subview in [cell.contentView subviews]) [subview removeFromSuperview];
    
    NSString *selectedCurrency = [NSString stringWithFormat:@"%@%d", keySuffix, (int)indexPath.section];
    selectedCurrency = [[PlistData getValue] objectForKey:selectedCurrency];
    
    if ([selectedCurrency isEqualToString:@"PFX"]
        || [selectedCurrency isEqualToString:@"OC1"]
        || [selectedCurrency isEqualToString:@"OC2"]) otherCurrency = 1;
    else otherCurrency = 0;
    
    for (int x = 0; x < dataModel.rowCount; x++) {
        
        NSString *rowCurrency = [[[dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                          andRowIndex:x] objectAtIndex:0] rawValue];
        if ([rowPrefix isEqualToString:rowCurrency ] && otherCurrency == 1) {
            
            selectionRowIndex = x;
            break;
            
        }
        else if (selectedCurrency == rowCurrency) {
            
            selectionRowIndex = x;
            break;
            
        }
        
    }

    if (indexPath.row == 0) {
        
        cellText = [rowPrefix stringByAppendingString:@":"];
        cellText = [cellText stringByAppendingString:[[[dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                                               andRowIndex:selectionRowIndex] objectAtIndex:0] headerValue]];
        contentAlignment = 0;
        
        cellInverseText = [[[dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                    andRowIndex:selectionRowIndex] objectAtIndex:0] headerValue];
        cellInverseText = [[cellInverseText stringByAppendingString:@":"] stringByAppendingString:rowPrefix];
        
        if (otherCurrency == 1) {
            
            cellText = [[rowPrefix stringByAppendingString:@":"] stringByAppendingString:selectedCurrency];
            cellInverseText = [[selectedCurrency stringByAppendingString:@":"] stringByAppendingString:rowPrefix];
            
        }
        
    }
    else {
        
        NSMutableArray *row = [dataModel arrayWithHeaderValueOfWholeRowByAxisType:ROW_AXIS
                                                                      andRowIndex:selectionRowIndex];
        MSIMetricValue *metricValue = [row objectAtIndex:indexPath.row + rowOffset];
        MSIPropertyGroup *propertyGroup = metricValue.format;
        int category = [[propertyGroup propertyByPropertySetID:FormattingNumber
                                                    propertyID:NumberFormattingCategory] intValue];
        NSString *format = [propertyGroup propertyByPropertySetID:FormattingNumber
                                                       propertyID:NumberFormattingFormat];
        
        cellText = [self setNumberFormat:metricValue.rawValue
                      withFormatCategory:category
                              withFormat:format];
        
        cellInverseText = [self setNumberFormat:[NSString stringWithFormat:@"%f", 1.000000f / [metricValue.rawValue doubleValue]]
                             withFormatCategory:category
                                     withFormat:format];
        
    }
    
    [cell.contentView addSubview:[self createLabel:cellContentFrame
                                          withText:cellText
                                         alignment:contentAlignment]];
    
    if (indexPath.row != 3 && indexPath.row != 5) {
        
        cellContentFrame = CGRectMake(0, 20.0f, 90.0f, 20.0f);
        [cell.contentView addSubview:[self createInverseLabel:cellContentFrame
                                                     withText:cellInverseText
                                                    alignment:contentAlignment]];
        
    }
    return cell;
    
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return noOfRows;
    
}

#pragma mark Cell Contents
-(UILabel*)createLabel:(CGRect)frame
              withText:(NSString*)text
             alignment:(int)align {
    
    UILabel *lblValue = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 5, frame.origin.y, frame.size.width - 5, frame.size.height)];
    lblValue.font = [UIFont fontWithName:fontFace
                                    size:fontSize + 1];
    
    lblValue.textColor = textColor;
    lblValue.text = text;
    
    switch (align) {
            
        case 4: lblValue.textAlignment = NSTextAlignmentRight;
            break;
            
        case 3: lblValue.textAlignment = NSTextAlignmentCenter;
            break;
            
        default: lblValue.textAlignment = NSTextAlignmentLeft;
            break;
            
    }
    return lblValue;
    
}
-(UILabel*)createInverseLabel:(CGRect)frame
                     withText:(NSString*)text
                    alignment:(int)align {
    
    UILabel *lblValue = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 5, frame.origin.y, frame.size.width - 5, frame.size.height)];
    lblValue.font = [UIFont fontWithName:[NSString stringWithFormat:@"%@%@", fontFace, @"-Italic"]
                                    size:fontSize];
    
    lblValue.textColor = gridColor;
    lblValue.text = text;
    
    switch (align) {
            
        case 4: lblValue.textAlignment = NSTextAlignmentRight;
            break;
            
        case 3: lblValue.textAlignment = NSTextAlignmentCenter;
            break;
            
        default: lblValue.textAlignment = NSTextAlignmentLeft;
            break;
            
    }
    return lblValue;
    
}

#pragma mark Sets Number Formatting
-(NSString*)setNumberFormat:(NSString*)text
         withFormatCategory:(int)category
                 withFormat:(NSString*)format {
    
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    switch (category) {
        case 0: numFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            break;
            
        case 1: numFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
            break;
            
        case 4: numFormatter.numberStyle = NSNumberFormatterPercentStyle;
            break;
            
        default:
            break;
    }
    numFormatter.positiveFormat = format;
    return [numFormatter stringFromNumber:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%@", text]]];
    
}

@end
