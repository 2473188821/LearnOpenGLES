//
//  HSWordView.m
//  SaasAppIOS
//
//  Created by Chenfy on 2020/5/22.
//  Copyright © 2020 刘强强. All rights reserved.
//

#import "HSWordView.h"

//键盘高度
#define KHS_BOARD_HEIGHT 45

@interface HSWordView () <UITextViewDelegate>
@property(nonatomic,assign)CGFloat heightBorard;
@property(nonatomic,assign)CGRect frame_local;

@property(nonatomic,strong)UIButton *btnSend;

@end

@implementation HSWordView
//默认alpha值为1
- (UIColor *)colorWithHexString:(NSString *)color
{
    return [self colorWithHexString:color alpha:1.0f];
}

- (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha
{
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6)
    {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"])
    {
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"])
    {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6)
    {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _heightBorard = frame.size.height;
        _frame_local = frame;
        self.backgroundColor = [self colorWithHexString:@"#27282A"];
        self.userInteractionEnabled = YES;
        [self configView:frame];
    }
    return self;
}

+ (HSWordView *)createWordTextViewDefault {
    CGRect frm = [[UIScreen mainScreen]bounds];
    HSWordView *wordV = [[HSWordView alloc]initWithFrame:CGRectMake(0, 0, frm.size.width, KHS_BOARD_HEIGHT)];
    return wordV;
}

- (void)configView:(CGRect)frm {
    [self addSubview:self.textView];
    [self addSubview:self.btnSend];
    
    int offset = 5;

    CGFloat x = offset;
    CGFloat y = offset;
    CGFloat w = frm.size.width - 120;
    CGFloat h = frm.size.height - offset * 2;
    
    CGRect new_frm = CGRectMake(x, y, w, h);
    
    self.textView.frame = new_frm;
    
    int top_offset = 3;
    
    x = w + 20;
    y = y + top_offset;
    w = 80;
    h = h  - top_offset * 2;
    
    CGRect btn_frm = CGRectMake(x, y, w, h);
    self.btnSend.frame = btn_frm;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc]init];
        _textView.delegate = self;
        _textView.backgroundColor = [self colorWithHexString:@"#FFFFFF" alpha:0.1f];
        _textView.font = [UIFont systemFontOfSize:12.0];
        _textView.textColor = [self colorWithHexString:@"#FFFFFF" alpha:1.f];
        _textView.scrollsToTop = NO;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.textContainerInset = UIEdgeInsetsMake(7.f, 10.f, 0.f, 0.f);
        _textView.layer.cornerRadius = 2.f;
        _textView.layer.masksToBounds = YES;
        if (@available(iOS 11.0, *)) {
            _textView.textDragInteraction.enabled = NO;
        }
//        _textView.backgroundColor = UIColor.cyanColor;
    }
    return _textView;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {

}

- (void)textViewDidEndEditing:(UITextView *)textView {

}

- (UIButton *)btnSend {
    if (!_btnSend) {
        _btnSend = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnSend setTitle:@"wancheng" forState:UIControlStateNormal];
        [_btnSend addTarget:self action:@selector(sendbuttonClicked) forControlEvents:UIControlEventTouchUpInside];
        _btnSend.backgroundColor = UIColor.purpleColor;
    }
    return _btnSend;
}

- (void)sendbuttonClicked {
    NSString *text = self.textView.text;
    [self.delegate HSWordViewClickedDone:text];
    self.textView.text = @"";
    [self.textView resignFirstResponder];
}


- (void)addObserveWord {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeObserveWord {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark --键盘弹出
//键盘将要出现
- (void)keyboardWillShow:(NSNotification *)noti {
    NSDictionary *userInfo = [noti userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect frm_keyboard = [aValue CGRectValue];
    CGFloat y = frm_keyboard.size.height;
    
    CGFloat duration = [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];

    CGRect frm = [[UIScreen mainScreen]bounds];
    //计算控制器的view需要平移的距离
    CGFloat transformY = y - frm.size.height;
    transformY = fabs(transformY);
    
    CGRect Nfrm = CGRectMake(0, transformY - _heightBorard, _frame_local.size.width, _frame_local.size.height);
    //执行动画
    [UIView animateWithDuration:duration animations:^{
        self.frame = Nfrm;
    }];
}

#pragma mark --键盘收回
- (void)keyboardDidHide:(NSNotification *)notification{
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    CGRect frm = [[UIScreen mainScreen]bounds];

    CGRect Nfrm = CGRectMake(0, frm.size.height + 5, _frame_local.size.width, _frame_local.size.height);

    [UIView animateWithDuration:duration animations:^{
        self.frame = Nfrm;
    }];
}
@end
