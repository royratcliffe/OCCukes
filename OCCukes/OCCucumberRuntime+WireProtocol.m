// OCCukes OCCucumberRuntime+WireProtocol.m
//
// Copyright © 2012, Roy Ratcliffe, Pioneering Software, United Kingdom
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

#import "OCCucumberRuntime+WireProtocol.h"
#import "OCCucumberLanguage.h"
#import "OCCucumberStepDefinition.h"
#import "OCCucumberStepMatch.h"

NSString *__OCCucumberRuntimeCamelize(NSString *string);

@implementation OCCucumberRuntime(WireProtocol)

- (id)handleWirePacketWithObject:(id)object
{
	id result = nil;
	if ([object isKindOfClass:[NSArray class]])
	{
		result = [self handleWirePacketWithArray:(NSArray *)object];
	}
	return result;
}

- (id)handleWirePacketWithArray:(NSArray *)array
{
	id result = nil;
	switch ([array count])
	{
		case 1:
		{
			SEL selector = NSSelectorFromString([NSString stringWithFormat:@"handle%@", __OCCucumberRuntimeCamelize([array objectAtIndex:0])]);
			if ([self respondsToSelector:selector])
			{
				result = [self performSelector:selector];
			}
			break;
		}
		case 2:
		{
			// Handle wire packets consisting of two array elements. The first
			// element describes the message. The second element, either an
			// array or a hash, describes the message parameter. Invoke the
			// runtime with a selector of the form -handle<Message>WithArray: or
			// -handle<Message>WithHash: passing an array or a dictionary,
			// respectively. Ignore messages where there is no corresponding
			// selector.
			NSString *with;
			id object = [array objectAtIndex:1];
			if ([object isKindOfClass:[NSArray class]])
			{
				with = @"Array";
			}
			else if ([object isKindOfClass:[NSDictionary class]])
			{
				with = @"Hash";
			}
			else
			{
				with = nil;
			}
			if (with)
			{
				SEL selector = NSSelectorFromString([NSString stringWithFormat:@"handle%@With%@:", __OCCucumberRuntimeCamelize([array objectAtIndex:0]), with]);
				if ([self respondsToSelector:selector])
				{
					result = [self performSelector:selector withObject:object];
				}
			}
		}
	}
	return result;
}

- (id)handleStepMatchesWithHash:(NSDictionary *)hash
{
	NSMutableArray *stepMatches = [NSMutableArray array];
	NSString *nameToMatch = [hash objectForKey:@"name_to_match"];
	OCCucumberLanguage *language = [self language];
	if (language == nil)
	{
		language = [OCCucumberLanguage sharedLanguage];
	}
	for (OCCucumberStepDefinition *stepDefinition in [language stepDefinitions])
	{
		for (OCCucumberStepMatch *match in [language stepMatches:nameToMatch])
		{
			[stepMatches addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[match stepDefinition] identifierString], @"id", [match stepArguments], @"args", nil]];
		}
	}
	return [NSArray arrayWithObjects:@"success", [stepMatches copy], nil];
}

- (id)handleSnippetTextWithHash:(NSDictionary *)hash
{
	NSString *multilineArgClass = [hash objectForKey:@"multiline_arg_class"];
	NSString *stepKeyword = [hash objectForKey:@"step_keyword"];
	NSString *stepName = [hash objectForKey:@"step_name"];
	return [NSArray arrayWithObjects:@"success", [NSString stringWithFormat:@"\t[OCCucumber %@:@\"^%@$\" step:^(NSArray *arguments) {\n\t\t// express the regular expression above with the code you wish you had\n\t\t[OCCucumber pending:@\"TODO\"];\n\t}];", [stepKeyword lowercaseString], stepName], nil];
}

- (id)handleBeginScenario
{
	return [NSArray arrayWithObject:@"success"];
}

- (id)handleEndScenario
{
	return [NSArray arrayWithObject:@"success"];
}

- (id)handleInvokeWithHash:(NSDictionary *)hash
{
	id result = nil;
	OCCucumberLanguage *language = [self language];
	if (language == nil)
	{
		language = [OCCucumberLanguage sharedLanguage];
	}
	NSString *identifierString = [hash objectForKey:@"id"];
	for (OCCucumberStepDefinition *stepDefinition in [language stepDefinitions])
	{
		if ([[stepDefinition identifierString] isEqualToString:identifierString])
		{
			// The step block throws any object in order to respond. If the wire
			// server can successfully convert the thrown object to JSON, it
			// becomes the reply. If not, there is no reply.
			@try
			{
				[stepDefinition block]([hash objectForKey:@"args"]);
			}
			@catch (id object)
			{
				result = object;
			}
			break;
		}
	}
	return result;
}

@end

/*
 * Converts a string with underscore delimiters to camel-case with leading
 * capital letter. Useful for deriving selectors from wire protocol messages,
 * e.g. for converting begin_scenario to BeginScenario.
 */
NSString *__OCCucumberRuntimeCamelize(NSString *string)
{
	NSMutableArray *components = [NSMutableArray array];
	for (NSString *component in [string componentsSeparatedByString:@"_"])
	{
		[components addObject:[component capitalizedString]];
	}
	return [components componentsJoinedByString:@""];
}
