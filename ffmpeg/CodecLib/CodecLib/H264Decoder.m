//
//  VideoDecoder.m
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import "H264Decoder.h"
#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavutil/channel_layout.h>
#include <libavutil/common.h>
#include <libavutil/imgutils.h>
#include <libavutil/mathematics.h>
#include <libavutil/samplefmt.h>

#define INBUF_SIZE 4096

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}

@interface H264Decoder()
{
    AVCodec *codec;//=NULL;
    AVCodecContext *codec_ctx;// = NULL;
    AVFrame *frame;//=NULL;
    uint8_t inbuf[INBUF_SIZE + FF_INPUT_BUFFER_PADDING_SIZE];
    AVPacket avpkt;
}
@end

@implementation H264Decoder
- (BOOL) open{
    avcodec_register_all();
    codec = avcodec_find_decoder(AV_CODEC_ID_H264);
    if (!codec)
    {
        NSLog(@"video decoder not found\n");
        return FALSE;
    }
    codec_ctx = avcodec_alloc_context3(codec);
    if (!codec_ctx)
    {
        NSLog(@"Could not allocate video codec context\n");
        return FALSE;
    }
    codec_ctx->pix_fmt = PIX_FMT_YUV420P;
    if (avcodec_open2(codec_ctx, codec, NULL) < 0)
    {
        NSLog(@"Could not open codec\n");
        return FALSE;
    }
    av_init_packet(&avpkt);
    memset(inbuf + INBUF_SIZE, 0, FF_INPUT_BUFFER_PADDING_SIZE);
    
    frame = av_frame_alloc();
    if (!frame)
    {
        NSLog(@"Could not allocate video frame\n");
        return FALSE;
    }
    return  TRUE;
}

- (NSData*) decode: (NSData *) h264Data{
    avpkt.data = (uint8_t*)[h264Data bytes];
    avpkt.size = (int)[h264Data length];
    if (avpkt.size > 0)
    {
        codec_ctx->pix_fmt = PIX_FMT_YUV420P;
        
        frame->format = codec_ctx->pix_fmt;
        frame->width = codec_ctx->width;
        frame->height = codec_ctx->height;
        
        int len, got_frame;
        len = avcodec_decode_video2(codec_ctx, frame, &got_frame, &avpkt);
        if (len < 0)
        {
            NSLog(@"Error while decoding frame");
            return nil;
        }
        if (got_frame)
        {
            int picSize = codec_ctx->height * codec_ctx->width;
            int newSize = picSize * 3 / 2;
            uint8_t* data = (uint8_t*) malloc(newSize);
            
            //copy stream
            int a = 0, i;
            for (i = 0; i < codec_ctx->height; i++)
            {
                memcpy(data + a, frame->data[0] + i * frame->linesize[0], codec_ctx->width);
                a += codec_ctx->width;
            }
            
            for (i = 0; i < codec_ctx->height / 2; i++)
            {
                memcpy(data + a, frame->data[1] + i * frame->linesize[1], codec_ctx->width / 2);
                a += codec_ctx->width / 2;
            }
            
            for (i = 0; i < codec_ctx->height / 2; i++)
            {
                memcpy(data + a, frame->data[2] + i * frame->linesize[2], codec_ctx->width / 2);
                a += codec_ctx->width / 2;
            }
            
            NSData * yuvData=[NSData dataWithBytes:data length:newSize];
            free(data);
            return yuvData;
        }
    }
    return nil;
}
- (void) close{
    if (codec_ctx)
    {
        avcodec_close(codec_ctx);
        av_free(codec_ctx);
        codec = NULL;
        codec_ctx = NULL;
        
    }
    if (frame)
    {
        //av_freep(&frame->data[0]);
        av_frame_free(&frame);
        frame = NULL;
    };
}
@end
