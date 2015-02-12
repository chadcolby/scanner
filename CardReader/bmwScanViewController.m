//
//  bmwScanViewController.m
//  CardReader
//
//  Created by Chad D Colby on 12/13/14.
//  Copyright (c) 2014 Byte Meets World. All rights reserved.
//

#import "bmwScanViewController.h"
#import "GSTCardReader.h"

@interface bmwScanViewController ()

@property (strong, nonatomic) GSTCardReader *cardReader;
@property (strong, nonatomic) CIDetector *cardDetector;

@end

@implementation bmwScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    self.cardReader = [[GSTCardReader alloc] initWithView:self.view andImageFilter:nil];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self prepareCardDetector];

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)prepareCardDetector {
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorTypeRectangle, CIDetectorAccuracyHigh, CIDetectorAspectRatio, 1.0, nil];
//    self.cardDetector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:options];
    
}

//func prepareRectangleDetector() -> CIDetector {
//    let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0]
//    return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
//}

@end
