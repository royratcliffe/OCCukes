/* OCCukesTests MultilineStringSteps.m
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
void LoadMultilineStringSteps()
{
	[OCCucumber given:@"^a multiline string containing$" step:^(NSArray *arguments) {
		[[OCCucumber currentWorld] setValue:[arguments objectAtIndex:0] forKey:@"lines"];
	} file:__FILE__ line:__LINE__];
	
	[OCCucumber then:@"^there are (\\d+) lines of text$" step:^(NSArray *arguments) {
		NSArray *lines = [[[OCCucumber currentWorld] valueForKey:@"lines"] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		if ([lines count] != [[arguments objectAtIndex:0] integerValue])
		{
			[NSException raise:@"MultilineString" format:@"expected %lu lines, actually %lu lines", [lines count], [[arguments objectAtIndex:0] integerValue]];
		}
	} file:__FILE__ line:__LINE__];
}
