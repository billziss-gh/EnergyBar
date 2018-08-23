/**
 * @file StringToUrlTransformer.m
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "StringToUrlTransformer.h"

@implementation StringToUrlTransformer
+ (Class)transformedValueClass
{
    return [NSURL class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return nil != value ? [NSURL fileURLWithPath:[value description]] : nil;
}

- (id)reverseTransformedValue:(id)value
{
    return [value path];
}
@end
