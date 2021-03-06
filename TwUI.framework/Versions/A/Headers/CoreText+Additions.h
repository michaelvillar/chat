/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#if TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#elif TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#endif

typedef enum {
	AB_CTLineRectAggregationTypeInline = 0,
	AB_CTLineRectAggregationTypeBlock,
} AB_CTLineRectAggregationType;

extern CGSize AB_CTLineGetSize(CTLineRef line);
extern CGSize AB_CTFrameGetSize(CTFrameRef frame, BOOL shouldAddOneLine);
extern CGFloat AB_CTFrameGetHeight(CTFrameRef frame);
extern CFIndex AB_CTFrameGetStringIndexForPosition(CTFrameRef frame, CGPoint p);

extern CFIndex AB_CTFrameGetIndexForBeginningOfLineWithCharIndex(CTFrameRef frame, CFIndex charIndex);
extern CFIndex AB_CTFrameGetIndexForEndingOfLineWithCharIndex(CTFrameRef frame, CFIndex charIndex);

extern void AB_CTFrameGetIndexForPositionInLine(NSString *string, CTFrameRef frame, CFIndex lineIndex, float xPosition, CFIndex *index);
extern void AB_CTFrameGetLinePositionOfIndex(NSString *string, CTFrameRef frame, int index, CFIndex *lineIndex, float *xPosition);
extern void AB_CTFrameGetRectsForRange(NSString *string, CTFrameRef frame, CFRange range, CGRect rects[], CFIndex *rectCount);
extern void AB_CTFrameGetRectsForRangeWithAggregationType(NSString *string, CTFrameRef frame, CFRange range, AB_CTLineRectAggregationType aggregationType, CGRect rects[], CFIndex *rectCount);
