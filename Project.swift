import ProjectDescription

private let bundleId: String = "io.tuist.Project"
private let version: String = "1.0.0"
private let bundleVersion: String = "1"
private let appName: String = "Projects"

private let IOSTargetVersion: String = "13.0"

private let basePath: String = "Targets"

let project = Project(name: appName,
                      packages: [],
                      settings: Settings.settings(configurations: makeConfigurations()),
                      targets: [
                      Target(name: "MarvelHerois",
                             platform: .iOS,
                             product: .app,
                             bundleId: bundleId,
                             deploymentTarget: .iOS(targetVersion: IOSTargetVersion, devices: .iphone),
                             infoPlist: makeInfoPlist(),
                             sources: ["\(basePath)/Projects/**"],
                             resources: ["\(basePath)/Projects/**"],
                             settings: baseSettings()
                             )
                      ],
                      additionalFiles: [
                        "README.md",
                      ])

private func makeInfoPlist(merging other: [String: InfoPlist.Value] = [:]) -> InfoPlist {
    var extendedPlist: [String: InfoPlist.Value] = [
        "UIApplicationSceneManifest": ["UIApplicationSupportsMultipleScenes": true],
        "UILaunchScreen": [],
        "UISupportedInterfaceOrientations":
            [
                "UIInterfaceOrientationPortrait"
            ],
        "CFBundleShortVersionString": "\(version)",
        "CFBundleVersion": "\(bundleVersion)",
        "CFBundleDisplayName": "\(appName)",
    ]
    other.forEach { (key: String, value: InfoPlist.Value) in
        extendedPlist[key] = value
    }
    return InfoPlist.extendingDefault(with: extendedPlist)
}

private func makeConfigurations() -> [Configuration] {
    let debug: Configuration = Configuration.debug(name: "Debug", xcconfig: "Configs/Debug.xcconfig")
    let release: Configuration = Configuration.debug(name: "Release", xcconfig: "Configs/Release.xcconfig")
    return [debug, release]
}


private func baseSettings() -> Settings {
    var settings = SettingsDictionary()
    
    return Settings.settings(base: settings,
                             configurations: [],
                             defaultSettings: .recommended)
}
