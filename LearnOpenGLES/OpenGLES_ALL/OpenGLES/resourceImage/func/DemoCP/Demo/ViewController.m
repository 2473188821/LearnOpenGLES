//
//  ViewController.m
//  Demo
//
//  Created by Chenfy on 2020/5/13.
//  Copyright © 2020 Chenfy. All rights reserved.
//

#import "ViewController.h"
#import "HSWordView.h"

@interface ViewController ()<UITextViewDelegate,HSWordViewDelegate>
@property(nonatomic,strong)HSWordView *wordV;
@end

@implementation ViewController

#define Heigh 40

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    _wordV = [[HSWordView alloc]initWithFrame:CGRectMake(0, 50, 300, Heigh)];
    [_wordV addObserveWord];
    _wordV.delegate = self;
    // Do any additional setup after loading the view.
    
//    _textV.inputAccessoryView = _wordV;
    [self.view addSubview:_wordV];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.wordV.textView becomeFirstResponder];
}




- (void)HSWordViewClickedDone:(NSString *)text {

}

@end
