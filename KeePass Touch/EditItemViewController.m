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

#import "EditItemViewController.h"
#import "ImageButtonCell.h"
#import "ImageFactory.h"
#import "Kdb4Node.h"
#import "Base64.h"

@interface EditItemViewController ()
@property (nonatomic, strong) ImageButtonCell *imageButtonCell;
@end

@implementation EditItemViewController

- (id)init {
    self = [super init];
    if (self) {
        _nameTextField = [[UITextField alloc] init];
        self.nameTextField.placeholder = NSLocalizedString(@"Name", nil);
        self.nameTextField.delegate = self;
        self.nameTextField.returnKeyType = UIReturnKeyDone;
        self.nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.imageButtonCell = [[ImageButtonCell alloc] initWithLabel:NSLocalizedString(@"Image", nil)];
        [self.imageButtonCell.imageButton addTarget:self
                                        action:@selector(imageButtonPressed)
                              forControlEvents:UIControlEventTouchUpInside];
        
        self.controls = [NSArray arrayWithObjects:self.nameTextField, self.imageButtonCell, nil];
    }
    return self;
}

- (id)initWithEntry:(KdbEntry *)entry {
    self = [self init];
    if (self) {
        self.title = NSLocalizedString(@"Edit Entry", nil);
        self.isKdb4 = [entry isKindOfClass:[Kdb4Entry class]];
        if(self.isKdb4)
        {
            Kdb4Entry *ent4 = ((Kdb4Entry *)entry);
            if(ent4.customIconUuid != nil)
            {
                self.searchKey = [[NSString alloc] initWithData:ent4.customIconUuid.getData encoding:NSASCIIStringEncoding];
                [self setSelectedImageCustom];
            }
            else
            {
                [self setSelectedImageIndex:entry.image];
            }
        }
        else
            [self setSelectedImageIndex:entry.image];
        self.nameTextField.text = entry.title;
        
    }
    return self;
}

- (id)initWithGroup:(KdbGroup *)group {
    self = [self init];
    if (self) {
        self.title = NSLocalizedString(@"Edit Group", nil);
        self.isKdb4 = [group isKindOfClass:[Kdb4Group class]];
        if(self.isKdb4)
        {
            Kdb4Group *grp4 = ((Kdb4Group *)group);
            if(grp4.customIconUuid != nil)
            {
                self.searchKey = [[NSString alloc] initWithData:grp4.customIconUuid.getData  encoding:NSASCIIStringEncoding];
                [self setSelectedImageCustom];
            }
            else
            {
                [self setSelectedImageIndex:group.image];
            }
        }
        else
            [self setSelectedImageIndex:group.image];
        self.nameTextField.text = group.name;
        
    }
    return self;
}

- (void)setSelectedImageIndex:(NSUInteger)selectedImageIndex {
    _selectedImageIndex = selectedImageIndex;
    
    
    UIImage *image = [[ImageFactory sharedInstance] imageForIndex:selectedImageIndex];
    
    
    [self.imageButtonCell.imageButton setImage:image forState:UIControlStateNormal];
}

- (void)setSelectedImageCustom
{
    UIImage *image = [[ImageFactory sharedInstance] imageForKey:self.searchKey];
    
    [self.imageButtonCell.imageButton setImage:image forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    ImageSelectionViewController *imageSelectionViewController = [[ImageSelectionViewController alloc] init];
    imageSelectionViewController.imageSelectionView.delegate = self;
    if(_selectedImageIndex == 0 && self.searchKey != nil)
    {
        NSLog(@"Habe ein Custom Image");
        NSUInteger keyIndex = [[ImageFactory sharedInstance] indexForKey:self.searchKey];
        if(keyIndex != NSUIntegerMax)
        {
            imageSelectionViewController.customIndex = keyIndex;
        }
    }
    else
    {
        imageSelectionViewController.imageSelectionView.selectedImageIndex = _selectedImageIndex;
    }
    
    [self.navigationController pushViewController:imageSelectionViewController animated:YES];
}

- (void)imageSelectionView:(ImageSelectionView *)imageSelectionView selectedImageIndex:(NSUInteger)imageIndex {
    self.selectedImageIndex = imageIndex;
}

- (void)imageSelectionView:(ImageSelectionView *)imageSelectionView selectedImageCustomWithKey:(NSString *)key
{
    self.searchKey = key;
    [self setSelectedImageCustom];
}

@end
