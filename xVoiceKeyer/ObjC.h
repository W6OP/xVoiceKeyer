//
//  ObjC.h
//  SDRVoiceKeyer
//
//  Created by Peter Bourget on 2/14/17.
//  Copyright © 2017 Peter Bourget. All rights reserved.
//

// Used to catch Objective C exceptions and convert to Swift NSError
// http://stackoverflow.com/questions/32758811/catching-nsexception-in-swift/36454808#36454808

#ifndef ObjC_h
#define ObjC_h

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error;

@end

#endif /* ObjC_h */

