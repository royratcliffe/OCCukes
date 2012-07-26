// OCCukes OCCucumber.m
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

#import "OCCucumber.h"
#import "OCCucumberLanguage.h"
#import "OCCucumberWorld.h"
#import "OCCucumberStepDefinition.h"

@implementation OCCucumber

+ (void)given:(NSString *)pattern step:(void (^)(NSArray *arguments))block
{
	[[OCCucumberLanguage sharedLanguage] registerStepPattern:pattern block:block];
}

+ (void)when:(NSString *)pattern step:(void (^)(NSArray *arguments))block
{
	[[OCCucumberLanguage sharedLanguage] registerStepPattern:pattern block:block];
}

+ (void)then:(NSString *)pattern step:(void (^)(NSArray *arguments))block
{
	[[OCCucumberLanguage sharedLanguage] registerStepPattern:pattern block:block];
}

+ (void)given:(NSString *)pattern step:(void (^)(NSArray *arguments))block file:(const char *)file line:(unsigned int)line
{
	OCCucumberStepDefinition *stepDefinition = [[OCCucumberLanguage sharedLanguage] registerStepPattern:pattern block:block];
	[stepDefinition setFile:file];
	[stepDefinition setLine:line];
}

+ (void)when:(NSString *)pattern step:(void (^)(NSArray *arguments))block file:(const char *)file line:(unsigned int)line
{
	OCCucumberStepDefinition *stepDefinition = [[OCCucumberLanguage sharedLanguage] registerStepPattern:pattern block:block];
	[stepDefinition setFile:file];
	[stepDefinition setLine:line];
}

+ (void)then:(NSString *)pattern step:(void (^)(NSArray *arguments))block file:(const char *)file line:(unsigned int)line
{
	OCCucumberStepDefinition *stepDefinition = [[OCCucumberLanguage sharedLanguage] registerStepPattern:pattern block:block];
	[stepDefinition setFile:file];
	[stepDefinition setLine:line];
}

+ (OCCucumberWorld *)currentWorld
{
	return [[OCCucumberLanguage sharedLanguage] currentWorld];
}

+ (void)pending
{
	@throw [NSArray arrayWithObject:@"pending"];
}

+ (void)pending:(NSString *)message
{
	@throw [NSArray arrayWithObjects:@"pending", message, nil];
}

@end
