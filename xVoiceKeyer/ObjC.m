//
//  ObjC.m
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/14/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObjC.h"

@implementation ObjC

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
    }
}

@end
