//
//  LFVideoClippingView.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFEditingProtocol.h"

@protocol LFVideoClippingViewDelegate;

@interface LFVideoClippingView : UIView <LFEditingProtocol>

@property (nonatomic, weak) id<LFVideoClippingViewDelegate> delegate;


/** 开始播放时间 */
@property (nonatomic, assign) double startTime;
/** 结束播放时间 */
@property (nonatomic, assign) double endTime;
/** 视频总时长 */
@property (nonatomic, readonly) double totalDuration;
/** 是否正在设置进度 */
@property (nonatomic, readonly) BOOL isScrubbing;
/** 是否存在水印 */
@property (nonatomic, readonly) BOOL hasWatermark;
/** 水印层 */
@property (nonatomic, weak, readonly) UIView *overlayView;

/** 数据 */
- (void)setVideoURL:(NSURL *)url placeholderImage:(UIImage *)image;

/** 贴图是否需要移到屏幕中心 */
@property (nonatomic, copy) BOOL(^moveCenter)(CGRect rect);

/** 保存 */
- (void)save;
/** 取消 */
- (void)cancel;

/** 播放 */
- (void)playVideo;
/** 暂停 */
- (void)pauseVideo;
/** 是否播放 */
- (BOOL)isPlaying;
/** 重新播放 */
- (void)replayVideo;

/** 移动到某帧 */
- (void)beginScrubbing;
- (void)seekToTime:(CGFloat)time;
- (void)endScrubbing;

@end

@protocol LFVideoClippingViewDelegate <NSObject>

/** 视频准备完毕，可以获取相关属性与操作 */
- (void)lf_videLClippingViewReadyToPlay:(LFVideoClippingView *)clippingView;
/** 进度回调 */
- (void)lf_videoClippingView:(LFVideoClippingView *)clippingView duration:(double)duration;
/** 进度长度 */
- (CGFloat)lf_videoClippingViewProgressWidth:(LFVideoClippingView *)clippingView;

@end
