//
//  VideoEncoder.h
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface H264Encoder : NSObject
- (bool) openWithBitRate: (int)bitrate fps:(int)fps intervalIframe:(int)intervalSeconds width:(int)width height:(int)height;

- (NSData*) encode: (NSData *) NV12Data;

- (void) close;
@end

