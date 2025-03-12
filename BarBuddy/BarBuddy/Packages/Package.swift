//
//  Package.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BarBuddyPackages",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "BarBuddyKit",
            targets: ["BarBuddyKit"]),
    ],
    dependencies: [
        // Dependencies here
    ],
    targets: [
        .target(
            name: "BarBuddyKit",
            dependencies: []),
        .testTarget(
            name: "BarBuddyKitTests",
            dependencies: ["BarBuddyKit"]),
    ]
)
