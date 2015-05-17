//
//  VideoDecoder.h
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface H264Decoder : NSObject
- (BOOL) open;

- (NSData*) decode: (NSData *) h264Data;

- (void) close;
@end
