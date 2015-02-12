//
//  GSTCardReader.m
//  CardReader
//
//  Created by Chad D Colby on 2/12/15.
//  Copyright (c) 2015 Byte Meets World. All rights reserved.
//

#import "GSTCardReader.h"
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface GSTCardReader () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) CIImage *applyFilter;
@property (nonatomic, strong) GLKView *videoDisplayView;
@property (nonatomic) CGRect videoDisplayBounds;
@property (nonatomic, strong) CIContext *renderContext;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) CIDetector *detector;

@end

@implementation GSTCardReader

- (id)initWithView:(UIView *)view andImageFilter:(CIImage *)filterCallback {
    self = [super init];
    if (self) {
        self.applyFilter = filterCallback;
        EAGLContext *eaContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        self.videoDisplayView = [[GLKView alloc] initWithFrame:view.bounds context:eaContext];
        self.videoDisplayView.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.videoDisplayView.frame = view.bounds;
        [view addSubview:self.videoDisplayView];
        [view sendSubviewToBack:self.videoDisplayView];
        
        self.renderContext = [CIContext contextWithEAGLContext:self.videoDisplayView.context];
        self.sessionQueue = dispatch_queue_create("AVSessionQueue", DISPATCH_QUEUE_SERIAL);
        
        [self.videoDisplayView bindDrawable];
        self.videoDisplayBounds = CGRectMake(0, 0, self.videoDisplayView.drawableWidth, self.videoDisplayView.drawableHeight);
    }
    return self;
}

- (void)startFiltering {
    if (self.session == nil) {
        self.session = [self createAVSession];
    }
    
    [self.session startRunning];
}

- (void)stopFiltering {
    if (self.session) {
        [self.session stopRunning];
    }
}


- (AVCaptureSession *)createAVSession {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    AVCaptureSession *avSession = [[AVCaptureSession alloc] init];
    avSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)
                                   kCVPixelBufferPixelFormatTypeKey];
    videoOutput.videoSettings = videoSettings;
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [videoOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    
    [avSession addInput:input];
    [avSession addOutput:videoOutput];
    
    return avSession;

}

#pragma mark - AVCaptureVideoDataOutPutSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:pixelBuffer options:nil];
    
    self.applyFilter = sourceImage;
    CIImage *outputImage = sourceImage;
    if (self.applyFilter) {
        outputImage = self.applyFilter;
    }
    
    CGRect drawFrame = [outputImage extent];
    CGFloat imageAR = drawFrame.size.width / drawFrame.size.height;
    CGFloat viewAR = self.videoDisplayBounds.size.width / self.videoDisplayBounds.size.height;
    if (imageAR > viewAR) {
        drawFrame.origin.x += (drawFrame.size.width - drawFrame.size.height * viewAR) / 2.0;
        drawFrame.size.width = drawFrame.size.height / viewAR;
    } else {
        drawFrame.origin.y += (drawFrame.size.height - drawFrame.size.width * viewAR) / 2.0;
        drawFrame.size.height = drawFrame.size.width / viewAR;
    }
    
    [self.videoDisplayView bindDrawable];
    
    if (self.videoDisplayView.context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:self.videoDisplayView.context];
    }
    
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(0x00004000);
    
    glEnable(0x0BE2);
    glBlendFunc(1, 0x0303);
    
    [self.renderContext drawImage:outputImage inRect:self.videoDisplayBounds fromRect:drawFrame];
    
    [self.videoDisplayView display];
}

@end


















