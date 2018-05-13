//
//  DTXNSPasteboardParser.m
//  DetoxInstruments
//
//  Created by Leo Natan (Wix) on 5/12/18.
//  Copyright © 2018 Wix. All rights reserved.
//

#import "DTXNSPasteboardParser.h"

@import AppKit;

@implementation DTXNSPasteboardParser

+ (id)_instanceOfClass:(Class)cls fromPasteboardItem:(NSPasteboardItem*)item type:(NSString*)type pasteboard:(NSPasteboard*)pasteboard
{
	if(cls == NSData.class)
	{
		return [item dataForType:type];
	}
	
	NSPasteboardReadingOptions readingOptions = NSPasteboardReadingAsData;
	if([cls respondsToSelector:@selector(readingOptionsForType:pasteboard:)])
	{
		readingOptions = [cls readingOptionsForType:type pasteboard:pasteboard];
	}
	
	if(readingOptions == NSPasteboardReadingAsKeyedArchive)
	{
		return [NSKeyedUnarchiver unarchiveObjectWithData:[item dataForType:type]];
	}
	
	id postprocessed;
	
	switch(readingOptions)
	{
		case NSPasteboardReadingAsPropertyList:
			postprocessed = [item propertyListForType:type];
			break;
		case NSPasteboardReadingAsString:
			postprocessed = [item stringForType:type];
			break;
		case NSPasteboardReadingAsData:
		default:
			postprocessed = [item dataForType:type];
			break;
	}
	
	return [[cls alloc] initWithPasteboardPropertyList:postprocessed ofType:type];
}

+ (NSArray<DTXPasteboardItem*>*)pasteboardItemsFromGeneralPasteboard
{
	NSMutableArray<DTXPasteboardItem *>* items = [NSMutableArray new];
	
	[NSPasteboard.generalPasteboard.pasteboardItems enumerateObjectsUsingBlock:^(NSPasteboardItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		__block BOOL imageHandled = NO;
		__block BOOL stringHandled = NO;
		__block BOOL rtfHandled = NO;
		__block BOOL URLHandled = NO;
		__block BOOL colorHandled = NO;
		
		DTXPasteboardItem* pasteboardItem = [DTXPasteboardItem new];

		[obj.types enumerateObjectsUsingBlock:^(NSPasteboardType  _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
			if(UTTypeConformsTo(CF(type), kUTTypeImage))
			{
				if(imageHandled == YES)
				{
					return;
				}
				
				NSImage* image = [self _instanceOfClass:NSImage.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard];
				NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:[image CGImageForProposedRect:NULL context:nil hints:nil]];
				
				[pasteboardItem addType:NS(kUTTypeImage) data:[newRep representationUsingType:NSPNGFileType properties:@{}]];
				
				imageHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTF))
			{
				if(rtfHandled == YES)
				{
					return;
				}
				
				NSData* data = [self _instanceOfClass:NSData.class fromPasteboardItem:obj type:NS(kUTTypeRTF) pasteboard:NSPasteboard.generalPasteboard];
				NSAttributedString* attr = [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
				
				[pasteboardItem addType:NS(kUTTypeRTF) value:data];
				if(attr != nil && !stringHandled)
				{
					[pasteboardItem addType:NS(kUTTypeText) value:attr.string];
					stringHandled = YES;
				}
				rtfHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeRTFD))
			{
				if(rtfHandled == YES)
				{
					return;
				}
				
				NSData* data = [self _instanceOfClass:NSData.class fromPasteboardItem:obj type:NS(kUTTypeRTFD) pasteboard:NSPasteboard.generalPasteboard];
				NSAttributedString* attr = [[NSAttributedString alloc] initWithRTFD:data documentAttributes:nil];
				
				[pasteboardItem addType:NS(kUTTypeRTFD) value:data];
				if(attr != nil && !stringHandled)
				{
					[pasteboardItem addType:NS(kUTTypeText) value:attr.string];
					stringHandled = YES;
				}
				rtfHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), CF(NSPasteboardTypeString)))
			{
				if(stringHandled == YES)
				{
					return;
				}
				
				[pasteboardItem addType:NS(kUTTypeText) value:[self _instanceOfClass:NSString.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard]];
				stringHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), kUTTypeURL))
			{
				if(URLHandled == YES)
				{
					return;
				}
				
				NSURL* URL = [self _instanceOfClass:NSURL.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard];
				[pasteboardItem addType:NS(kUTTypeURL) value:URL];
				if(!stringHandled)
				{
					[pasteboardItem addType:NS(kUTTypeText) value:URL.absoluteString];
					stringHandled = YES;
				}
				URLHandled = YES;
				
				return;
			}
			
			if(UTTypeConformsTo(CF(type), CF(NSPasteboardTypeColor)))
			{
				if(colorHandled == YES)
				{
					return;
				}
				
				NSColor* color = [self _instanceOfClass:NSColor.class fromPasteboardItem:obj type:type pasteboard:NSPasteboard.generalPasteboard];
				//Translate color from system color to normal color.
				color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
				[pasteboardItem addType:DTXColorPasteboardType value:color];
				colorHandled = YES;
				
				return;
			}
		}];
		
		[items addObject:pasteboardItem];
	}];
	
	return items;
}

@end
