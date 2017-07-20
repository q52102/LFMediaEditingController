//
//  LFVideoClippingView.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoClippingView.h"
#import "LFVideoPlayer.h"
#import "LFVideoPlayerLayerView.h"
#import "UIView+LFMECommon.h"

/** 编辑功能 */
#import "LFDrawView.h"
#import "LFSplashView.h"
#import "LFSplashView_new.h"
#import "LFStickerView.h"

NSString *const kLFVideoCLippingViewData = @"LFVideoCLippingViewData";

NSString *const kLFVideoCLippingViewData_startTime = @"LFVideoCLippingViewData_startTime";
NSString *const kLFVideoCLippingViewData_endTime = @"LFVideoCLippingViewData_endTime";

NSString *const kLFVideoCLippingViewData_draw = @"LFVideoCLippingViewData_draw";
NSString *const kLFVideoCLippingViewData_sticker = @"LFVideoCLippingViewData_sticker";
NSString *const kLFVideoCLippingViewData_splash = @"LFVideoCLippingViewData_splash";

@interface LFVideoClippingView () <LFVideoPlayerDelegate>

@property (nonatomic, weak) LFVideoPlayerLayerView *playerLayerView;
@property (nonatomic, strong) LFVideoPlayer *videoPlayer;

/** 原始坐标 */
@property (nonatomic, assign) CGRect originalRect;

/** 绘画 */
@property (nonatomic, weak) LFDrawView *drawView;
/** 贴图 */
@property (nonatomic, weak) LFStickerView *stickerView;
/** 模糊 */
@property (nonatomic, weak) LFSplashView_new *splashView;

/** 代理 */
@property (nonatomic ,weak) id<LFPhotoEditDelegate> editDelegate_self;

/** 记录编辑层是否可控 */
@property (nonatomic, assign) BOOL editEnable;
@property (nonatomic, assign) BOOL drawViewEnable;
@property (nonatomic, assign) BOOL stickerViewEnable;
@property (nonatomic, assign) BOOL splashViewEnable;


#pragma mark 编辑数据
/** 开始播放时间 */
@property (nonatomic, assign) double old_startTime;
/** 结束播放时间 */
@property (nonatomic, assign) double old_endTime;

@end

@implementation LFVideoClippingView

/*
 1、播放功能（无限循环）
 2、暂停／继续功能
 3、视频编辑功能
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _originalRect = frame;
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor clearColor];
    self.editEnable = YES;
    
    LFVideoPlayerLayerView *playerLayerView = [[LFVideoPlayerLayerView alloc] initWithFrame:self.bounds];
    playerLayerView.contentMode = UIViewContentModeScaleAspectFit;
    playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self addSubview:playerLayerView];
    _playerLayerView = playerLayerView;
    
    /** 涂抹 - 最底层 */
//    LFSplashView_new *splashView = [[LFSplashView_new alloc] initWithFrame:self.bounds];
//    __weak typeof(self) weakSelf = self;
//    splashView.splashColor = ^UIColor *(CGPoint point) {
//        return [weakSelf.playerLayerView LFME_colorOfPoint:point];
//    };
//    /** 默认不能涂抹 */
//    splashView.userInteractionEnabled = NO;
//    [self addSubview:splashView];
//    self.splashView = splashView;
    
    /** 绘画 */
    LFDrawView *drawView = [[LFDrawView alloc] initWithFrame:self.bounds];
    /** 默认不能触发绘画 */
    drawView.userInteractionEnabled = NO;
    [self addSubview:drawView];
    self.drawView = drawView;
    
    /** 贴图 */
    LFStickerView *stickerView = [[LFStickerView alloc] initWithFrame:self.bounds];
    /** 禁止后，贴图将不能拖到，设计上，贴图是永远可以拖动的 */
    //    stickerView.userInteractionEnabled = NO;
    [self addSubview:stickerView];
    self.stickerView = stickerView;
}

- (void)dealloc
{
    [self.videoPlayer pause];
    self.videoPlayer.delegate = nil;
    self.videoPlayer = nil;
}

