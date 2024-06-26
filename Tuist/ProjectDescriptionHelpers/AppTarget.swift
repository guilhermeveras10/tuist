import Foundation
import ProjectDescription

public enum AppTarget: String, CaseIterable {
    case main
    case marvelHerosKit
}

extension AppTarget {
    public var id: String {
        rawValue
    }
    
    public var name: String {
        id.capitalizingFirstLetter
    }
    
    public var scope: AppScope {
        switch self {
        case .main:
            return .root
            
        case .marvelHerosKit:
            return .libs
        }
    }
    
    private var dependencies: [AppDependencie] {
        switch self {

        case .main:
            return [
                .target(.marvelHerosKit)
            ]
            
        case .marvelHerosKit:
            return [
                .external(.kingfisher)
            ]
        }
    }
}

extension AppTarget {
    public var target: Target {
        switch self {
        case .main:
            return mainTarget(AppSetup.appConfig)
        case .marvelHerosKit:
            return makeBaseTarget(AppSetup.appConfig)
        }
    }
    
    private func mainTarget(_ config: AppConfig) -> Target {
        Target(
            name: "Main",
            platform: .iOS,
            product: .app,
            bundleId: config.bunldePrefix + "superapp",
            deploymentTarget: .iOS(targetVersion: config.iosTargetVersion, devices: .iphone),
            
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": InfoPlist.Value(stringLiteral: config.marketingVersion),
                "CFBundleVersion": config.buildVersion,
                "UIMainStoryboardFile": "",
                "UILaunchStoryboardName": "LaunchScreen",
                "CFBundleIconName": "AppIcon",
                "CFBundleDisplayName": "TestName",
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                "UISupportedInterfaceOrientations~ipad": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown"],
                "UIUserInterfaceStyle": "Light",
            ]),
            
            sources: ["Targets/Projects/Sources/**"],
            resources: ["Targets/Projects/Resources/**"],
            dependencies: dependencies.map(\.convert),
            settings: Settings.settings(
                base:
                    SettingsDictionary()
                    .bitcodeEnabled(false)
                    .marketingVersion(config.marketingVersion)
                    .merging(["ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"])
                ,
                debug: Configuration.debug(name: .debug).settings,
                release: Configuration.release(name: .release).settings,
                defaultSettings: DefaultSettings.essential(excluding: [])
            )
        )
    }
    
    private func makeBaseTarget(_ config: AppConfig) -> Target {
        createFolderIfNeeded()
        
        let pathSource = "Targets/\(scope.folder)/\(name)/Sources"
        let pathResource = "Targets/\(scope.folder)/\(name)/Resources"
        let doesResourceFolderExist = FileManager.default.fileExists(atPath: pathResource, isDirectory: nil)
        
        return Target(
            name: name,
            platform: .iOS,
            product: .framework,
            bundleId: config.bunldePrefix + id,
            deploymentTarget: .iOS(targetVersion: config.iosTargetVersion, devices: .iphone),
            infoPlist: .extendingDefault(with: [:]),
            sources: ["\(pathSource)/**"],
            resources: doesResourceFolderExist ? ["\(pathResource)/**"] : [],
            dependencies: dependencies.map(\.convert),
            settings: Settings.settings(
                base: SettingsDictionary().bitcodeEnabled(false),
                debug: Configuration.debug(name: .debug).settings,
                release: Configuration.release(name: .release).settings,
                defaultSettings: DefaultSettings.essential(excluding: [])
            )
        )
    }
    
    private func createFolderIfNeeded() {
        let sourcesPath = "Targets/\(scope.folder)/\(name)/Sources"
        
        if !FileManager.default.fileExists(atPath: sourcesPath) {
            do {
                try FileManager.default.createDirectory(
                    atPath: sourcesPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                FileManager.default.createFile(atPath: "\(sourcesPath)/Placeholder.swift", contents: nil)
            } catch {
                print("Create dir error", error.localizedDescription)
            }
        }
    }
}
