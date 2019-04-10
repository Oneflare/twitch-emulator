//
//  GameboyCore.m
//  Gameboy
//
//  Created by Pasquale Barilla on 3/4/19.
//  Copyright © 2019 oneflare. All rights reserved.
//

#import "GameboyCore.h"
#import "SDL.h"

@interface GameboyCore() {
    // Memory
    BYTE cartMemory[0x200000]; // <- On the cartridge
    BYTE romMemory[0x10000]; // <- Inside the gameboy
    
    // Registers
    union Register registerAF;
    union Register registerBC;
    union Register registerDE;
    union Register registerHL;
    
    WORD programCounter;
    union Register stackPointer;
    BYTE flagRegister;
    
    BYTE currentRomBank;
    BYTE currentRamBank;
    BYTE ramBanks[0x8000];
    
    bool enableRam;
    bool romBanking;
    BankType bankType;
    
    BOOL isRunning;
}

@property (strong, nonatomic) NSData *romData;

@end

@implementation GameboyCore

#pragma mark - Lifecycle

-(void)turnOn {
    [self zeroOutRegisters];
    [self initializeRegisters];
    [self initializeRomMemory];
}

-(void)loadRom:(NSData *)rom {
    self.romData = rom;
    [self turnOn];
    
    const BYTE *buf = self.romData.bytes;
    for (int i = 0; i < self.romData.length; i++) {
        cartMemory[i] = buf[i];
    }
    
    [self setBankType];
    currentRomBank = 1;
    
    memset(ramBanks, 0, sizeof(ramBanks));
    currentRamBank = 0;
    
    [NSThread detachNewThreadWithBlock:^{
        [self displayTestWindow];
    }];
    
//    [self.delegate updateRegisterDebugWithString:@"This is coming from the gameboy"];
    
    [self beginEmulation];
    
}

-(void)beginEmulation {
    isRunning = true;
    
    while(isRunning) {
        int ticks = SDL_GetTicks();
        SDL_Event event;
        
        while(SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                SDL_Quit();
                isRunning = false;
                return;
            } else if (event.type == SDL_KEYDOWN) {
                NSLog(@"DOWN");
                // do something
            } else if (event.type == SDL_KEYUP) {
                NSLog(@"UP");
                // do something
            }
        }
        
        int x = 1000 / 59.70 - (SDL_GetTicks() - ticks);
        if (x > 0) {
            SDL_Delay(x);
            [self.delegate updateRegisterDebugWithString:[self getDebugRegisterString]];
            [self updateEmulator];
        }
    }
}

-(void)updateEmulator {
    const int MAXCYCLES = 20;
    int currentCycles = 0;
    
    while (currentCycles < MAXCYCLES) {
        int cycles = [self fetchDecodeExecute];
        currentCycles += cycles;
        
        programCounter++;
        
        // Update timing
        // Update graphics
        // Check and handle interrupts
    }
    
    // update screen
}

