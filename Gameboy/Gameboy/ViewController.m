//
//  ViewController.m
//  Gameboy
//
//  Created by Pasquale Barilla on 3/4/19.
//  Copyright © 2019 oneflare. All rights reserved.
//

#import "ViewController.h"
#import "GameboyCore.h"

@interface ViewController() <GameboyDebugDelegate>

@property (strong, nonatomic) GameboyCore *gameboyCore;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

-(void)viewDidAppear {
    [super viewDidAppear];
    
    self.gameboyCore = [GameboyCore new];
    self.gameboyCore.delegate = self;
    
    NSData *testRom = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"cpu_instrs" ofType:@"gb"]];
    
    [self.gameboyCore loadRom:testRom];
    
//    [self becomeFirstResponder];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - GameboyDebugDelegate

-(void)updateRegisterDebugWithString:(NSString *)string {
    self.debugOutput.stringValue = string;
}


@end
