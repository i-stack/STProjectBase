// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STBase",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "STBase",
            targets: ["STBase"]
        ),
    ],
    targets: [
        .target(
            name: "STBase",
            dependencies: [],
            path: "Sources",
            sources: [
                "STAnimation",
                "STBaseModel",
                "STBaseView",
                "STBaseViewController",
                "STBaseViewModel",
                "STConfig",
                "STCore",
                "STDialog",
                "STSecurity",
                "STTabBar",
                "STUI"
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
