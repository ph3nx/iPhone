//
//  NSString+URLTools.h
//  SimpleTwitter
//
//  Created by Clemens Wagner on 10.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLTools)

- (NSString *)encodedStringForURLWithEncoding:(CFStringEncoding)inEncoding;

@end
