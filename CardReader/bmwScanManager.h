//
//  bmwScanManager.h
//  CardReader
//
//  Created by Chad D Colby on 12/13/14.
//  Copyright (c) 2014 Byte Meets World. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@protocol ScanManagerDelegate <NSObject>

//- (void)scanManagerDidFinish;
- (void)addTheOneView:(UIView *)viewToDraw;

@end

@interface bmwScanManager : NSObject <AVCaptureMetadataOutputObjectsDelegate>

@property (unsafe_unretained) id <ScanManagerDelegate> delegate;

+ (bmwScanManager *)sharedManager;

-(void)beginScanning;
-(void)pauseScanner;

-(void)restartCameraForConfigChange;

-(CALayer *)layerForPreview;


@end
