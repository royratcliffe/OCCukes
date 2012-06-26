// OCCukes OCCucumberLanguage.h
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

#import <Foundation/Foundation.h>

@class OCCucumberStepDefinition;

@interface OCCucumberLanguage : NSObject

@property(strong, NS_NONATOMIC_IOSONLY) NSMutableSet *stepDefinitions;

- (void)registerStepDefinition:(OCCucumberStepDefinition *)stepDefinition;
- (OCCucumberStepDefinition *)registerStep:(NSRegularExpression *)regularExpression block:(void (^)(NSArray *arguments))block;
- (OCCucumberStepDefinition *)registerStepPattern:(NSString *)pattern block:(void (^)(NSArray *arguments))block;

/*!
 * @brief Answers the steps matching a given step name.
 * @details There could be more than one. The resulting array contains Step
 * Match objects. Each Step Match retains its step definition for later
 * invocation and the argument values derived from the match.
 */
- (NSArray *)stepMatches:(NSString *)nameToMatch;

+ (OCCucumberLanguage *)sharedLanguage;

@end
