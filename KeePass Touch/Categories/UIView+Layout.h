#import <UIKit/UIKit.h>

#pragma mark Enumerations

typedef enum
{
    UIViewHorizontalAlignmentCenter = 0,
    UIViewHorizontalAlignmentLeft = 1,
    UIViewHorizontalAlignmentRight = 2
} UIViewHorizontalAlignment;

typedef enum
{
    UIViewVerticalAlignmentMiddle = 0,
    UIViewVerticalAlignmentTop = 1,
    UIViewVerticalAlignmentBottom = 2
} UIViewVerticalAlignment;


#pragma mark - Class Interface

@interface UIView (Layout)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_LESS_THAN_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH <= 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6PLUS_INTERN (IS_IPHONE && [[UIScreen mainScreen] nativeScale] == 3.0f)
#define IS_IPHONE_6_PLUS (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)
#define IS_RETINA ([[UIScreen mainScreen] scale] == 2.0)


#pragma mark - Properties

@property (nonatomic, assign) CGFloat xOrigin;
@property (nonatomic, assign) CGFloat yOrigin;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat xCenter;
@property (nonatomic, assign) CGFloat yCenter;

@property (nonatomic, assign) CGPoint originPoint;


#pragma mark - Instance Methods

- (void)setPixelSnappedFrame: (CGRect)frame;
- (void)setPixelSnappedCenter: (CGPoint)center;

- (void)alignHorizontally: (UIViewHorizontalAlignment)horizontalAlignment;
- (void)alignVertically: (UIViewVerticalAlignment)verticalAlignment;
- (void)alignHorizontally: (UIViewHorizontalAlignment)horizontalAlignment
               vertically: (UIViewVerticalAlignment)verticalAlignment;

- (void)removeAllSubviews;

#pragma mark - wb methods

- (void)roundCorners:(UIRectCorner)corners withRadius:(CGFloat)radius;
- (void)roundCorners:(UIRectCorner)corners withRadius:(CGFloat)radius borderColor:(CGColorRef)color borderWith:(CGFloat)width;


@end // @interface UIView (Layout)
