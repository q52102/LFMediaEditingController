//
//  LFVideoTrimmerView.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoTrimmerView.h"
#import "LFVideoTrimmerGridView.h"
#import "UIView+LFMEFrame.h"

@interface LFVideoTrimmerView () <LFVideoTrimmerGridViewDelegate>

/** 视频图片解析器 */
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;

/** 内容容器 */
@property (nonatomic, weak) UIView *contentView;

/** 控制操作视图 */
@property (nonatomic, weak) LFVideoTrimmerGridView *gridView;

/** 进度 */
@property (nonatomic, weak) UIView *slider;

@end

@implementation LFVideoTrimmerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    _maxImageCount = 15;
    
    /** 每帧图片的容器 */
    UIView *contentView = [[UIView alloc] initWithFrame:self.bounds];
    contentView.clipsToBounds = YES;
    [self addSubview:contentView];
    _contentView = contentView;
    
    /** 时间轴 */
    LFVideoTrimmerGridView *gridView = [[LFVideoTrimmerGridView alloc] initWithFrame:self.bounds];
    gridView.delegate = self;
    [self addSubview:gridView];
    _gridView = gridView;
    
    /** 进度 */
    UIView *slider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, self.bounds.size.height)];
    slider.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
    slider.userInteractionEnabled = NO;
    [self addSubview:slider];
    _slider = slider;
}

- (void)setMaxImageCount:(NSInteger)maxImageCount
{
    if (maxImageCount > 0) {
        _maxImageCount = maxImageCount;
    }
}

- (void)setControlMinWidth:(CGFloat)controlMinWidth
{
    if (controlMinWidth > self.gridView.controlMaxWidth) {
        controlMinWidth = self.gridView.controlMaxWidth;
    }
    self.gridView.controlMinWidth = controlMinWidth;
}

- (CGFloat)controlMinWidth
{
    return self.gridView.controlMinWidth;
}

- (void)setControlMaxWidth:(CGFloat)controlMaxWidth
{
    if (controlMaxWidth < self.gridView.controlMinWidth) {
        controlMaxWidth = self.gridView.controlMinWidth;
    }
    self.gridView.controlMaxWidth = controlMaxWidth;
}

- (CGFloat)controlMaxWidth
{
    return self.gridView.controlMaxWidth;
}

- (void)setAsset:(AVAsset *)asset
{
    _asset = asset;
    [self analysisVideo];
}

- (void)setProgress:(double)progress
{
    if (isnan(progress) || progress < 0) {
        return;
    }
    _progress = progress;
    _slider.x = progress*self.width;
}

- (void)setHiddenProgress:(BOOL)hidden
{
    _slider.hidden = hidden;
}

/** 重设控制区域 */
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated
{
    [self.gridView setGridRect:gridRect animated:animated];
}

- (void)analysisVideo
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_asset];
    CGFloat minSize = MIN(self.frame.size.width, self.frame.size.height);
    _imageGenerator.maximumSize = CGSizeMake(minSize, minSize);
    
    CMTime duration = _asset.duration;
    NSInteger index = self.maxImageCount;
    CMTimeValue intervalSeconds = duration.value/self.maxImageCount;
    CMTime time = CMTimeMake(0, duration.timescale);
    NSMutableArray *times = [NSMutableArray array];
    for (NSUInteger i = 0; i < index; i++) {
        [times addObject:[NSValue valueWithCMTime:time]];
        time = CMTimeAdd(time, CMTimeMake(intervalSeconds, duration.timescale));
    }
    
    CGFloat imageWidth = self.frame.size.width / (index * 1.0f);
    __block CGFloat maxContentWidth = 0;
    
    [_imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime,
                                                                                      CGImageRef cgImage,
                                                                                      CMTime actualTime,
                                                                                      AVAssetImageGeneratorResult result,
                                                                                      NSError *error) {
        UIImage *image = nil;
        if (cgImage) {
            image = [[UIImage alloc] initWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger imageIndex = [times indexOfObject:[NSValue valueWithCMTime:requestedTime]];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.layer.borderColor = [UIColor blackColor].CGColor;
            imageView.layer.borderWidth = .5f;
            CGFloat width = MIN(imageWidth, image.size.width);
            imageView.frame = CGRectMake(imageIndex*width, 0, image.size.width, self.contentView.frame.size.height);
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.contentView addSubview:imageView];
            maxContentWidth = CGRectGetMaxX(imageView.frame);

            if (self.contentView.subviews.count == times.count) {
                CGRect frame = self.contentView.frame;
                frame.size.width = MIN(self.bounds.size.width, maxContentWidth);
                frame.origin.x = (self.bounds.size.width - frame.size.width)/2;
                self.contentView.frame = frame;
            }
        });
    }];
}

#pragma mark - LFVideoTrimmerGridViewDelegate
- (void)lf_videoTrimmerGridViewDidBeginResizing:(LFVideoTrimmerGridView *)gridView
{
    if ([self.delegate respondsToSelector:@selector(lf_videoTrimmerViewDidBeginResizing:)]) {
        [self.delegate lf_videoTrimmerViewDidBeginResizing:self];
    }
}
- (void)lf_videoTrimmerGridViewDidResizing:(LFVideoTrimmerGridView *)gridView
{
    if ([self.delegate respondsToSelector:@selector(lf_videoTrimmerViewDidResizing:gridRect:)]) {
        [self.delegate lf_videoTrimmerViewDidResizing:self gridRect:gridView.gridRect];
    }
}
- (void)lf_videoTrimmerGridViewDidEndResizing:(LFVideoTrimmerGridView *)gridView
{
    if ([self.delegate respondsToSelector:@selector(lf_videoTrimmerViewDidEndResizing:)]) {
        [self.delegate lf_videoTrimmerViewDidEndResizing:self];
    }
}

@end