- (void)setVideoURL:(NSURL *)url placeholderImage:(UIImage *)image
{
    [self.playerLayerView setImage:image];
    if (self.videoPlayer == nil) {
        self.videoPlayer = [LFVideoPlayer new];
        self.videoPlayer.delegate = self;
    }
    [self.videoPlayer setURL:url];
    
    /** 重置编辑UI位置 */
    CGRect editRect = AVMakeRectWithAspectRatioInsideRect(self.videoPlayer.size, self.frame);
    _drawView.frame = editRect;
    _splashView.frame = editRect;
    _stickerView.frame = editRect;
}

- (void)setMoveCenter:(BOOL (^)(CGRect))moveCenter
{
    _moveCenter = moveCenter;
    if (moveCenter) {
        _stickerView.moveCenter = moveCenter;
    } else {
        _stickerView.moveCenter = nil;
    }
}

/** 保存 */
- (void)save
{
    self.old_startTime = self.startTime;
    self.old_endTime = self.endTime;
}
/** 取消 */
- (void)cancel
{
    self.startTime = self.old_startTime;
    self.endTime = self.old_endTime;
}

/** 播放 */
- (void)playVideo
{
    [self.videoPlayer play];
    [self seekToTime:self.startTime];
}

/** 暂停 */
- (void)pauseVideo
{
    [self.videoPlayer pause];
}

/** 是否播放 */
- (BOOL)isPlaying
{
    return [self.videoPlayer isPlaying];
}

/** 重新播放 */
- (void)replayVideo
{
    [self.videoPlayer resetDisplay];
    if (![self.videoPlayer isPlaying]) {
        [self.videoPlayer play];
    }
    [self seekToTime:self.startTime];
}

/** 移动到某帧 */
- (void)seekToTime:(CGFloat)time
{
    [self.videoPlayer seekToTime:time];
}

- (void)beginScrubbing
{
    _isScrubbing = YES;
    [self.videoPlayer beginScrubbing];
}

- (void)endScrubbing
{
    _isScrubbing = NO;
    [self.videoPlayer endScrubbing];
}

/** 是否存在水印 */
- (BOOL)hasWatermark
{
    return self.drawView.canUndo || self.splashView.canUndo || self.stickerView.subviews.count;
}

- (UIView *)overlayView
{
    UIView *view = nil;
    if (self.hasWatermark) {
        
        NSDictionary *photoEditData = self.photoEditData;
        
        CGRect editRect = AVMakeRectWithAspectRatioInsideRect(self.videoPlayer.size, self.frame);
        view = [[UIView alloc] initWithFrame:editRect];
        
        /** 绘画 */
        LFDrawView *drawView = [[LFDrawView alloc] initWithFrame:view.bounds];
        /** 默认不能触发绘画 */
        drawView.userInteractionEnabled = NO;
        [view addSubview:drawView];
        drawView.data = photoEditData[kLFVideoCLippingViewData_draw];
        
        
        /** 贴图 */
        LFStickerView *stickerView = [[LFStickerView alloc] initWithFrame:view.bounds];
        [view addSubview:stickerView];
        stickerView.data = photoEditData[kLFVideoCLippingViewData_sticker];
    }
    return view;
}

#pragma mark - LFVideoPlayerDelegate
/** 画面回调 */
- (void)LFVideoPlayerLayerDisplay:(LFVideoPlayer *)player avplayer:(AVPlayer *)avplayer
{
    if (self.startTime > 0) {
        [player seekToTime:self.startTime];
    }
    [self.playerLayerView setPlayer:avplayer];
}
/** 可以播放 */
- (void)LFVideoPlayerReadyToPlay:(LFVideoPlayer *)player duration:(double)duration
{
    if (self.endTime == 0) {
        _endTime = duration;
    }
    _totalDuration = duration;
    [self playVideo];
    if ([self.delegate respondsToSelector:@selector(lf_videLClippingViewReadyToPlay:)]) {
        [self.delegate lf_videLClippingViewReadyToPlay:self];
    }
}

