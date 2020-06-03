//
//  ViewController.m
//  Demo
//
//  Created by Chenfy on 2020/5/13.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "ViewController.h"
#import "HSLiveSession.h"

@interface ViewController ()<HSLiveSessionDelegate>
@property(nonatomic,strong)HSLiveSession *session;

@property(nonatomic,strong)UIImageView *imageV;

@end

@implementation ViewController
- (UIImageView *)imageV {
    if (!_imageV) {
        _imageV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
        _imageV.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageV;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self testHSLiveSession];

    // Do any additional setup after loading the view.
}

- (void)testHSLiveSession {
    [self.session setupAVCapture];
    [self.session setVideoPreview:self.view];
    [self.session startSession];
        
    [self.view addSubview:self.imageV];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if ([output isKindOfClass:[AVCaptureVideoDataOutput class]]) {
        NSLog(@"OutPut  Video ++++++++++++++++++++++++");
        UIImage *img = [self.session readSampleBufferVideoToImage:sampleBuffer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageV.image = img;
        });
    }
    if ([output isKindOfClass:[AVCaptureAudioDataOutput class]]) {
        NSLog(@"OutPut   Audio ----------------------");
    }
}

#pragma mark -- session
- (HSLiveSession *)session {
    if (!_session) {
        _session = [[HSLiveSession alloc]init];
        _session.delegate = self;
    }
    return _session;
}


@end
