//
//  ZPDefaultsKeys.h
//  Zippity
//
//  Created by Simon Whitaker on 15/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#ifndef Zippity_ZPDefaultsKeys_h
#define Zippity_ZPDefaultsKeys_h

#define kZPDefaultsFirstLaunchKey @"GSZippityIsFirstLaunch"
#define kZPDefaultsClearCacheKey @"GSZippityClearCacheOnNextRun"
#define kZPDefaultsShowFileExtensions @"GSZippityShowFileExtensions"
#define kZPDefaultsLastChosenCharacterEncoding @"GSZippityLastChosenCharacterEncoding"

/* Used to persist the selection of rows we were working on before leaving the app to authenticate with Dropbox */
#define kZPDefaultsDropboxUploadSelection @"GSZippityDropboxUploadSelection"

/* Used to record the file wrapper we were working on prior to authenticating with Dropbox. Only reload the previous selection if we're working on the same folder/archive when the app re-launches. */
#define kZPDefaultsDropboxUploadCurrentContainerPath @"GSZippityDropboxUploadActiveFileWrapperPath"
#endif
