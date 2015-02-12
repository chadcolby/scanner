//
//  GSTCardOutline.m
//  CardReader
//
//  Created by Chad D Colby on 2/12/15.
//  Copyright (c) 2015 Byte Meets World. All rights reserved.
//

#import "GSTCardOutline.h"

@implementation GSTCardOutline

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 4.0);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {0.5, 0.5, 0.5, 1.0};
    CGColorRef color = CGColorCreate(colorspace, components);
    CGContextSetStrokeColorWithColor(context, color);
    
    CGFloat aspRatio = 1.7f;
    CGFloat cardWidth = self.frame.size.width - 20;
    CGFloat cardHeight = cardWidth / aspRatio;
    
    CGFloat segW = 30;
    CGFloat segH = 30;
    
    CGFloat heightOffset = 70.f; //change this value to move card up or down (in portrait mode)
    
    //TL
    CGContextMoveToPoint(context, 20 + segW, heightOffset);
    CGContextAddLineToPoint(context, 20, heightOffset);
    CGContextAddLineToPoint(context, 20, heightOffset + segH);
    
    //TR
    CGContextMoveToPoint(context, cardWidth - segW, heightOffset);
    CGContextAddLineToPoint(context, cardWidth, heightOffset);
    CGContextAddLineToPoint(context, cardWidth, heightOffset + segW);
    
    //BL
    CGContextMoveToPoint(context, 20 + segW, cardHeight + heightOffset);
    CGContextAddLineToPoint(context, 20, cardHeight + heightOffset);
    CGContextAddLineToPoint(context, 20, cardHeight - segH + heightOffset);
    
    //BR
    CGContextMoveToPoint(context, cardWidth - segW, cardHeight + heightOffset);
    CGContextAddLineToPoint(context, cardWidth, cardHeight + heightOffset);
    CGContextAddLineToPoint(context, cardWidth, cardHeight - segH + heightOffset);
    
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
    
    
}

@end
