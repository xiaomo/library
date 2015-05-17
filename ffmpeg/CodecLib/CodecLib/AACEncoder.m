//
//  AudioEncoder.m
//  CodecLib
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import "AACEncoder.h"
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

@interface AACEncoder()
{
    AVCodec *codec;//=NULL;
    AVCodecContext *codec_ctx;// = NULL;
    AVFrame *frame;//=NULL;
    AVPacket pkt;
    uint16_t *samples;
    int frame_size;
}
@end

@implementation AACEncoder

- (int) getFrameSize{
    return frame_size;
}
- (BOOL) openWithBitRate: (int)bit_rate sample_rate:(int)sample_rate nb_channels:(int)nb_channels{
    avcodec_register_all();
    codec = avcodec_find_encoder_by_name("libvo_aacenc");
    if (!codec)
    {
        NSLog(@"audio encoder aacenc not found\n");
        return FALSE;
    }
    codec_ctx = avcodec_alloc_context3(codec);
    if (!codec_ctx)
    {
        NSLog(@"Could not allocate audio codec context\n");
        return FALSE;
    }
    codec_ctx->bit_rate = bit_rate; //64000;
    codec_ctx->sample_fmt = AV_SAMPLE_FMT_S16;
    
    
    /* select other audio parameters supported by the encoder */
    codec_ctx->sample_rate = sample_rate; //22050; // select_sample_rate(codec);
    //c->channel_layout = select_channel_layout(codec);
    codec_ctx->channels = nb_channels; //2; // av_get_channel_layout_nb_channels(c->channel_layout);
    
    /* open it */
    int res = avcodec_open2(codec_ctx, codec, NULL);
    if (res < 0)
    {
        NSLog(@"audio encoder not open codec,%d", res);
        return FALSE;
    }
    
    /* frame containing input raw audio */
    frame = av_frame_alloc();
    if (!frame)
    {
        NSLog(@"audio encoder not allocate audio frame\n");
        return FALSE;
    }
    
    frame->nb_samples = codec_ctx->frame_size;
    frame->format = codec_ctx->sample_fmt;
    frame->channel_layout = codec_ctx->channel_layout;
    
    /* the codec gives us the frame size, in samples,
     * we calculate the size of the samples buffer in bytes */
    frame_size = av_samples_get_buffer_size(NULL, codec_ctx->channels, codec_ctx->frame_size, codec_ctx->sample_fmt, 0);
    if (frame_size < 0)
    {
        NSLog(@"audio encoder not get sample buffer size\n");
        return FALSE;
    }
    samples = (uint16_t *) av_malloc(frame_size);
    memset(samples, 0, frame_size);
    if (!samples)
    {
        NSLog(@"Could not allocate %d bytes for samples buffer\n", frame_size);
        return FALSE;
    }
    /* setup the data pointers in the AVFrame */
    int ret = avcodec_fill_audio_frame(frame, codec_ctx->channels, codec_ctx->sample_fmt, (const uint8_t*) samples, frame_size, 0);
    if (ret < 0)
    {
        NSLog(@"audio encoder not setup audio frame\n");
        return FALSE;
    }
    av_init_packet(&pkt);
    pkt.data = NULL; // packet data will be allocated by the encoder
    pkt.size = 0;
    return TRUE;
}


- (NSData*) encode: (NSData *) pcm16Data{
    int got_output = 0;
    memcpy((uint8_t *) samples, (uint8_t*)[pcm16Data bytes],[pcm16Data length]);
    int ret = avcodec_encode_audio2(codec_ctx, &pkt, frame, &got_output);
    if (ret < 0)
    {
        NSLog(@"encode Error encoding audio frame\n");
        return nil;
    }
    if (got_output && pkt.data)
    {
        NSData * aacData=[NSData dataWithBytes:pkt.data length:pkt.size];
        av_free_packet(&pkt);
        return aacData;
     }
    return nil;
}

- (void) close{
    if (samples)
    {
        av_freep(&samples);
        samples = NULL;
    }
    if (frame)
    {
        av_frame_free(&frame);
    }
    if (codec_ctx)
    {
        avcodec_close(codec_ctx);
        av_free(codec_ctx);
    }
}
@end
