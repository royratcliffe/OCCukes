// OCCukes OCCucumberStepDefinition.h
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

#import <Foundation/Foundation.h>

/**
 * Step definitions hold a regular expression and a C block.
 *
 * You create a step definition by registering a Give, When or Then
 * step. You can invoke a step definition.
 *
 * Step definitions carry a file and line property. Assign these to `__FILE__`
 * and `__LINE__` respectively. Cucumber reports source file-colon-line
 * references for step definitions. These become clickable in editors such as
 * TextMate and RubyMine. Very useful when developing. Note that `__FILE__` is a
 * pointer to a static string of characters. No need to copy the static
 * null-terminated C string. As a static, the string will remain in place and
 * unchanged. Line numbers are ordinal, rather than cardinal. Line 1 is the
 * first line, not the second line. Hence line 0 means line number unspecified.
 */
@interface OCCucumberStepDefinition : NSObject

@property(strong, NS_NONATOMIC_IOSONLY) NSRegularExpression *regularExpression;
@property(copy, NS_NONATOMIC_IOSONLY) void (^block)(NSArray *arguments);
@property(assign, NS_NONATOMIC_IOSONLY) const char *file;
@property(assign, NS_NONATOMIC_IOSONLY) unsigned int line;

// convenience initialisers
- (id)initWithRegularExpression:(NSRegularExpression *)regularExpression block:(void (^)(NSArray *arguments))block;

/**
 * Constructs a new step definition from a given pattern string.
 *
 * Compiles a new regular expression for the step based on the given
 * pattern string. Answers a new step definition if the expression successfully
 * compiles. Otherwise answers @c nil.
 */
- (id)initWithPattern:(NSString *)pattern block:(void (^)(NSArray *arguments))block;

/**
 * Answers a unique string identifier for the step definition.
 *
 * All step definitions need a unique string identifier. The Cucumber
 * client utilises these identifiers in order to reference remote step
 * definitions across the wire. Identifiers are string values. So long as they
 * are one-to-one with the identity of the step definition, and not the state of
 * the step definition, their exact contents are arbitrary. The implementation
 * uses a string value based on the "self" pointer.
 */
- (NSString *)identifierString;

/**
 * @result Answers an array of regular-expression match capture values, one for
 * each matching capture group. Answers @c nil if the step definition's regular
 * expression pattern does not match the given step name. Answers an array of
 * zero length if the pattern matches but no capture groups exist in the step
 * expression.
 */
- (NSArray *)argumentsFromStepName:(NSString *)stepName;

/**
 * Invokes a step given its name, using the given arguments.
 *
 * First derives the step matches. If it finds just one, invokes the
 * step using the supplied arguments.
 * Step definitions can invoke other step definitions as necessary. This method
 * gives access to the steps @em by @em name. There could be more than one
 * matching definition. There may even be no match. In such cases, the step
 * invocation throws an exception.
 */
- (void)invokeWithArguments:(NSArray *)arguments;

@end
