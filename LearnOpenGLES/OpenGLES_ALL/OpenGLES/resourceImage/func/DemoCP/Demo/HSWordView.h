//
//  HSWordView.h
//  SaasAppIOS
//
//  Created by Chenfy on 2020/5/22.
//  Copyright © 2020 刘强强. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HSWordViewDelegate <NSObject>

- (void)HSWordViewClickedDone:(NSString *)text;

@end

@interface HSWordView : UIView
@property(nonatomic,weak)id <HSWordViewDelegate>delegate;

@property(nonatomic,strong)UITextView *textView;

+ (HSWordView *)createWordTextViewDefault;

- (void)addObserveWord;
- (void)removeObserveWord;

@end

NS_ASSUME_NONNULL_END
