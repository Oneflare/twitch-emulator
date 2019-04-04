//
//  GameboyCore.h
//  Gameboy
//
//  Created by Pasquale Barilla on 3/4/19.
//  Copyright © 2019 oneflare. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GameboyCore : NSObject

-(void)loadRom:(NSData *)rom;

@end

NS_ASSUME_NONNULL_END
