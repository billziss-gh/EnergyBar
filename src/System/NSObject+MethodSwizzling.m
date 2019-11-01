/**
 * @file NSObject+MethodSwizzling.h
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "NSObject+MethodSwizzling.h"
#import <objc/runtime.h>

@implementation NSObject (MethodSwizzling)
+ (BOOL)swizzleInstanceMethod:(SEL)oldsel withMethod:(SEL)newsel
{
    Method oldmeth = class_getInstanceMethod(self, oldsel);
    if (NULL == oldmeth)
    {
        NSLog(@"%s error: selector %s not found in class %@",
            __PRETTY_FUNCTION__, sel_getName(oldsel), self);
        return NO;
    }
    Method newmeth = class_getInstanceMethod(self, newsel);
    if (NULL == newmeth)
    {
        NSLog(@"%s error: selector %s not found in class %@",
            __PRETTY_FUNCTION__, sel_getName(newsel), self);
        return NO;
    }
    class_addMethod(self, oldsel,
        method_getImplementation(oldmeth), method_getTypeEncoding(oldmeth));
    class_addMethod(self, newsel,
        method_getImplementation(newmeth), method_getTypeEncoding(newmeth));
    /* IMPORTANT NOTE:
     * Must perform class_getInstanceMethod() again in case methods
     * were added from a superclass to this class.
     */
    method_exchangeImplementations(
        class_getInstanceMethod(self, oldsel),
        class_getInstanceMethod(self, newsel));
    return YES;
}
+ (BOOL)swizzleClassMethod:(SEL)oldsel withMethod:(SEL)newsel
{
    return [object_getClass(self) swizzleInstanceMethod:oldsel withMethod:newsel];
}
@end