-(int)fetchDecodeExecute {
    WORD currentInstruction = [self readMemoryFromAddress:programCounter];
    int cycles = 0;
    
    switch (currentInstruction) {
        case 0x06: {
            [self loadValue:[self readMemoryFromAddress:programCounter + 1] intoRegister:RegB];
            
            cycles = 8;
            break;
        }
        case 0x0E: {
            [self loadValue:[self readMemoryFromAddress:programCounter + 1] intoRegister:RegC];
            
            cycles = 8;
            break;
        }
        case 0x16: {
            [self loadValue:[self readMemoryFromAddress:programCounter + 1] intoRegister:RegD];
            
            cycles = 8;
            break;
        }
        case 0x1E: {
            [self loadValue:[self readMemoryFromAddress:programCounter + 1] intoRegister:RegE];
            
            cycles = 8;
            break;
        }
        case 0x26: {
            [self loadValue:[self readMemoryFromAddress:programCounter + 1] intoRegister:RegH];
            
            cycles = 8;
            break;
        }
        case 0x2E: {
            [self loadValue:[self readMemoryFromAddress:programCounter + 1] intoRegister:RegL];
            
            cycles = 8;
            break;
        }
        case 0x7F: {
            [self loadValue:registerAF.hi intoRegister:RegA];
            
            cycles+=4;
            break;
        }
        case 0x78: {
            [self loadValue:registerAF.hi intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x79: {
            [self loadValue:registerAF.hi intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x7A: {
            [self loadValue:registerAF.hi intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x7B: {
            [self loadValue:registerAF.hi intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x7E: {
            [self loadValue:registerAF.hi intoRegister:RegHL];
            
            cycles+=8;
            break;
        }
        case 0x40: {
            [self loadValue:registerBC.hi intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x41: {
            [self loadValue:registerBC.hi intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x42: {
            [self loadValue:registerBC.hi intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x43: {
            [self loadValue:registerBC.hi intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x44: {
            [self loadValue:registerBC.hi intoRegister:RegH];
            
            cycles+=4;
            break;
        }
        case 0x45: {
            [self loadValue:registerBC.hi intoRegister:RegL];
            
            cycles+=4;
            break;
        }
        case 0x46: {
            [self loadValue:registerBC.hi intoRegister:RegHL];
            
            cycles+=8;
            break;
        }
        case 0x48: {
            [self loadValue:registerBC.lo intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x49: {
            [self loadValue:registerBC.lo intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x4A: {
            [self loadValue:registerBC.lo intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x4B: {
            [self loadValue:registerBC.lo intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x4C: {
            [self loadValue:registerBC.lo intoRegister:RegH];
            
            cycles+=4;
            break;
        }
        case 0x4D: {
            [self loadValue:registerBC.lo intoRegister:RegL];
            
            cycles+=4;
            break;
        }
        case 0x4E: {
            [self loadValue:registerBC.lo intoRegister:RegHL];
            
            cycles+=8;
            break;
        }
        case 0x50: {
            [self loadValue:registerDE.hi intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x51: {
            [self loadValue:registerDE.hi intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x52: {
            [self loadValue:registerDE.hi intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x53: {
            [self loadValue:registerDE.hi intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x54: {
            [self loadValue:registerDE.hi intoRegister:RegH];
            
            cycles+=4;
            break;
        }
        case 0x55: {
            [self loadValue:registerDE.hi intoRegister:RegL];
            
            cycles+=4;
            break;
        }
        case 0x56: {
            [self loadValue:registerDE.hi intoRegister:RegHL];
            
            cycles+=8;
            break;
        }
        case 0x58: {
            [self loadValue:registerDE.lo intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x59: {
            [self loadValue:registerDE.lo intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x5A: {
            [self loadValue:registerDE.lo intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x5B: {
            [self loadValue:registerDE.lo intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x5C: {
            [self loadValue:registerDE.lo intoRegister:RegH];
            
            cycles+=4;
            break;
        }
        case 0x5D: {
            [self loadValue:registerDE.lo intoRegister:RegL];
            
            cycles+=4;
            break;
        }
        case 0x5E: {
            [self loadValue:registerDE.lo intoRegister:RegHL];
            
            cycles+=8;
            break;
        }
        case 0x60: {
            [self loadValue:registerHL.hi intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x61: {
            [self loadValue:registerHL.hi intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x62: {
            [self loadValue:registerHL.hi intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x63: {
            [self loadValue:registerHL.hi intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x64: {
            [self loadValue:registerHL.hi intoRegister:RegH];
            
            cycles+=4;
            break;
        }
        case 0x65: {
            [self loadValue:registerHL.hi intoRegister:RegL];
            
            cycles+=4;
            break;
        }
        case 0x66: {
            [self loadValue:registerHL.hi intoRegister:RegHL];
            
            cycles+=8;
            break;
        }
        case 0x68: {
            [self loadValue:registerHL.lo intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x69: {
            [self loadValue:registerHL.lo intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x6A: {
            [self loadValue:registerHL.lo intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x6B: {
            [self loadValue:registerHL.lo intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x6C: {
            [self loadValue:registerHL.lo intoRegister:RegH];
            
            cycles+=4;
            break;
        }
        case 0x6D: {
            [self loadValue:registerHL.lo intoRegister:RegL];
            
            cycles+=4;
            break;
        }
        case 0x6E: {
            [self loadValue:registerHL.lo intoRegister:RegHL];
            
            cycles+=8;
            break;
        }
        case 0x70: {
            [self loadValue:registerHL.reg intoRegister:RegB];
            
            cycles+=8;
            break;
        }
        case 0x71: {
            [self loadValue:registerHL.reg intoRegister:RegC];
            
            cycles+=8;
            break;
        }
        case 0x72: {
            [self loadValue:registerHL.reg intoRegister:RegD];
            
            cycles+=8;
            break;
        }
        case 0x73: {
            [self loadValue:registerHL.reg intoRegister:RegE];
            
            cycles+=8;
            break;
        }
        case 0x74: {
            [self loadValue:registerHL.reg intoRegister:RegH];
            
            cycles+=8;
            break;
        }
        case 0x75: {
            [self loadValue:registerHL.reg intoRegister:RegL];
            
            cycles+=8;
            break;
        }
        case 0x36: { // (HL),n
            [self loadValue:registerHL.reg intoRegister:RegHL];
            
            cycles+=12;
            break;
        }
            // LD A,n
        case 0x7C: {
            [self loadValue:registerHL.hi intoRegister:RegA];
            
            cycles+=4;
            break;
        }
        case 0x7D: {
            [self loadValue:registerHL.lo intoRegister:RegA];
            
            cycles+=4;
            break;
        }
        case 0x0A: {
            [self loadValue:registerBC.reg intoRegister:RegA];
            
            cycles+=8;
            break;
        }
        case 0x1A: {
            [self loadValue:registerDE.reg intoRegister:RegA];
            
            cycles+=8;
            break;
        }
        case 0xFA: {
            // A, nn
            [self loadValue:[self readMemoryFromAddress:programCounter+1] intoRegister:RegA];
            
            cycles+=16;
            break;
        }
        case 0x3E: {
            // A, #
            [self loadValue:0x0 intoRegister:RegA];
            
            cycles+=8;
            break;
        }
        case 0x47: {
            [self loadValue:registerAF.hi intoRegister:RegB];
            
            cycles+=4;
            break;
        }
        case 0x4F: {
            [self loadValue:registerAF.hi intoRegister:RegC];
            
            cycles+=4;
            break;
        }
        case 0x57: {
            [self loadValue:registerAF.hi intoRegister:RegD];
            
            cycles+=4;
            break;
        }
        case 0x5F: {
            [self loadValue:registerAF.hi intoRegister:RegE];
            
            cycles+=4;
            break;
        }
        case 0x67: {
            [self loadValue:registerAF.hi intoRegister:RegH];
            
            cycles+=4;
            break;
        }
        case 0x6F: {
            [self loadValue:registerAF.hi intoRegister:RegL];
            
            cycles+=4;
            break;
        }
        case 0x02: {
            [self loadValue:registerBC.reg intoRegister:RegA];
            
            cycles+=8;
            break;
        }
        case 0x12: {
            [self loadValue:registerDE.reg intoRegister:RegA];
            
            cycles+=8;
            break;
        }
        case 0x77: {
            [self loadValue:registerHL.reg intoRegister:RegA];
            
            cycles+=8;
            break;
        }
        case 0xEA: {
            [self loadValue:[self readMemoryFromAddress:programCounter+1] intoRegister:RegA];
            
            cycles+=16;
            break;
        }
        case 0xF2: {
            [self loadValue:[self readMemoryFromAddress:0xFF00 + registerBC.lo] intoRegister:RegA];
            cycles+=8;
            break;
        }
        case 0xE2: {
            [self writeMemoryWithAddress:0xFF00 + registerBC.lo andData:registerAF.hi];
            cycles+=8;
            break;
        }
        case 0x3A: {
            [self loadValue:[self readMemoryFromAddress:registerHL.reg] intoRegister:RegA];
            registerHL.reg--;
            cycles+=8;
            break;
        }
            
    }
    
    return cycles;
}

-(void)loadValue:(BYTE)value intoRegister:(GameboyRegister)reg {
    switch (reg) {
        case RegA: {
            registerAF.hi = value;
            break;
        }
        case RegF: {
            registerAF.lo = value;
            break;
        }
        case RegAF: {
            registerAF.reg = value;
            break;
        }
        case RegB: {
            registerBC.hi = value;
            break;
        }
        case RegC: {
            registerBC.lo = value;
            break;
        }
        case RegBC: {
            registerBC.reg = value;
            break;
        }
        case RegD: {
            registerDE.hi = value;
            break;
        }
        case RegE: {
            registerDE.lo = value;
            break;
        }
        case RegDE: {
            registerDE.reg = value;
            break;
        }
        case RegH: {
            registerHL.hi = value;
            break;
        }
        case RegL: {
            registerHL.lo = value;
            break;
        }
        case RegHL: {
            registerHL.reg = value;
            break;
        }
    }
}



-(NSString *)getDebugRegisterString {
    return [NSString stringWithFormat:@"A: 0x%X F: 0x%X\nB: 0x%X C: 0x%X\nD: 0x%X E: 0x%X\nH: 0x%X L: 0x%X\nSP: 0x%X\nPC: 0x%X", registerAF.hi, registerAF.lo, registerBC.hi, registerBC.lo, registerDE.hi, registerDE.lo, registerHL.hi, registerHL.lo, stackPointer.reg, programCounter];
}

-(void)zeroOutRegisters {
    registerAF.hi = 0x00;
    registerAF.lo = 0x00;
    registerBC.hi = 0x00;
    registerBC.lo = 0x00;
    registerDE.hi = 0x00;
    registerDE.lo = 0x00;
    registerHL.hi = 0x00;
    registerHL.lo = 0x00;
    
    flagRegister = 0x00;
    programCounter = 0x00;
    stackPointer.reg = 0x00;
}

-(void)initializeRegisters {
    programCounter = 0x100;
    stackPointer.reg = 0xFFFE;
    flagRegister = 0x00;
    registerAF.reg = 0x01B0;
    registerBC.reg = 0x0013;
    registerDE.reg = 0x00D8;
    registerHL.reg = 0x014D;
}

-(void)initializeRomMemory {
    romMemory[0xFF05] = 0x00;
    romMemory[0xFF06] = 0x00;
    romMemory[0xFF07] = 0x00;
    romMemory[0xFF10] = 0x80;
    romMemory[0xFF11] = 0xBF;
    romMemory[0xFF12] = 0xF3;
    romMemory[0xFF14] = 0xBF;
    romMemory[0xFF16] = 0x3F;
    romMemory[0xFF17] = 0x00;
    romMemory[0xFF19] = 0xBF;
    romMemory[0xFF1A] = 0x7F;
    romMemory[0xFF1B] = 0xFF;
    romMemory[0xFF1C] = 0x9F;
    romMemory[0xFF1E] = 0xBF;
    romMemory[0xFF20] = 0xFF;
    romMemory[0xFF21] = 0x00;
    romMemory[0xFF22] = 0x00;
    romMemory[0xFF23] = 0xBF;
    romMemory[0xFF24] = 0x77;
    romMemory[0xFF25] = 0xF3;
    romMemory[0xFF26] = 0xF1;
    romMemory[0xFF40] = 0x91;
    romMemory[0xFF42] = 0x00;
    romMemory[0xFF43] = 0x00;
    romMemory[0xFF45] = 0x00;
    romMemory[0xFF47] = 0xFC;
    romMemory[0xFF48] = 0xFF;
    romMemory[0xFF49] = 0xFF;
    romMemory[0xFF4A] = 0x00;
    romMemory[0xFF4B] = 0x00;
    romMemory[0xFFFF] = 0x00;
}

#pragma mark - Read and Write Helper Methods

-(BYTE)readMemoryFromAddress:(WORD)address {
    if ((address >= 0x4000) && (address <= 0x7FFF)) {
        WORD newAddress = address - 0x4000;
        return cartMemory[newAddress + (currentRomBank * 0x4000)];
    } else if ((address >= 0xA000) && (address <= 0xBFFF)) {
        WORD newAddress = address - 0xA000;
        return ramBanks[newAddress + (currentRamBank * 0x2000)];
    } else {
        return romMemory[address];
    }
}

-(void)writeMemoryWithAddress:(WORD)address andData:(BYTE)data {
    if (0xFF04 == address) {
        romMemory[0xFF04] = 0;
    } else if (TMC == address) {
        // SKIP FOR NOW
    } else if (address < 0x8000) {
        [self handleBankingWithAddress:address andData:data];
    } else if ((address >= 0xA000) && (address < 0xC000)) {
        if (enableRam) {
            WORD newAddress = address - 0xA000;
            ramBanks[newAddress + (currentRamBank * 0x2000)] = data;
        }
    } else if ((address >= 0xE000) && (address < 0xFE00)) {
        romMemory[address] = data;
        [self writeMemoryWithAddress:address - 0x2000 andData:data];
    } else if ((address >= 0xFEA0) && (address < 0xFEFF)) {
        // restricted
    } else {
        romMemory[address] = data;
    }
}

#pragma mark - Banking

-(void)setBankType {
    switch (cartMemory[0x147]) {
        case 0: bankType = BankTypeRomOnly; break;
        case 1: bankType = BankTypeMBC1; break;
        case 2: bankType = BankTypeMBC1; break;
        case 3: bankType = BankTypeMBC1; break;
        case 5: bankType = BankTypeMBC2; break;
        case 6: bankType = BankTypeMBC2; break;
            
        default: bankType = BankTypeUnsupported;
    }
}

-(void)handleBankingWithAddress:(WORD)address andData:(BYTE)data {
    if (address < 0x2000) {
        if (bankType == BankTypeMBC1 || bankType == BankTypeMBC2) {
            [self enableRamBankIfRequiredForAddress:address withData:data];
        }
    } else if ((address >= 0x2000) && (address > 0x4000)) {
        if (bankType == BankTypeMBC1 || bankType == BankTypeMBC2) {
            [self changeLoRomBankWithData:data];
        }
    } else if ((address >= 0x4000) && (address < 0x6000)) {
        if (bankType == BankTypeMBC1) {
            [self changeHiRomBankWithData:data];
        } else {
            [self changeRamBankWithData:data];
        }
    } else if ((address >= 0x6000) && (address < 0x8000)) {
        if (bankType == BankTypeMBC1) {
            [self changeRomAndRamModeWithData:data];
        }
    }
}


-(void)enableRamBankIfRequiredForAddress:(WORD)address withData:(BYTE)data {
    if (bankType == BankTypeMBC2) {
        if (TEST_BIT(address, 4) == 1) return;
    }
    
    BYTE testData = data & 0xF;
    if (testData == 0xA) {
        enableRam = true;
    } else if (testData == 0x0) {
        enableRam = false;
    }
}

-(void)changeLoRomBankWithData:(BYTE)data {
    if (bankType == BankTypeMBC2) {
        currentRomBank = data & 0xF;
        if (currentRomBank == 0) currentRamBank++;
        return;
    }
    
    BYTE lower5 = data & 31;
    currentRomBank &= 224;
    currentRomBank |= lower5;
    if (currentRomBank == 0) currentRomBank++;
}

-(void)changeHiRomBankWithData:(BYTE)data {
    currentRomBank &= 31;
    data &= 224;
    currentRomBank |= data;
    if (currentRomBank == 0) currentRomBank++;
}

-(void)changeRamBankWithData:(BYTE)data {
    currentRamBank = data & 0x3;
}

-(void)changeRomAndRamModeWithData:(BYTE)data {
    BYTE newData = data & 0x1;
    romBanking = (newData == 0) ? true : false;
    if (romBanking) currentRamBank = 0;
}

#pragma mark - Test

-(void)displayTestWindow {
    
    SDL_Window *window;
    SDL_Renderer *renderer;
    
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        NSLog(@"Whoops!");
    } else {
        SDL_CreateWindowAndRenderer(160, 144, 0, &window, &renderer);
        SDL_SetWindowTitle(window, "GAMEBOY");
        SDL_RenderClear(renderer);
        
        SDL_SetRenderDrawColor(renderer, 0xCA, 0xDC, 0x9F, 0xFF);
        SDL_RenderClear(renderer);
        
        SDL_SetRenderDrawColor(renderer, 0x0F, 0x3A, 0x0F, 0xFF);
        
        for (int i = 0; i < 160; i++) {
            SDL_RenderDrawPoint(renderer, i, i);
        }
        
        SDL_RenderPresent(renderer);
    }
}

@end
