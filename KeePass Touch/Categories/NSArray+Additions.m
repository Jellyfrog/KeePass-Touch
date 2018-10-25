//
//  NSArray+Additions.m
//  KeePass Touch
//
//  Created by Aljoscha Lüers on 10.06.17.
//  Copyright © 2017 Self. All rights reserved.
//

#import "NSArray+Additions.h"

@implementation NSArray (Additions)

- (instancetype)arrayByRemovingObject:(id)object {
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", object]]; // Anmerkung(falls StringCompare nicht geht) sonst LIKE[c] %@
}

- (instancetype)arrayByRemovingObjects:(NSArray *)array
{
    if(array.count > 0)
    {
        id object = [array objectAtIndex:0];
        NSArray *removed = [self arrayByRemovingObject:object];
        return [removed arrayByRemovingObjects:[array arrayByRemovingObject:object]];
    }
    else
    {
        return self;
    }
    
}

@end
