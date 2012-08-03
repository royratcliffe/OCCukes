// OCCukes OCCucumber.h
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

#import <Foundation/Foundation.h>

@class OCCucumberWorld;

/*!
 * @brief Offers a set of class-scoped convenience methods for interacting with
 * Cucumber language and runtime.
 * @details Typically, your unit tests will interact via this interface, rather
 * than via the Cucumber shared language, or some other instance of the language
 * class.
 *
 * All the class-scoped methods access the shared runtime's language, rather
 * than the shared language. Typically this amounts to exactly the same
 * thing. The answer differs only in one case: when the runtime overrides the
 * language. In that case, the runtime takes precedence.
 */
@interface OCCucumber : NSObject

//----------------------------------------------------------- Language Shortcuts

+ (void)given:(NSString *)pattern step:(void (^)(NSArray *arguments))block;
+ (void)when:(NSString *)pattern step:(void (^)(NSArray *arguments))block;
+ (void)then:(NSString *)pattern step:(void (^)(NSArray *arguments))block;

+ (void)given:(NSString *)pattern step:(void (^)(NSArray *arguments))block file:(const char *)file line:(unsigned int)line;
+ (void)when:(NSString *)pattern step:(void (^)(NSArray *arguments))block file:(const char *)file line:(unsigned int)line;
+ (void)then:(NSString *)pattern step:(void (^)(NSArray *arguments))block file:(const char *)file line:(unsigned int)line;

/*!
 * @brief Answers the shared language's current world, a shortcut.
 * @details World's appear and disappear as scenarios begin and end. Step
 * definitions use them as scratchpads for persisting arguments and other pieces
 * of information in-between steps. Use key-value coding to access world values.
 */
+ (OCCucumberWorld *)currentWorld;

//------------------------------------------------------------ Runtime Shortcuts

+ (void)pending;
+ (void)pending:(NSString *)message;

@end
