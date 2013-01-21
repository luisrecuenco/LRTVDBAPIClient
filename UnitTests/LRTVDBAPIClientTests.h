// LRTVDBAPIClientTests.h
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

#import <SenTestingKit/SenTestingKit.h>

@interface LRTVDBAPIClientTests : SenTestCase

/** Search shows tests */
- (void)testShowsWithNameNoResults;
- (void)testShowsWithNameEmptyQuery;
- (void)testShowsWithNameNullQuery;
- (void)testShowsWithNameNotEnglishShow;
- (void)testShowsWithNameCorrectLanguage;
- (void)testShowsWithNameRemoveDuplicates;
- (void)testShowsWithNameBasicProperties;

/** Shows with IDs tests */
- (void)testShowsWithIDsNullID;
- (void)testShowsWithIDsEmptyIDs;
- (void)testShowsWithIDsSameIDsSameOrder;
- (void)testShowsWithIDsWrongShowID;
- (void)testShowsWithIDsFullInformation;
- (void)testShowsWithIDsCheckRelationships;
- (void)testShowsWithIDsCheckSpecialEpisodes;
- (void)testShowsWithIDsCheckRelationshipsProperties;
- (void)testShowsWithIDsCorrectLanguage;
- (void)testShowsWithIDsShowWeakReference;

/** Episodes With IDs tests */
- (void)testEpisodesWithIDsNullID;
- (void)testEpisodesWithIDsEmptyIDs;
- (void)testEpisodesWithIDsSameIDsSameOrder;
- (void)testEpisodesWithIDsWrongEpisodeID;
- (void)testEpisodesWithIDsFullInformation;
- (void)testEpisodesWithIDsCorrectLanguage;

/** Episodes with season number and episode number tests */
- (void)testEpisodeWithSeasonNumberSameSeasonAndNumber;
- (void)testEpisodeWithSeasonNumberWrongShowID;
- (void)testEpisodeWithSeasonNumberWrongSeasonNumber;

/** Images for showID tests */
- (void)testImagesForShowBasicChecks;
- (void)testImagesForShowWrongShowID;

/** Actors for showID tests */
- (void)testActorsForShowBasicChecks;
- (void)testActorsForShowWrongShowID;

/** Update Shows tests */
- (void)testUpdateShowsBasicChecks;
- (void)testUpdateShowsLanguage;
- (void)testUpdateShowsKVO;

/** Update Episodes tests */
- (void)testUpdateEpisodeBasicChecks;

@end