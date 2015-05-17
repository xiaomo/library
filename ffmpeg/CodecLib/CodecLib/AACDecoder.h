//
//  AudioDecoder.h
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AACDecoder : NSObject
- (BOOL) open;
- (NSData *) decode: (NSData *) aacData;
- (void) close;
@end
