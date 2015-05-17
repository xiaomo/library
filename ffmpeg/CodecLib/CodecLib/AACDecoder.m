//
//  AudioDecoder.m
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import "AACDecoder.h"
#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavutil/channel_layout.h>
#include <libavutil/common.h>
#include <libavutil/imgutils.h>
#include <libavutil/mathematics.h>
#include <libavutil/samplefmt.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/pixfmt.h>
#include <libswresample/swresample.h>

#define kMaxDataSizeSamples 3840*2

@interface AACDecoder(){
    AVCodec *codec;
    AVCodecContext *codec_ctx;
    struct SwrContext *swr_ctx;
    AVPacket avpkt;
    AVFrame *decoded_frame;
    uint8_t *decode_buffer;
}
@end


@implementation AACDecoder
- (BOOL) open{
        avcodec_register_all();
    codec = avcodec_find_decoder(AV_CODEC_ID_AAC);
    
    if (!codec)
    {
        NSLog(@"audio codec not found");
        return FALSE;
    }
    codec_ctx = avcodec_alloc_context3(codec);
    if (!codec_ctx)
    {
        NSLog(@"could not allocate audio codec context");
        return FALSE;
    }
    //codec_ctx->channels=nb_channels;
    //codec_ctx->sample_rate = sample_rate;
    
    int ret=avcodec_open2(codec_ctx, codec, NULL);
    if (ret< 0)
    {
        NSLog(@"audio decoder not open codec,err:%d",ret);
        return FALSE;
    }
    av_init_packet(&avpkt);
    decoded_frame = av_frame_alloc();
    if (!decoded_frame)
    {
        NSLog(@"audio decoder not allocate audio frame");
        return FALSE;
    }
    decode_buffer = (uint8_t*) malloc(kMaxDataSizeSamples);
    return TRUE;
}

- (NSData *) decode: (NSData *) aacData{
    
    avpkt.data = (uint8_t *)[aacData bytes];
    avpkt.size = [aacData length];
    if (avpkt.size > 0)
    {
        int got_frame = 0;
        int len = avcodec_decode_audio4(codec_ctx, decoded_frame, &got_frame, &avpkt);

        if (len < 0)
        {
            NSLog(@"decode Error while decoding");
            return nil;
        }
        if (got_frame)
        {

            int data_size = av_samples_get_buffer_size(NULL, codec_ctx->channels, decoded_frame->nb_samples, codec_ctx->sample_fmt, 1);
            if (data_size < 0)
            {
                //This should not occur, checking just for paranoia
                NSLog(@"Failed to calculate data size");
                return nil;
            }
            if (!swr_ctx)
            {
                swr_ctx = swr_alloc();
                if (!swr_ctx)
                {
                    NSLog(@"Could not allocate swr context");
                    return FALSE;
                }
                // set options
                av_opt_set_int(swr_ctx, "in_channel_layout", codec_ctx->channel_layout, 0);
                av_opt_set_int(swr_ctx, "in_sample_rate", codec_ctx->sample_rate, 0);
                av_opt_set_sample_fmt(swr_ctx, "in_sample_fmt", codec_ctx->sample_fmt, 0);
                
                av_opt_set_int(swr_ctx, "out_channel_layout", codec_ctx->channel_layout, 0);
                av_opt_set_int(swr_ctx, "out_sample_rate", codec_ctx->sample_rate, 0);
                av_opt_set_sample_fmt(swr_ctx, "out_sample_fmt", AV_SAMPLE_FMT_S16, 0);
                
                if (swr_init(swr_ctx) < 0)
                {
                    NSLog(@"Failed to initialize the resampling context");
                    return FALSE;
                }
            }
            
            int ret = swr_convert(swr_ctx, &decode_buffer, decoded_frame->nb_samples, (const uint8_t **) &decoded_frame->data[0],
                                  decoded_frame->nb_samples);
            if (ret < 0)
            {
                NSLog(@"Error while converting");
                return nil;
            }
            int data_len = av_samples_get_buffer_size(NULL, codec_ctx->channels, ret, AV_SAMPLE_FMT_S16, 0);
            NSData * pcmData=[NSData dataWithBytes:decode_buffer length:data_len];
            return pcmData;
        }
    }
    return nil;
}

- (void) close{
    if (swr_ctx)
    {
        swr_free(&swr_ctx);
    }
    
    if (codec_ctx)
    {
        avcodec_close(codec_ctx);
        av_free(codec_ctx);
    }
    if (decoded_frame)
    {
        //av_freep(&decoded_frame->data[0]);
        av_frame_free(&decoded_frame);
        
    }
    free(decode_buffer);
    decode_buffer = NULL;
}
@end
