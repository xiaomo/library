//
//  VideoEncoder.m
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import "H264Encoder.h"
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/pixfmt.h>
#include <libavutil/opt.h>
#include <libavutil/imgutils.h>
#include <stdlib.h>

@interface H264Encoder()
{
    AVCodec *codec;//=NULL;
    AVCodecContext *codec_ctx;// = NULL;
    AVFrame *frame;//=NULL;
    AVPacket pkt;
}
@end

@implementation H264Encoder
- (bool) openWithBitRate: (int)bitrate fps:(int)fps intervalIframe:(int)intervalSeconds width:(int)width height:(int)height{
    avcodec_register_all();
    codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    if (!codec)
    {
        NSLog(@"video encoder not found\n");
        return FALSE;
    }
    codec_ctx = avcodec_alloc_context3(codec);
    if (!codec_ctx)
    {
        NSLog(@"Could not allocate video codec context\n");
        return FALSE;
    }
    
    /* put sample parameters */
    codec_ctx->bit_rate = bitrate; //200000;
    /* resolution must be a multiple of two */
    codec_ctx->width = width;
    codec_ctx->height = height;
    /* frames per second */
    codec_ctx->time_base = (AVRational){1,fps};
    /* emit one intra frame every ten frames
     * check frame pict_type before passing frame
     * to encoder, if frame->pict_type is AV_PICTURE_TYPE_I
     * then gop_size is ignored and the output of encoder
     * will always be I frame irrespective to gop_size
     */
    codec_ctx->gop_size = fps * intervalSeconds;
    codec_ctx->max_b_frames = 1;
    codec_ctx->pix_fmt = AV_PIX_FMT_YUV420P;
    
    //if (codec_id == AV_CODEC_ID_H264)
    //av_opt_set(codec_ctx->priv_data, "preset", "slow", 0);
    
    av_opt_set(codec_ctx->priv_data, "preset", "ultrafast", 0);
    av_opt_set(codec_ctx->priv_data, "tune", "zerolatency", 0);
    /* open it */
    if (avcodec_open2(codec_ctx, codec, NULL) < 0)
    {
        NSLog(@"Could not open codec\n");
        return FALSE;
    }
    frame = av_frame_alloc();
    if (!frame)
    {
        NSLog(@"Could not allocate video frame\n");
         return FALSE;
    }
    frame->format = codec_ctx->pix_fmt;
    frame->width = codec_ctx->width;
    frame->height = codec_ctx->height;
    
    /* the image can be allocated by any means and av_image_alloc() is
     * just the most convenient way if av_malloc() is to be used */
    int ret = av_image_alloc(frame->data, frame->linesize, codec_ctx->width, codec_ctx->height, codec_ctx->pix_fmt, 8);
    if (ret < 0)
    {
        NSLog(@"Could not allocate raw picture buffer\n");
         return FALSE;
    }
    
    av_init_packet(&pkt);
    pkt.data = NULL;
    pkt.size = 0;
    return TRUE;
}

- (NSData *) encode: (NSData *) NV12Data{
    
    int got_output = 0;
    /* Y */
    int nPicSize = frame->width * frame->height;
    
    uint8_t * yuvBytes=(uint8_t*)[NV12Data bytes];
    memcpy(frame->data[0], yuvBytes, nPicSize);
    /* U V */
    int i = 0;
    for (i = 0; i < nPicSize / 4; i++)
    {
        frame->data[1][i] = *(yuvBytes + nPicSize + i * 2 + 0);
        frame->data[2][i] = *(yuvBytes + nPicSize + i * 2 + 1);
    }
    int ret = avcodec_encode_video2(codec_ctx, &pkt, frame, &got_output);
    if (ret < 0)
    {
        NSLog(@"vencode Error encoding frame\n");
        return nil;
    }
    //int len = 0;
    if (got_output && pkt.data)
    {
        NSData * h264Data=[NSData dataWithBytes:pkt.data length:pkt.size];
        av_free_packet(&pkt);
        return h264Data;
    }
    return nil;
}

- (void) close{
    if (codec_ctx)
    {
        avcodec_close(codec_ctx);
        av_free(codec_ctx);
    }
    if (frame)
    {
        //av_freep(&frame->data[0]);
        av_frame_free(&frame);
    }
}
@end
