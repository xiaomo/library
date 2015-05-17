//
//  ViewController.m
//  CodecLibTest
//
//  Created by MCUer on 15/4/25.
//  Copyright (c) 2015年 MoMing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "../CodecLib/H264Encoder.h"
#import "../CodecLib/H264Decoder.h"
#import "../CodecLib/AACEncoder.h"
#import "../CodecLib/AACDecoder.h"

@interface ViewController (){
    AVCaptureSession *_session;
    AVCaptureVideoDataOutput *_dataOutputVideo;
    AVCaptureAudioDataOutput *_dataOutputAudio;
    H264Encoder *_videoEncoder;
    H264Decoder *_videoDecoder;
    AACEncoder *_audioEncoder;
    AACDecoder *_audioDecoder;
}
@property (strong, nonatomic) IBOutlet UIImageView *previewImage;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //视频采集设置
    //1
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //2
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    
    
    
    //3  output kCVPixelFormatType_32BGRA
    NSMutableDictionary *settings;
    settings = [NSMutableDictionary dictionary];
    [settings setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                 forKey:(__bridge id) kCVPixelBufferPixelFormatTypeKey];
    _dataOutputVideo = [[AVCaptureVideoDataOutput alloc] init];
    _dataOutputVideo.videoSettings = settings;
    [_dataOutputVideo setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

    
    //4
    _session = [[AVCaptureSession alloc] init];
    [_session addInput:deviceInput];
    [_session addOutput:_dataOutputVideo];
    
    // via http://news.mynavi.jp/column/iphone/041/index.html
    _session.sessionPreset =AVCaptureSessionPreset640x480;// AVCaptureSessionPresetPhoto;
    
    //音频采集设置
    //1
    AVCaptureDevice *device2 = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //2
    AVCaptureDeviceInput *deviceInput2 = [AVCaptureDeviceInput deviceInputWithDevice:device2 error:NULL];
    
    //3
    _dataOutputAudio = [[AVCaptureAudioDataOutput alloc]init];
    [_dataOutputAudio setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    //4
    [_session addInput:deviceInput2];
    [_session addOutput:_dataOutputAudio];
    
    //编解码器初始
    //视频编码
    _videoEncoder=[[H264Encoder alloc]init];
    [_videoEncoder openWithBitRate:200000 fps:25 intervalIframe:5 width:640 height:480];
    
    //视频解码
    _videoDecoder=[[H264Decoder alloc]init];
    [_videoDecoder open];
    
    //音频编码
    _audioEncoder=[[AACEncoder alloc]init];
    [_audioEncoder openWithBitRate:32000 sample_rate:16000 nb_channels:1];
    
    //音频解码
    _audioDecoder=[[AACDecoder alloc]init];
    [_audioDecoder open];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [_session startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_session stopRunning];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (captureOutput == _dataOutputAudio) {
        //处理音频
        CMItemCount numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
        CMBlockBufferRef audioBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t lengthAtOffset;
        size_t totalLength;
        char *samples;
        CMBlockBufferGetDataPointer(audioBuffer, 0, &lengthAtOffset, &totalLength, &samples);
        CMAudioFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        const AudioStreamBasicDescription *desc = CMAudioFormatDescriptionGetStreamBasicDescription(format);
        
        if([_audioEncoder getFrameSize]==lengthAtOffset){
            NSData * pcmData=[NSData dataWithBytes:samples length:[_audioEncoder getFrameSize]];
            //aac编码，每次只能[_audioEncoder getFrameSize]字节
            NSData * aacData=[_audioEncoder encode:pcmData];
            //aac解码
            pcmData=[_audioDecoder decode:aacData];
            NSLog(@"get audio,length:%d",lengthAtOffset);
        }
    }else{
        //处理视频
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
        int bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
        int bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
        uint8_t *yc = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        int total = bufferWidth * bufferHeight;
        NSData * yuvData=[NSData dataWithBytes:yc length:total*3/2];
        //h264编码
        NSData * h264Data=[_videoEncoder encode:yuvData];
        //h264解码
        NSData * yuvDecodeData=[_videoDecoder decode:h264Data];
        NSLog(@"get video size：%dx%d",bufferWidth,bufferHeight);
        CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    }
}



- (void)viewDidUnload {
    _session = nil;
    _dataOutputVideo = nil;
    //编解码器关闭
    //视频编码
    [_videoEncoder close];
    //视频解码
    [_videoDecoder close];
    
    //音频编码
    [_audioEncoder close];
    
    //音频解码
    [_audioDecoder close];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
- (IBAction)btnBack:(id)sender {
    exit(0);
}

@end