/** 播放结束 */
- (void)LFVideoPlayerPlayDidReachEnd:(LFVideoPlayer *)player
{
    [self playVideo];
}
/** 错误回调 */
- (void)LFVideoPlayerFailedToPrepare:(LFVideoPlayer *)player error:(NSError *)error
{
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"确定"
                      otherButtonTitles:nil]
     show];
}

/** 进度回调2-手动实现 */
- (void)LFVideoPlayerSyncScrub:(LFVideoPlayer *)player duration:(double)duration
{
    if (self.isScrubbing) return;
    if (duration > self.endTime) {
        [self replayVideo];
    } else {
        if ([self.delegate respondsToSelector:@selector(lf_videoClippingView:duration:)]) {
            [self.delegate lf_videoClippingView:self duration:duration];
        }
    }
}

/** 进度长度 */
- (CGFloat)LFVideoPlayerSyncScrubProgressWidth:(LFVideoPlayer *)player
{
    if ([self.delegate respondsToSelector:@selector(lf_videoClippingViewProgressWidth:)]) {
        return [self.delegate lf_videoClippingViewProgressWidth:self];
    }
    return [UIScreen mainScreen].bounds.size.width;
}


#pragma mark - LFEditingProtocol

- (void)setEditDelegate:(id<LFPhotoEditDelegate>)editDelegate
{
    _editDelegate_self = editDelegate;
    /** 设置代理回调 */
    __weak typeof(self) weakSelf = self;
    
    if (_editDelegate_self) {
        /** 绘画 */
        _drawView.drawBegan = ^{
            if ([weakSelf.editDelegate_self respondsToSelector:@selector(lf_photoEditDrawBegan)]) {
                [weakSelf.editDelegate_self lf_photoEditDrawBegan];
            }
        };
        
        _drawView.drawEnded = ^{
            if ([weakSelf.editDelegate_self respondsToSelector:@selector(lf_photoEditDrawEnded)]) {
                [weakSelf.editDelegate_self lf_photoEditDrawEnded];
            }
        };
        
        /** 贴图 */
        _stickerView.tapEnded = ^(BOOL isActive){
            if ([weakSelf.editDelegate_self respondsToSelector:@selector(lf_photoEditStickerDidSelectViewIsActive:)]) {
                [weakSelf.editDelegate_self lf_photoEditStickerDidSelectViewIsActive:isActive];
            }
        };
        
        /** 模糊 */
        _splashView.splashBegan = ^{
            if ([weakSelf.editDelegate_self respondsToSelector:@selector(lf_photoEditSplashBegan)]) {
                [weakSelf.editDelegate_self lf_photoEditSplashBegan];
            }
        };
        
        _splashView.splashEnded = ^{
            if ([weakSelf.editDelegate_self respondsToSelector:@selector(lf_photoEditSplashEnded)]) {
                [weakSelf.editDelegate_self lf_photoEditSplashEnded];
            }
        };
    } else {
        _drawView.drawBegan = nil;
        _drawView.drawEnded = nil;
        _stickerView.tapEnded = nil;
        _splashView.splashBegan = nil;
        _splashView.splashEnded = nil;
    }
    
}

- (id<LFPhotoEditDelegate>)editDelegate
{
    return _editDelegate_self;
}

/** 禁用其他功能 */
- (void)photoEditEnable:(BOOL)enable
{
    if (_editEnable != enable) {
        _editEnable = enable;
        if (enable) {
            _drawView.userInteractionEnabled = _drawViewEnable;
            _splashView.userInteractionEnabled = _splashViewEnable;
            _stickerView.userInteractionEnabled = _stickerViewEnable;
        } else {
            _drawViewEnable = _drawView.userInteractionEnabled;
            _splashViewEnable = _splashView.userInteractionEnabled;
            _stickerViewEnable = _stickerView.userInteractionEnabled;
            _drawView.userInteractionEnabled = NO;
            _splashView.userInteractionEnabled = NO;
            _stickerView.userInteractionEnabled = NO;
        }
    }
}

