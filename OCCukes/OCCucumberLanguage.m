// OCCukes OCCucumberLanguage.m
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

#import "OCCucumberLanguage.h"
#import "OCCucumberWorld.h"
#import "OCCucumberStepDefinition.h"
#import "OCCucumberStepMatch.h"

@implementation OCCucumberLanguage

@synthesize currentWorld = _currentWorld;
@synthesize stepDefinitions = _stepDefinitions;

// designated initialiser
- (id)init
{
	if ((self = [super init]))
	{
		[self setStepDefinitions:[NSMutableSet set]];
	}
	return self;
}

- (void)registerStepDefinition:(OCCucumberStepDefinition *)stepDefinition
{
	[[self stepDefinitions] addObject:stepDefinition];
}

- (OCCucumberStepDefinition *)registerStep:(NSRegularExpression *)regularExpression block:(void (^)(NSArray *arguments))block
{
	OCCucumberStepDefinition *stepDefinition = [[OCCucumberStepDefinition alloc] initWithRegularExpression:regularExpression block:block];
	[self registerStepDefinition:stepDefinition];
	return stepDefinition;
}

- (OCCucumberStepDefinition *)registerStepPattern:(NSString *)pattern block:(void (^)(NSArray *arguments))block
{
	OCCucumberStepDefinition *stepDefinition = [[OCCucumberStepDefinition alloc] initWithPattern:pattern block:block];
	[self registerStepDefinition:stepDefinition];
	return stepDefinition;
}

- (NSArray *)stepMatches:(NSString *)nameToMatch
{
	NSMutableArray *matches = [NSMutableArray array];
	for (OCCucumberStepDefinition *stepDefinition in [self stepDefinitions])
	{
		NSArray *arguments = [stepDefinition argumentsFromStepName:nameToMatch];
		if (arguments)
		{
			[matches addObject:[[OCCucumberStepMatch alloc] initWithDefinition:stepDefinition arguments:arguments]];
		}
	}
	return [matches copy];
}

- (void)beginScenario
{
	[self setCurrentWorld:[[OCCucumberWorld alloc] init]];
}

- (void)endScenario
{
	[self setCurrentWorld:nil];
}

+ (OCCucumberLanguage *)sharedLanguage
{
	static OCCucumberLanguage *__strong sharedLanguage;
	if (sharedLanguage == nil)
	{
		sharedLanguage = [[OCCucumberLanguage alloc] init];
	}
	return sharedLanguage;
}

@end
