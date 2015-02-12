//
//  GSTCardReader.h
//  CardReader
//
//  Created by Chad D Colby on 2/12/15.
//  Copyright (c) 2015 Byte Meets World. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GSTCardReader : NSObject

- (id)initWithView:(UIView *)view andImageFilter:(CIImage *)filterCallback;

- (void)startFiltering;
- (void)stopFiltering;

@end
