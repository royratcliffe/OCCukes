// OCCukes OCCucumberWorld.m
//
// Copyright © 2012, 2013, The OCCukes Organisation. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the “Software”), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "OCCucumberWorld.h"

@interface OCCucumberWorld()

@property(strong, NS_NONATOMIC_IOSONLY) NSMutableDictionary *values;

@end

@implementation OCCucumberWorld

// designated initialiser
- (id)init
{
	if ((self = [super init]))
	{
		[self setValues:[NSMutableDictionary dictionary]];
	}
	return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	[[self values] setObject:value forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return [[self values] objectForKey:key];
}

- (void)setNilValueForKey:(NSString *)key {
    return [[self values] removeObjectForKey:key];
}

@end
