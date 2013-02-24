// LRSwitchButton.m
//
// Copyright (c) 2013 Luis Recuenco
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LRSwitchButton.h"

@implementation LRSwitchButton

static UIColor *sFillColor;
static UIColor *sNotFillColor;

+ (void)initialize
{
    if (self == [LRSwitchButton class])
    {
        sFillColor = [UIColor colorWithRed:0.36f green:0.47f blue:0.59f alpha:1.0f];
        sNotFillColor = [UIColor colorWithRed:0.36f green:0.47f blue:0.59f alpha:0.2f];
    }
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    [self.filled ? sFillColor : sNotFillColor setFill];
    [ovalPath fill];
}

- (void)setFilled:(BOOL)filled
{
    if (_filled != filled)
    {
        _filled = filled;
        [self setNeedsDisplay];
    }
}

@end
