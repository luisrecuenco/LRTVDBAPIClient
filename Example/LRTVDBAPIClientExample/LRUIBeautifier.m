// LRUIBeautifier.m
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

#import "LRUIBeautifier.h"

static CGFloat const kCurlFactor = 5.0f;
static CGFloat const kShadowDepth = 2.0f;
static CGFloat const kShadowOpacity = 0.7f;
static CGFloat const kShadowRadius = 5.0f;
static CGFloat const kCurlShadowOffset = 7.0f;

#define SHADOW_COLOR [UIColor blackColor].CGColor

void LRApplyCurlShadowToView(UIView *view)
{
    CGSize size = view.frame.size;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.0f, 0.0f)];
    [path addLineToPoint:CGPointMake(size.width, 0.0f)];
    [path addLineToPoint:CGPointMake(size.width, size.height + kShadowDepth)];
    [path addCurveToPoint:CGPointMake(0.0f, size.height + kShadowDepth)
            controlPoint1:CGPointMake(size.width - kCurlFactor, size.height + kShadowDepth - kCurlFactor)
            controlPoint2:CGPointMake(kCurlFactor, size.height + kShadowDepth - kCurlFactor)];
    view.layer.shadowColor = SHADOW_COLOR;
    view.layer.shadowOpacity = kShadowOpacity;
    view.layer.shadowOffset = CGSizeMake(0.0f, kCurlShadowOffset);
    view.layer.shadowRadius = kShadowRadius;
    view.layer.masksToBounds = NO;
    view.layer.shadowPath = path.CGPath;
}

void LRApplyStandardShadowToView(UIView *view)
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:view.bounds];
    
    view.layer.shadowColor = SHADOW_COLOR;
    view.layer.shadowOpacity = kShadowOpacity;
    view.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    view.layer.shadowRadius = kShadowRadius;
    view.layer.masksToBounds = NO;
    view.layer.shadowPath = path.CGPath;
}
