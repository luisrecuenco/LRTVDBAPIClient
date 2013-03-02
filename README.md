## LRTVDBAPIClient

LRTVDBAPIClient is a simple and efficient Objective-C wrapper for [TheTVDB](http://thetvdb.com/). 

It supports: 

* Search for shows based on a specified query.
* Retrieve a list shows for the given TVDB shows IDs.
* Retrieve a list episodes for the given TVDB episodes IDs.
* Get the correct episode for the specified season and number.
* Get all the TV Show artwork information.
* Get all the TV Show actors information.
* Update a lists of shows.
* Persist/retrieve a list of shows to/from disk.
* Support for every language TVDB is able to handle.

## Install

1. **Using CocoaPods**

  Add the following line to your Podfile:

  ```
  platform :ios, "5.1"
  pod 'LRTVDBAPIClient'   
  ```

  Run the following command:
  
  ```
  pod install
  ```

  **Important**: due to an error in zipzap podspec, zipzap library is producing errors when compiled in release mode. You can see the issue [here](https://github.com/pixelglow/zipzap/issues/25).
  As a temporal workaround, you can edit *Pods.xcconfig* file and replace:
  
  ```
  OTHER_CPLUSPLUSFLAGS = -std=gnu++11 -stdlib=libc++
  ```
  
  with
  
  ```
  CLANG_CXX_LANGUAGE_STANDARD = c++0x
  CLANG_CXX_LIBRARY = libc++
  ```

  Finally, import SystemConfiguration and MobileCoreServices frameworks to avoid AFNetworking warnings.

2. **Manually**

  Clone the project or add it as a submodule (use *--recursive* option so associated submodules are updated). 

  ```
  git clone --recursive git://github.com/luisrecuenco/LRTVDBAPIClient.git
  ```

  Drag *LRTVDBAPIClient* folder to your project and add *AFNetworking*, *TBXML* and *zipzap* projects (available in *Vendor* folder). You can see instructions on how to add them in their github pages (see credits section below).

## Configuration

You may specify your TVDB API key in the property *apiKey* in TVDBAPIClient class. 

You may also set the desired language to use (via *language* property in TVDBAPIClient). If no language is provided, the default device one will be used (or English if the latter is not supported by TheTVDB). 

## Usage

The code is divided in four main categories:

* **Model**: *LRTVDBShow*, *LRTVDBEpisode*, *LRTVDBImage* and *LRTVDBActor*.
* **Persistence Manager**: *LRTVDBPersistenceManager*.
* **Parser**: *LRTVDBAPIParser*.
* **API Client**: *LRTVDBAPIClient*.

The main class that has all the important methods to retrieve the information from TheTVDB is LRTVDBAPIClient. Let's explain further what you can do with it.

**Search for shows based on a specified query**

```objective-c
- (void)showsWithName:(NSString *)showName
      completionBlock:(void (^)(NSArray *shows, NSError *error))completionBlock;
```

The result of the method is an array of LRTVDBShow objects with some basic information provided by TheTVDB (name, ID, overview, IMDB ID, bannerURL…). In order to retrieve more detailed information, such as episodes, artwork or actors, you can use the following method.

**Retrieve a list shows for the given TVDB shows IDs**

```objective-c
- (void)showsWithIDs:(NSArray *)showsIDs
     includeEpisodes:(BOOL)includeEpisodes
       includeImages:(BOOL)includeImages
       includeActors:(BOOL)includeActors
     completionBlock:(void (^)(NSArray *shows, NSDictionary *errorsDictionary))completionBlock;
```

**Retrieve a list episodes for the given TVDB episodes IDs**

```objective-c
- (void)episodesWithIDs:(NSArray *)episodesIDs
        completionBlock:(void (^)(NSArray *episodes, NSDictionary *errorsDictionary))completionBlock;
```

*episodes* is an array of LRTVDBEpisode objects.

**Get the correct episode for the specified season and number**

```objective-c
- (void)episodeWithSeasonNumber:(NSNumber *)seasonNumber
                  episodeNumber:(NSNumber *)episodeNumber
                  forShowWithID:(NSString *)showID
                completionBlock:(void (^)(LRTVDBEpisode *episode, NSError *error))completionBlock;
```

**Get all the TV Show artwork information**

```objective-c
- (void)imagesForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *images, NSError *error))completionBlock;
```

*images* is an array of LRTVDBImage objects.

**Get all the TV Show actors information**

```objective-c
- (void)actorsForShowWithID:(NSString *)showID
            completionBlock:(void (^)(NSArray *actors, NSError *error))completionBlock;
```

*actors* is an array of LRTVDBActor objects.

**Update a lists of shows**

```objective-c
- (void)updateShows:(NSArray *)showsToUpdate
      checkIfNeeded:(BOOL)checkIfNeeded
     updateEpisodes:(BOOL)updateEpisodes
       updateImages:(BOOL)updateImages
       updateActors:(BOOL)updateActors
    completionBlock:(void (^)(BOOL finished))completionBlock;
```

*showsToUpdate* will be updated with the latest information of the shows. When all the shows have been updated, the block will be called with a boolean indicating the success of the operation. The best way to update a show without having to wait for the block to execute (i.e., waiting for every show update to finish) is to watch the desired properties via KVO.

**Persist/retrieve a list of shows to/from disk.**

```objective-c
- (void)saveShowsInPersistenceStorage:(NSArray *)shows;

- (NSArray *)showsFromPersistenceStorage;
```

## Example

The project contains a complete example of a TV Show Tracker App. You can search for shows, add them to your library, see the episodes, share on Twitter and Facebook, mark the episodes as seen… everything you would expect from an app of this kind.

## Requirements

LRTVDBAPIClient requires both iOS 5.0 and ARC.

You can still use LRTVDBAPIClient in your non-arc project. Just set -fobjc-arc compiler flag in every source file.

## Credits

LRTVDBAPIClient uses the following third party libraries:

* [AFNetworking](https://github.com/AFNetworking/AFNetworking)
* [TBXML](https://github.com/71squared/TBXML)
* [zipzap](https://github.com/pixelglow/zipzap)
* [LRImageManager](https://github.com/luisrecuenco/LRImageManager)

## Contact

LRTVDBAPIClient was created by Luis Recuenco: [@luisrecuenco](https://twitter.com/luisrecuenco).

## Contributing

If you want to contribute to the project just follow this steps:

1. Fork the repository.
2. Clone your fork to your local machine.
3. Create your feature branch.
4. Commit your changes, push to your fork and submit a pull request.

## License

LRTVDBAPIClient is available under the MIT license. See the [LICENSE file](https://github.com/luisrecuenco/LRTVDBAPIClient/blob/master/LICENSE) for more info.

