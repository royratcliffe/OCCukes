/* OCCukesTests QuotedArgumentSteps.m
 *
 * Copyright © 2012, The OCCukes Organisation. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the “Software”), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in
 *	all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS,” WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO
 * EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 ******************************************************************************/

#import <OCCukes/OCCukes.h>

__attribute__((constructor))
void LoadQuotedArgumentSteps()
{
	[OCCucumber when:@"^my scenario includes some \"(.*)\"$" step:^(NSArray *arguments) {
		OCCucumberWorld *world = [[OCCucumberLanguage sharedLanguage] currentWorld];
		[world setValue:[arguments objectAtIndex:0] forKey:@"quotedArgument"];
	} file:__FILE__ line:__LINE__];
	
	[OCCucumber then:@"^the \"(.*?)\" string appears as an argument to the step definition$" step:^(NSArray *arguments) {
		OCCucumberWorld *world = [[OCCucumberLanguage sharedLanguage] currentWorld];
		NSString *quotedArgument = [world valueForKey:@"quotedArgument"];
		NSString *argument0 = [arguments objectAtIndex:0];
		if (![argument0 isEqualToString:quotedArgument])
		{
			[NSException raise:@"QuotedArgumentMismatch" format:@"\"%@\" does not equal \"%@\"", argument0, quotedArgument];
		}
	} file:__FILE__ line:__LINE__];
}
