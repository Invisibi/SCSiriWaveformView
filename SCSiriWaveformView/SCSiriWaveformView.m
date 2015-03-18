//
//  SCSiriWaveformView.m
//  SCSiriWaveformView
//
//  Created by Stefan Ceriu on 12/04/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCSiriWaveformView.h"

static const CGFloat kDefaultFrequency          = 1.5f;
static const CGFloat kDefaultAplitude           = 1.0f;
static const CGFloat kDefaultIdleAmplitude      = 0.01f;
static const CGFloat kDefaultNumberOfWaves      = 5.0f;
static const CGFloat kDefaultPhaseShift         = -0.15f;
static const CGFloat kDefaultDensity            = 5.0f;
static const CGFloat kDefaultPrimaryLineWidth   = 3.0f;
static const CGFloat kDefaultSecondaryLineWidth = 1.0f;

@interface SCSiriWaveformView ()

@property (nonatomic, assign) CGFloat phase;
@property (nonatomic, assign) CGFloat amplitude;

@property (nonatomic, strong) NSArray *blendedColorCache;
@property (nonatomic, assign) CGFloat cacheValidForWidth;

@end

@implementation SCSiriWaveformView

- (instancetype)init
{
	if(self = [super init]) {
		[self setup];
	}
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setup];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self setup];
}

- (void)setup
{
    self.blendedColorCache = [[NSArray alloc] init];
    self.cacheValidForWidth = 0.0f;

    self.waveColor = [UIColor whiteColor];
    self.waveColors = @[];
	
	self.frequency = kDefaultFrequency;
	
	self.amplitude = kDefaultAplitude;
	self.idleAmplitude = kDefaultIdleAmplitude;
	
	self.numberOfWaves = kDefaultNumberOfWaves;
	self.phaseShift = kDefaultPhaseShift;
	self.density = kDefaultDensity;
	
	self.primaryWaveLineWidth = kDefaultPrimaryLineWidth;
	self.secondaryWaveLineWidth = kDefaultSecondaryLineWidth;
}

- (NSArray *)waveColors
{
    if (!_waveColors || _waveColors.count <= 0) {
        return @[self.waveColor];
    } else {
        return _waveColors;
    }
}

- (void)updateWithLevel:(CGFloat)level
{
	self.phase += self.phaseShift;
	self.amplitude = fmax(level, self.idleAmplitude);
	
	[self setNeedsDisplay];
}

// Thanks to Raffael Hannemann https://github.com/raffael/SISinusWaveView
- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, self.bounds);
	
	[self.backgroundColor set];
	CGContextFillRect(context, rect);

    CGFloat halfHeight = CGRectGetHeight(self.bounds) / 2.0f;
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat mid = width / 2.0f;

    const CGFloat maxAmplitude = halfHeight - 4.0f; // 4 corresponds to twice the stroke width
	
	// We draw multiple sinus waves, with equal phases but altered amplitudes, multiplied by a parable function.
	for (int i = 0; i < self.numberOfWaves; i++) {
		CGContextSetLineWidth(context, (i == 0 ? self.primaryWaveLineWidth : self.secondaryWaveLineWidth));
		
		// Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
		CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
		CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
		
		CGFloat multiplier = MIN(1.0, (progress / 3.0f * 2.0f) + (1.0f / 3.0f));

        CGFloat lastX = 0;
        CGFloat lastY = halfHeight;
        for (CGFloat x = 0; x < width + self.density; x += self.density) {
            CGContextMoveToPoint(context, lastX, lastY);

			// We use a parable to scale the sinus wave, that has its peak in the middle of the view.
			CGFloat scaling = -pow(1 / mid * (x - mid), 2) + 1;

			CGFloat y = scaling * maxAmplitude * normedAmplitude * sinf(2 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;

            UIColor *const waveColor = [self colorForPositionX:x width:width];
            [[waveColor colorWithAlphaComponent:multiplier * CGColorGetAlpha(waveColor.CGColor)] set];
            CGContextAddLineToPoint(context, x, y);
            CGContextStrokePath(context);
            lastX = x;
            lastY = y;
        }
    }
}

- (UIColor *)colorForPositionX:(CGFloat)x width:(CGFloat)width
{
    if (self.cacheValidForWidth == width && x < self.blendedColorCache.count) {
        return self.blendedColorCache[(NSUInteger)x];
    }

    NSMutableArray *const colorCache = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)width];
    CGFloat const distancePerColor = width / self.waveColors.count;
    for (NSUInteger i = 0; i < width * 1.1; i++) {

        NSUInteger indexActiveColor = MIN((self.waveColors.count - 1), (NSUInteger)floor(i / distancePerColor));
        UIColor *const activeColor = self.waveColors[indexActiveColor];
        UIColor *const nextColor = self.waveColors[MIN(self.waveColors.count - 1,indexActiveColor + 1)];
        UIColor *const blendedColor = [self blendIntoColor:activeColor fraction:(fmodf(i, distancePerColor) / distancePerColor)
                ofColor:nextColor];
        colorCache[i] = blendedColor;
    }
    self.blendedColorCache = colorCache;
    self.cacheValidForWidth = width;

    return self.blendedColorCache[(NSUInteger)x];

}

- (UIColor *)blendIntoColor:(UIColor *)originColor fraction:(CGFloat)fraction ofColor:(UIColor *)newColor
{
    fraction = MIN(1.f, MAX(0.f, fraction));
    CGFloat beta = 1.f - fraction;
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [originColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [newColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    CGFloat r = r1 * beta + r2 * fraction;
    CGFloat g = g1 * beta + g2 * fraction;
    CGFloat b = b1 * beta + b2 * fraction;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.f];
}

@end
