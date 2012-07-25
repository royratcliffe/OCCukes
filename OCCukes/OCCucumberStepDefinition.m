// OCCukes OCCucumberStepDefinition.m
//
// Copyright © 2012, The OCCukes Organisation. All rights reserved.
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

#import "OCCucumberStepDefinition.h"
#import "OCCucumberStepArgument.h"

@implementation OCCucumberStepDefinition

@synthesize regularExpression = _regularExpression;
@synthesize block = _block;
@synthesize file = _file;
@synthesize line = _line;

- (id)initWithRegularExpression:(NSRegularExpression *)regularExpression block:(void (^)(NSArray *arguments))block
{
	if ((self = [self init]))
	{
		[self setRegularExpression:regularExpression];
		[self setBlock:block];
	}
	return self;
}

- (id)initWithPattern:(NSString *)pattern block:(void (^)(NSArray *arguments))block
{
	NSError *__autoreleasing error = nil;
	NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
	// What to do with the error if the expression compiler raises one?
	if (error)
	{
		[NSException raise:[error domain] format:@"%@", [error localizedDescription]];
	}
	return regularExpression ? [self initWithRegularExpression:regularExpression block:block] : nil;
}

- (NSString *)identifierString
{
	return [NSString stringWithFormat:@"%p", self];
}

- (NSArray *)argumentsFromStepName:(NSString *)stepName
{
	NSMutableArray *arguments;
	NSTextCheckingResult *match = [[self regularExpression] firstMatchInString:stepName options:0 range:NSMakeRange(0, [stepName length])];
	if (match)
	{
		arguments = [NSMutableArray array];
		// The first range always captures the entire match; subsequent ranges
		// match regular expression capture groups.
		for (NSUInteger i = 1; i < [match numberOfRanges]; i++)
		{
			OCCucumberStepArgument *argument = [[OCCucumberStepArgument alloc] init];
			NSRange range = [match rangeAtIndex:i];
			[argument setOffset:range.location];
			[argument setVal:[stepName substringWithRange:range]];
			[arguments addObject:argument];
		}
	}
	else
	{
		// Yes, you can send -copy to nil; [(NSObject *)nil copy] answers
		// nil. In Objective-C, nil is a valid message receiver.
		arguments = nil;
	}
	return [arguments copy];
}

- (void)invokeWithArguments:(NSArray *)arguments
{
	[self block](arguments);
}

@end
