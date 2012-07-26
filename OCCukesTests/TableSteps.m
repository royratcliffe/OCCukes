/* OCCukesTests TableSteps.m
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
void LoadTableSteps()
{
	[OCCucumber given:@"^a table:$" step:^(NSArray *arguments) {
		[[OCCucumber currentWorld] setValue:[arguments objectAtIndex:0] forKey:@"table"];
	} file:__FILE__ line:__LINE__];
	
	// Cucumber sends the table as an array of arrays, a two-dimensional
	// array. The arguments are strings, even the numbers. Apple's JSON
	// decoder does not make numbers out of the arguments simply because
	// Cucumber sends the arguments in quotes. They are strings. Use the
	// -integerValue method to convert from string to integer. Adjust the
	// row and column numbers for 1-based versus 0-based addressing.
	[OCCucumber then:@"^row (\\d+), column (\\d+) equals \"(.*?)\"$" step:^(NSArray *arguments) {
		NSInteger rowNumber = [(NSString *)[arguments objectAtIndex:0] integerValue];
		NSInteger columnNumber = [(NSString *)[arguments objectAtIndex:1] integerValue];
		NSArray *row = [[[OCCucumber currentWorld] valueForKey:@"table"] objectAtIndex:rowNumber - 1];
		NSString *actual = [row objectAtIndex:columnNumber - 1];
		NSString *expected = [arguments objectAtIndex:2];
		if (![actual isEqualToString:expected])
		{
			[NSException raise:@"TableCellMismatch" format:@"cell at row %ld, column %ld equals %@; expected %@", (long)rowNumber, (long)columnNumber, actual, expected];
		}
	} file:__FILE__ line:__LINE__];
}
