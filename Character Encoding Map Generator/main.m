//
//  main.m
//  Character Encoding Map Generator
//
//  Created by Simon Whitaker on 10/06/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kKeyName @"name"
#define kKeyEncoding @"encoding"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSStringEncoding encodings[] = {
            // Values from NSString.h
            NSASCIIStringEncoding,
            NSISO2022JPStringEncoding,
            NSISOLatin1StringEncoding,
            NSISOLatin2StringEncoding,
            NSJapaneseEUCStringEncoding,
            NSMacOSRomanStringEncoding,
            NSNEXTSTEPStringEncoding,
            NSNonLossyASCIIStringEncoding,
            NSShiftJISStringEncoding,
            NSSymbolStringEncoding,
            NSUnicodeStringEncoding,
            NSUTF16BigEndianStringEncoding,
            NSUTF16LittleEndianStringEncoding,
            NSUTF32BigEndianStringEncoding,
            NSUTF32LittleEndianStringEncoding,
            NSUTF32StringEncoding,
            NSUTF8StringEncoding,
            NSWindowsCP1250StringEncoding,
            NSWindowsCP1251StringEncoding,
            NSWindowsCP1252StringEncoding,
            NSWindowsCP1253StringEncoding,
            NSWindowsCP1254StringEncoding,
            
            // Values from CFStringEncodingExt.h
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingANSEL),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingASCII),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5_E),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5_HKSCS_1999),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingCNS_11643_92_P1),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingCNS_11643_92_P2),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingCNS_11643_92_P3),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSArabic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSBalticRim),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSCanadianFrench),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseSimplif),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseTrad),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSCyrillic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSGreek),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSGreek1),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSGreek2),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSHebrew),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSIcelandic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSKorean),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSLatin1),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSLatin2),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSLatinUS),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSNordic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSPortuguese),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSRussian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSThai),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSTurkish),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEBCDIC_CP037),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEBCDIC_US),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_CN),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_KR),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_TW),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGBK_95),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_2312_80),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingHZ_GB_2312),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin1),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin10),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin2),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin3),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin4),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin5),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin6),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin7),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin8),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatin9),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinArabic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinCyrillic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinGreek),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinHebrew),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISOLatinThai),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_CN),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_CN_EXT),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP_1),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP_2),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_JP_3),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_KR),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingJIS_C6226_78),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingJIS_X0201_76),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingJIS_X0208_83),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingJIS_X0208_90),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingJIS_X0212_90),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_R),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKOI8_U),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKSC_5601_87),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingKSC_5601_92_Johab),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacArabic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacArmenian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacBengali),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacBurmese),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacCeltic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacCentralEurRoman),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacChineseSimp),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacChineseTrad),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacCroatian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacCyrillic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacDevanagari),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacDingbats),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacEthiopic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacExtArabic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacFarsi),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacGaelic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacGeorgian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacGreek),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacGujarati),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacGurmukhi),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacHebrew),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacHFS),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacIcelandic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacInuit),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacJapanese),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKannada),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKhmer),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacKorean),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacLaotian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacMalayalam),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacMongolian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacOriya),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacRoman),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacRomanian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacRomanLatin1),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacSinhalese),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacSymbol),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacTamil),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacTelugu),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacThai),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacTibetan),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacTurkish),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacUkrainian),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacVietnamese),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacVT100),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingNextStepJapanese),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingNextStepLatin),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS_X0213_MenKuTen),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF7),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF7_IMAP),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingVISCII),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsArabic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsBalticRim),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsCyrillic),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsGreek),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsHebrew),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsKoreanJohab),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsLatin1),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsLatin2),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsLatin5),
            CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingWindowsVietnamese)
        };
        unsigned int numEncodings = sizeof(encodings) / sizeof(encodings[0]);
        NSMutableArray * array = [NSMutableArray arrayWithCapacity:numEncodings];
        
        for (unsigned int i = 0; i < numEncodings; i++) {
            NSStringEncoding encoding = encodings[i];
            NSString * name = [NSString localizedNameOfStringEncoding:encoding];
            
            if (name && [name length] > 0) {
                NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       name, kKeyName,
                                       [NSNumber numberWithUnsignedLong:encoding], kKeyEncoding,
                                       nil];
                [array addObject:dict];
            } else {
                NSLog(@"[WARN] No name for encoding %lu", encoding);
            }
        }
        [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSString*)[obj1 valueForKey:kKeyName] compare:(NSString*)[obj2 valueForKey:kKeyName]];
        }];
        
        for (NSDictionary * dict in array) {
            NSLog(@"%@ [%lu]", [dict objectForKey:kKeyName], [[dict objectForKey:kKeyEncoding] unsignedLongValue]);
        }
        NSString * thisFilePath = [NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding];
        NSString * outputPath = [[[[thisFilePath 
                                    stringByDeletingLastPathComponent] 
                                   stringByDeletingLastPathComponent] 
                                  stringByAppendingPathComponent:@"Zippity"] 
                                 stringByAppendingPathComponent:@"character-encodings.plist"];
        NSLog(@"Writing to %@", outputPath);
        
        [array writeToFile:outputPath atomically:YES];
    }
    return 0;
}

