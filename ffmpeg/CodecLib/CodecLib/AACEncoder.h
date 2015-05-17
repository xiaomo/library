//
//  AudioEncoder.h
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AACEncoder : NSObject
- (BOOL) openWithBitRate: (int)bit_rate sample_rate:(int)sample_rate nb_channels:(int)nb_channels;

- (int) getFrameSize;

- (NSData *) encode: (NSData *) pcm16Data;

- (void) close;

@end
