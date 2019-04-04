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
    
    [self displayTestWindow];
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
