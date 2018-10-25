//
//  KPTextField.m
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 21.12.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import "KPTextField.h"

@implementation KPTextField

- (id)init {
    self = [super init];
    if(self) {
        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [self setLeftViewMode:UITextFieldViewModeAlways];
        self.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.autocorrectionType = UITextAutocorrectionTypeNo;
        [self setLeftView:spacerView];
    }
    
    return self;
}

@end
