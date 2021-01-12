//Copyright (c) 2021 pikachu987 <pikachu77769@gmail.com>
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

import Foundation
import UIKit

public struct AppVersion {
    public var bundleId: String = ""
    public var lookupURLPath: String = ""
    public var downloadURLPath: String = ""
    public var currentVersion: String = ""
    public var storeVersion: String = ""
    public var isUpdate: Bool = false
    public var depth: Int = -1
    public var error: Error?
}

public class AppStore: NSObject {
    public static func versionCheck(_ identifier: String? = nil, handler: @escaping (AppVersion) -> Void) {
        let currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let bundleIdentifierValue = identifier ?? Bundle.main.bundleIdentifier

        var appVersion = AppVersion()
        appVersion.storeVersion = currentVersion
        appVersion.currentVersion = currentVersion

        guard let bundleIdentifier = bundleIdentifierValue else {
            handler(appVersion)
            return
        }

        appVersion.bundleId = bundleIdentifier
        let lookupURLPath = "http://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)&t=\(Date().timeIntervalSince1970)"
        appVersion.lookupURLPath = lookupURLPath

        guard let url = NSURL(string: lookupURLPath) else {
            handler(appVersion)
            return
        }

        enum UpdateType {
            case none, update, noneUpdate
        }

        var updateType: UpdateType = .none
        let task = URLSession.shared.dataTask(with: url as URL) {(data, response, error) in
            do {
                guard
                    let json = data,
                    let dict = try JSONSerialization.jsonObject(with: json, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary,
                    let results :NSArray = dict["results"] as? NSArray, results.count != 0,
                    let dic = results[0] as? NSDictionary,
                    let trackViewUrl = dic["trackViewUrl"] as? String,
                    let version = dic["version"] as? String else {
                        handler(appVersion)
                        return
                }

                appVersion.downloadURLPath = trackViewUrl

                if currentVersion != version {
                    let versionArr = version.components(separatedBy: ".")
                    let currentVersionArr = currentVersion.components(separatedBy: ".")
                    let componentCnt = versionArr.count < currentVersionArr.count ? versionArr.count: currentVersionArr.count
                    for index in 0 ..< componentCnt {
                        if let av = Int(versionArr[index]), let cv = Int(currentVersionArr[index]) {
                            if av > cv {
                                updateType = .update
                                break
                            } else if av < cv {
                                updateType = .noneUpdate
                                break
                            }
                        }
                    }
                    if updateType == .none {
                        updateType = versionArr.count > currentVersionArr.count ? .update : .noneUpdate
                    }
                } else {
                    updateType = .noneUpdate
                }
                if updateType == .update {
                    // update
                    appVersion.storeVersion = version
                    appVersion.isUpdate = true

                    // depth
                    let currentComponent = appVersion.currentVersion.components(separatedBy: ".")
                    let storeComponent = appVersion.storeVersion.components(separatedBy: ".")
                    let componentsCnt = currentComponent.count
                    if componentsCnt != storeComponent.count {
                        appVersion.depth = 0
                    } else {
                        for element in 0..<componentsCnt {
                            if currentComponent[element] < storeComponent[element]{
                                appVersion.depth = element
                                break
                            }
                        }
                    }

                    handler(appVersion)
                } else {
                    // non update
                    handler(appVersion)
                }
            } catch let error {
                appVersion.error = error
                handler(appVersion)
            }
        }
        task.resume()
    }
}

