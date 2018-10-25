//
//  NSArray+Additions.h
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 10.06.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Additions)

- (instancetype)arrayByRemovingObject:(id)object;

- (instancetype)arrayByRemovingObjects:(NSArray *)array;

@end
