//
//  bmwScanManager.m
//  CardReader
//
//  Created by Chad D Colby on 12/13/14.
//  Copyright (c) 2014 Byte Meets World. All rights reserved.
//

#import "bmwScanManager.h"
#import <GLKit/GLKit.h>
#import <ImageIO/ImageIO.h>

@interface bmwScanManager () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) BOOL isReady;
@property (strong, nonatomic) AVCaptureDevice *camera;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureDeviceInput *cameraInput;
@property (strong, nonatomic) AVCaptureMetadataOutput *metaDataOutput;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, copy) NSString *recognizeTag;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,strong) EAGLContext *context;
@end


@implementation bmwScanManager {
    CIRectangleFeature *_borderDetectLastRectangleFeature;
    CGFloat _imageDedectionConfidence;
    
    CIContext *_coreImageContext;
    GLuint _renderBuffer;
    GLKView *_glkView;
}

+ (bmwScanManager *)sharedManager {
    static dispatch_once_t pred;
    static bmwScanManager *sharedManager = nil;
        
        dispatch_once(&pred, ^{
            sharedManager = [[bmwScanManager alloc] init];
        });
    return sharedManager;
}

- (void)createGLKView
{
    if (self.context) return;
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    GLKView *view = [[GLKView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.context = self.context;
    view.contentScaleFactor = 1.0f;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
//    [self insertSubview:view atIndex:0];
    [self.delegate addTheOneView:view];
    _glkView = view;
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    _coreImageContext = [CIContext contextWithEAGLContext:self.context];
    [EAGLContext setCurrentContext:self.context];
}

- (void)beginScanning {
    if (self.session) {
        [self.session startRunning];
        self.isReady = YES;
        self.recognizeTag = nil;
        _imageDedectionConfidence = 0.0f;
        return;
    }
    
    // else session not ready to run
    
    NSError *error;
    self.queue = dispatch_queue_create("com.bytemeetsworld.scanQueue", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    [self createGLKView];
    NSArray *availableDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
    self.camera = nil;
    for (AVCaptureDevice *device in availableDevices) {
        if (device.position == position) {
            self.camera = device;
            break;
        }
    }
    
    self.cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:self.camera error:&error];
    
    [self.session addInput:self.cameraInput];
    self.recognizeTag = nil;
    
    self.metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:self.metaDataOutput];
    
    [self.metaDataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    [self.metaDataOutput setMetadataObjectsDelegate:self queue:self.queue];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.session addOutput:dataOutput];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    
    [self.session commitConfiguration];
    [self.session startRunning];
    
    self.recognizeTag = nil;
    self.isReady = YES;
    
    
    [self.camera lockForConfiguration:&error];
    if (!error) {
        [self.camera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        [self.camera unlockForConfiguration];
    }
    
//    [self updateCameraOrientation];

}

//-(void)updateCameraOrientation {
//    CATransform3D t = CATransform3DMakeScale(2.0, 2.0, 1.0);
//    
//    if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) {
//        t = CATransform3DRotate(t, M_PI/2, 0, 0, 1);
//    } else {
//        t = CATransform3DRotate(t, -M_PI/2, 0, 0, 1);
//    }
//    self.previewLayer.transform = t;
//}

-(CALayer *)layerForPreview {
    return self.previewLayer;
}

-(void)restartCameraForConfigChange {
    [self stopScannerAndNotify:NO];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [NSThread sleepForTimeInterval:0.5];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self beginScanning];
        });
    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if (!self.isReady) {
        return;
    }
    
    if ([metadataObjects count] <1) {
        return;
    }
    
    AVMetadataMachineReadableCodeObject *meta = [metadataObjects objectAtIndex:0];
    
    [self notifyScannedQRTag:meta.stringValue];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    image = [self filteredImageUsingContrastFilterOnImage:image];
    
    
    _borderDetectLastRectangleFeature = [self biggestRectangleInRectangles:[[self highAccuracyRectangleDetector] featuresInImage:image]];
    _imageDedectionConfidence += .5;
    
    image = [self drawHighlightOverlayForPoints:image topLeft:_borderDetectLastRectangleFeature.topLeft topRight:_borderDetectLastRectangleFeature.topRight
                                     bottomLeft:_borderDetectLastRectangleFeature.bottomLeft bottomRight:_borderDetectLastRectangleFeature.bottomRight];
    
    if (self.context && _coreImageContext)
    {
        [_coreImageContext drawImage:image inRect:[UIScreen mainScreen].bounds fromRect:image.extent];
        [self.context presentRenderbuffer:GL_RENDERBUFFER];
        
        [_glkView setNeedsDisplay];
    }
}

- (CIImage *)drawHighlightOverlayForPoints:(CIImage *)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight
{
    CIImage *overlay = [CIImage imageWithColor:[CIColor colorWithRed:1 green:0 blue:0 alpha:0.6]];
    overlay = [overlay imageByCroppingToRect:image.extent];
    overlay = [overlay imageByApplyingFilter:@"CIPerspectiveTransformWithExtent" withInputParameters:@{@"inputExtent":[CIVector vectorWithCGRect:image.extent],@"inputTopLeft":[CIVector vectorWithCGPoint:topLeft],@"inputTopRight":[CIVector vectorWithCGPoint:topRight],@"inputBottomLeft":[CIVector vectorWithCGPoint:bottomLeft],@"inputBottomRight":[CIVector vectorWithCGPoint:bottomRight]}];
    
    return [overlay imageByCompositingOverImage:image];
}

- (CIImage *)filteredImageUsingContrastFilterOnImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorControls" withInputParameters:@{@"inputContrast":@(1.1),kCIInputImageKey:image}].outputImage;
}

-(void)stopScannerAndNotify:(BOOL)notify {
    self.isReady = NO;
    if (self.session) {
        [self.session stopRunning];
        [self.session removeInput:self.cameraInput];
        [self.session removeOutput:self.metaDataOutput];
        [self.previewLayer removeFromSuperlayer];
        self.previewLayer = nil;
        self.session = nil;
        self.session = nil;
        self.cameraInput = nil;
        self.camera = nil;
        self.queue = nil;
    }
    
}

- (CIDetector *)highAccuracyRectangleDetector
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
                  });
    return detector;
}

- (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles
{
    if (![rectangles count]) return nil;
    
    float halfPerimiterValue = 0;
    
    CIRectangleFeature *biggestRectangle = [rectangles firstObject];
    
    for (CIRectangleFeature *rect in rectangles)
    {
        CGPoint p1 = rect.topLeft;
        CGPoint p2 = rect.topRight;
        CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);
        
        CGPoint p3 = rect.topLeft;
        CGPoint p4 = rect.bottomLeft;
        CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);
        
        CGFloat currentHalfPerimiterValue = height + width;
        
        if (halfPerimiterValue < currentHalfPerimiterValue)
        {
            halfPerimiterValue = currentHalfPerimiterValue;
            biggestRectangle = rect;
        }
    }
    
    return biggestRectangle;
}

-(void)pauseScanner {
    [self.session stopRunning];
}

-(void)notifyScannedQRTag:(NSString *)tag {
    if ([self.recognizeTag isEqualToString:tag]) {
        return;
    }
    
    self.recognizeTag = tag;
    self.isReady = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self flashScreen];
//        [[NSNotificationCenter defaultCenter] postNotificationName:GRDNotificationQRTagScanned object:tag];
    });
    
}

-(void)flashScreen {
    UIView *flashView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    
    UIWindow *window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    
    [window addSubview:flashView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                     }
     ];
    
    //AudioServicesPlaySystemSound (1025);
    
}
@end
