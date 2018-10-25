/*
 * Copyright 2011-2013 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ImageSelectionView.h"
#import "ImageFactory.h"

#define IMAGE_SIZE  24.0f
#define MIN_SPACING 10.5f

@interface ImageSelectionView () {
    NSUInteger numImages;
    NSUInteger numCustomImages;
    NSMutableArray *imageViews;
    UIImageView *selectedImageView;
    UIImageView *borderView;
    CGFloat spacing;
    NSInteger imagesPerRow;
}
@end

@implementation ImageSelectionView

- (id)init {
    self = [super init];

    if (self) {
        // Get the application delegate
        ImageFactory *imageFactory = [ImageFactory sharedInstance];
        numImages = [imageFactory.images count];

        // Create an image view for each image
        imageViews = [[NSMutableArray alloc] initWithCapacity:numImages];
        for (UIImage *image in imageFactory.images) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [self addSubview:imageView];
            [imageViews addObject:imageView];
        }
        
        // Create an imageview for each custom image
        NSArray *customImages = imageFactory.customs;
        for (UIImage *image in customImages)
        {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [self addSubview:imageView];
            [imageViews addObject:imageView];
        }
        
        
        
        numCustomImages = customImages.count;
        UIImage *selectedImage = [UIImage imageNamed:@"checkmark"];
        selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        [self addSubview:selectedImageView];
        UITapGestureRecognizer *tapGestureRecgonizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:tapGestureRecgonizer];
    }
    return self;
}

- (void)layoutSubviews {
    UIScrollView *scrollView = (UIScrollView *)self.superview;

    // Compute the number of images per row as well as the spacing
    imagesPerRow = self.bounds.size.width / (IMAGE_SIZE + 2 * MIN_SPACING);
    spacing = ((self.bounds.size.width / imagesPerRow) - IMAGE_SIZE) / 2.0f;
    

    // Layout the images
    int numberOfRows = 0;
    CGRect imageFrame = CGRectMake(spacing, spacing, IMAGE_SIZE, IMAGE_SIZE);
    for (int i = 0; i < numImages; i += imagesPerRow) {
        numberOfRows++;
        for (int j = 0; j < imagesPerRow; j++) {
            if (i + j >= numImages) {
                break;
            }
            
            UIImageView *imageView = (UIImageView *)[imageViews objectAtIndex:i + j];
            imageView.frame = imageFrame;
            
            imageFrame.origin.x += IMAGE_SIZE + 2 * spacing;
        }
        
        imageFrame.origin.x = spacing;
        imageFrame.origin.y += IMAGE_SIZE + 2 * spacing;
    }
    
    // Layout the customImages
    int borderHeight = 0;
    int numberOfCustomRows = 0;
    if(numCustomImages > 0)
    {
        borderHeight = IMAGE_SIZE;
        
        
        
        
        if(!borderView)
        {
            // Draw Border
            UIGraphicsBeginImageContext(CGSizeMake(self.bounds.size.width, 24.0f));
            
            // get the context for CoreGraphics
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            
            // set fill color and stroke color
            [[UIColor whiteColor] setStroke];
            [[UIColor grayColor] setFill];
            
            // make Rect
            CGRect greyBorder = CGRectMake(0, 0, self.bounds.size.width, borderHeight);
            
            // draw rect
            CGContextFillRect(ctx, greyBorder);
            
            // Draw the Text
            NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
            textStyle.alignment = NSTextAlignmentLeft;
            NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize: 14], NSForegroundColorAttributeName: UIColor.whiteColor, NSParagraphStyleAttributeName: textStyle};
            
            [@"Custom Icons" drawInRect:CGRectMake(spacing, 2, greyBorder.size.width, borderHeight) withAttributes:textFontAttributes];
            
            // make image out of bitmap context
            UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();
            
            // free the context
            UIGraphicsEndImageContext();
            
            borderView = [[UIImageView alloc] initWithImage:retImage];
            borderView.frame = CGRectMake(0, imageFrame.origin.y, self.bounds.size.width, borderHeight);
            [self addSubview:borderView];
        }
        
        
        
        
        // add borderheight to origin y
        imageFrame.origin.y += borderHeight + 2 * spacing;
        
        
        for (int i = 0; i < numCustomImages; i += imagesPerRow) {
            numberOfRows++;
            for (int j = 0; j < imagesPerRow; j++) {
                if (i + j >= numCustomImages) {
                    break;
                }
                
                UIImageView *imageView = (UIImageView *)[imageViews objectAtIndex:NUM_IMAGES + i + j];
                imageView.frame = imageFrame;
                
                imageFrame.origin.x += IMAGE_SIZE + 2 * spacing;
            }
            
            imageFrame.origin.x = spacing;
            imageFrame.origin.y += IMAGE_SIZE + 2 * spacing;
        }
    }
    

    // Re-select the image after layout
    self.selectedImageIndex = _selectedImageIndex;

    // Update the height of the frame based on the new layout
    CGRect newFrame = self.frame;
    newFrame.size.height = borderHeight + 2 * spacing + (numberOfRows + numberOfCustomRows) * (IMAGE_SIZE + 2 * spacing);
    self.frame = newFrame;
    
    scrollView.contentSize = newFrame.size;
    
    if([_layoutDelegate respondsToSelector:@selector(didFinishLayout)])
    {
        [_layoutDelegate didFinishLayout];
    }
}

- (void)setSelectedImageIndex:(NSUInteger)selectedImageIndex {
    _selectedImageIndex = selectedImageIndex;
    // Update the selected image view frame if we know how many images there are per row
    [self drawSelectedImageViewWithIndex];
}

- (void)drawSelectedImageViewWithIndex
{
    if (imagesPerRow > 0) {
        NSUInteger row = _selectedImageIndex / imagesPerRow;
        NSUInteger col = _selectedImageIndex - (row * imagesPerRow);
        
        CGSize size = selectedImageView.image.size;
        CGRect frame = CGRectMake((col + 1) * (IMAGE_SIZE + 2 * spacing) - size.width,
                                  (row + 1) * (IMAGE_SIZE + 2 * spacing) - size.height,
                                  size.width, size.height);
        selectedImageView.frame = frame;
    }
}

- (void)selectedCustomIndex:(NSUInteger)customIndex
{
    NSUInteger selectedIndex = 0;
    NSLog(@"customIndex ist %lu", (unsigned long)customIndex);
    
    // Normalen gesamt + Restliche überbleibend vom Modulo am Rest der Zeile + eine ganze Zeile
    selectedIndex = NUM_IMAGES + (imagesPerRow - (NUM_IMAGES % imagesPerRow)) + imagesPerRow + customIndex;
    
    NSLog(@"Berechnungen ergeben %lu", (unsigned long)selectedIndex);
    _selectedImageIndex = selectedIndex;
    [self drawSelectedImageViewWithIndex];
}

- (void)handleTapGesture:(UIGestureRecognizer*)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];

    // Convert the point to row/col
    NSUInteger col = point.x / (IMAGE_SIZE + 2 * spacing);
    NSUInteger row = point.y / (IMAGE_SIZE + 2 * spacing);

    // Convert the row/col to an index
    NSUInteger index = row * imagesPerRow + col;

//    self.selectedImageIndex = index;
    NSLog(@"NormalIndex %lu", (unsigned long)index);
    if(index >= numImages)
    {
        NSUInteger customIndex = index - imagesPerRow - (imagesPerRow - (NUM_IMAGES % imagesPerRow));
        NSLog(@"CustomIndex %lu", (unsigned long)customIndex);
        if(customIndex >= numImages)
        {
            NSUInteger customIconIndex = customIndex - NUM_IMAGES;
            if(customIconIndex < numCustomImages)
            {
                // SELECT IT
                self.selectedImageIndex = index;
                
                NSLog(@"CustomIcon %lu", (unsigned long)customIndex);
                NSLog(@"Icon %lu of %lu CI", (unsigned long)customIconIndex, (unsigned long)numCustomImages - 1);
                
//                 Notify delegate with custom Key
                        if ([_delegate respondsToSelector:@selector(imageSelectionView:selectedImageCustomWithKey:)])
                        {
                            [_delegate imageSelectionView:self selectedImageCustomWithKey:[[[ImageFactory sharedInstance] customsKeys ]objectAtIndex:customIconIndex]];
                        }
            }
        }
    }
    else
    {
        self.selectedImageIndex = index;
        
        // Notify the delegate
        if ([_delegate respondsToSelector:@selector(imageSelectionView:selectedImageIndex:)]) {
            [_delegate imageSelectionView:self selectedImageIndex:_selectedImageIndex];
        }
    }
    
}

@end