#pragma mark - 数据
- (NSDictionary *)photoEditData
{
    NSDictionary *drawData = _drawView.data;
    NSDictionary *stickerData = _stickerView.data;
    NSDictionary *splashData = _splashView.data;
    
    NSMutableDictionary *data = [@{} mutableCopy];
    if (drawData) [data setObject:drawData forKey:kLFVideoCLippingViewData_draw];
    if (stickerData) [data setObject:stickerData forKey:kLFVideoCLippingViewData_sticker];
    if (splashData) [data setObject:splashData forKey:kLFVideoCLippingViewData_splash];
    
    if (self.startTime > 0 || self.endTime < self.totalDuration) {
        NSDictionary *myData = @{kLFVideoCLippingViewData_startTime:@(self.startTime)
                                 , kLFVideoCLippingViewData_endTime:@(self.endTime)
                                 };
        [data setObject:myData forKey:kLFVideoCLippingViewData];
    }
    
    if (data.count) {
        return data;
    }
    return nil;
}

- (void)setPhotoEditData:(NSDictionary *)photoEditData
{
    NSDictionary *myData = photoEditData[kLFVideoCLippingViewData];
    if (myData) {
        self.startTime = self.old_startTime = [myData[kLFVideoCLippingViewData_startTime] doubleValue];
        self.endTime = self.old_endTime = [myData[kLFVideoCLippingViewData_endTime] doubleValue];
    }
    _drawView.data = photoEditData[kLFVideoCLippingViewData_draw];
    _stickerView.data = photoEditData[kLFVideoCLippingViewData_sticker];
    _splashView.data = photoEditData[kLFVideoCLippingViewData_splash];
}

#pragma mark - 绘画功能
/** 启用绘画功能 */
- (void)setDrawEnable:(BOOL)drawEnable
{
    _drawView.userInteractionEnabled = drawEnable;
}
- (BOOL)drawEnable
{
    return _drawView.userInteractionEnabled;
}

- (BOOL)drawCanUndo
{
    return _drawView.canUndo;
}
- (void)drawUndo
{
    [_drawView undo];
}
/** 设置绘画颜色 */
- (void)setDrawColor:(UIColor *)color
{
    _drawView.lineColor = color;
}

#pragma mark - 贴图功能
/** 取消激活贴图 */
- (void)stickerDeactivated
{
    [LFStickerView LFStickerViewDeactivated];
}
/** 激活选中的贴图 */
- (void)activeSelectStickerView
{
    [_stickerView activeSelectStickerView];
}
/** 删除选中贴图 */
- (void)removeSelectStickerView
{
    [_stickerView removeSelectStickerView];
}
/** 获取选中贴图的内容 */
- (LFText *)getSelectStickerText
{
    return [_stickerView getSelectStickerText];
}
/** 更改选中贴图内容 */
- (void)changeSelectStickerText:(LFText *)text
{
    [_stickerView changeSelectStickerText:text];
}

/** 创建贴图 */
- (void)createStickerImage:(UIImage *)image
{
    [_stickerView createImage:image];
}

#pragma mark - 文字功能
/** 创建文字 */
- (void)createStickerText:(LFText *)text
{
    if (text) {
        [_stickerView createText:text];
    }
}

#pragma mark - 模糊功能
/** 启用模糊功能 */
- (void)setSplashEnable:(BOOL)splashEnable
{
    _splashView.userInteractionEnabled = splashEnable;
}
- (BOOL)splashEnable
{
    return _splashView.userInteractionEnabled;
}
/** 是否可撤销 */
- (BOOL)splashCanUndo
{
    return _splashView.canUndo;
}
/** 撤销模糊 */
- (void)splashUndo
{
    [_splashView undo];
}

- (void)setSplashState:(BOOL)splashState
{
    if (splashState) {
        _splashView.state = LFSplashStateType_Paintbrush;
    } else {
        _splashView.state = LFSplashStateType_Mosaic;
    }
}

- (BOOL)splashState
{
    return _splashView.state == LFSplashStateType_Paintbrush;
}

@end
