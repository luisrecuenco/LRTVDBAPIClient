// LRTVDBAPIClient+Private.h
//
// Copyright (c) 2012 Luis Recuenco
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

/** TVDB image base URL */
static NSString *const kLRTVDBAPIImageBaseURLString = @"http://www.thetvdb.com/banners/";

/**
 Provides the correct image URL based on the relative path
 provided in theTVDB XML response.
 @param path The relative path of the image.
 @return A newly-initialized NSURL object with the correct image URL.
 */
NS_INLINE NSURL *LRTVDBImageURLForPath(NSString *path)
{    
    NSString *urlString = [kLRTVDBAPIImageBaseURLString stringByAppendingPathComponent:path];
    return [NSURL URLWithString:urlString];
}

/**
 @return The default TVDB API language: English
 */
NS_INLINE NSString *LRTVDBDefaultLanguage(void)
{
    return @"en";
}