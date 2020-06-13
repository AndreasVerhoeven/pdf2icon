#!/usr/bin/swift

//
//  pdf2icon.swift
//  pdf2icon
//
//  Created by Andreas Verhoeven on 27/01/2019.
//  Copyright © 2019 bikkelbroeders. All rights reserved.
//
import Foundation
import AppKit

guard CommandLine.arguments.count >= 3 else {
	print("Usage: \(CommandLine.arguments[0]) icon [overlay] output\n")
	exit(-1)
}

let iconPath = URL(fileURLWithPath:CommandLine.arguments[1])
var overlayPath: URL? = nil
if CommandLine.arguments.count > 3 {
	overlayPath = URL(fileURLWithPath: CommandLine.arguments[2])
}
let outputDir = URL(fileURLWithPath:CommandLine.arguments.last! + ".xcasset", isDirectory: true)
let appIconSetDir = outputDir.appendingPathComponent("AppIcon.appiconset")

guard let data = try? Data(contentsOf: iconPath), let pdf = NSPDFImageRep(data: data) else {
	print("Could not load icon\n")
	exit(-1)
}

var overlayPdf: NSPDFImageRep?
if let overlayPath = overlayPath, let data = try? Data(contentsOf: overlayPath) {
	overlayPdf = NSPDFImageRep(data: data)
}

try? FileManager.default.removeItem(at: appIconSetDir)
try? FileManager.default.createDirectory(at: appIconSetDir, withIntermediateDirectories: true)

extension CGFloat {
	var stringForUseInFileName: String {
		let intValue = Int(self)
		let roundedIntValue = Int(rounded())
		return roundedIntValue == intValue ? String(intValue) : String(format: "%.01f", self)
	}
}

struct Icon {
	enum Idiom: String, RawRepresentable {
		case iPhone
		case iPad
		case watch
		case mac
		case iOSMarketing
		case watchMarketing

		var assetCatalogValue: String {
			switch self {
				case .iPhone, .iPad, .watch, .mac: return rawValue.lowercased()
				case .iOSMarketing: return "ios-marketing"
				case .watchMarketing: return "watch-marketing"
			}
		}
	}

	enum Role: String, RawRepresentable {
		case notificationCenter
		case companionSettings
		case appLauncher
		case quickLook

		var assetCatalogValue: String {return rawValue}
	}

	enum SubType: String, RawRepresentable {
		case watch38mm
		case watch40mm
		case watch42mm
		case watch44mm

		var assetCatalogValue: String {
			switch self {
				case .watch38mm: return "38mm"
				case .watch40mm: return "40mm"
				case .watch42mm: return "42mm"
				case .watch44mm: return "44mm"
			}
		}

	}

	var idiom: Idiom
	var name: String

	var role: Role?
	var subType: SubType?

	var size: CGFloat
	var scales: [CGFloat]


	func fileName(for scale: CGFloat) -> String {
		var nameComponents = [idiom.rawValue, name]
		role.map {nameComponents.append($0.rawValue)}
		subType.map {nameComponents.append($0.rawValue)}
		nameComponents.append(size.stringForUseInFileName)

		var fileName = nameComponents.joined(separator: "-")
		if scale != 1.0 {
			fileName += "@\(scale.stringForUseInFileName)x"
		}
		fileName += ".png";
		return fileName
	}

	func assetCatalogEntry(for scale: CGFloat) -> [String: String] {
		var entry = [
			"size": "\(size.stringForUseInFileName)x\(size.stringForUseInFileName)",
			"idiom": idiom.assetCatalogValue,
			"filename": fileName(for: scale),
			"scale": "\(scale.stringForUseInFileName)x"
		]

		role.map { entry["role"] = $0.assetCatalogValue }
		subType.map { entry["subtype"] = $0.assetCatalogValue }
		return entry
	}
}

let icons = [
	// iOS
	Icon(idiom: .iPhone, name: "Notifications", 	size: 20,   scales: [2, 3]),
	Icon(idiom: .iPhone, name: "Settings", 			size: 29,   scales: [1, 2, 3]),
	Icon(idiom: .iPhone, name: "Spotlight",			size: 40,   scales: [2, 3]),
	Icon(idiom: .iPhone, name: "App-Legacy", 		size: 57,   scales: [1, 2]),
	Icon(idiom: .iPhone, name: "App",				size: 60,   scales: [2, 3]),

	// iPad
	Icon(idiom: .iPad, name: "Notifications",		size: 20,   scales: [1, 2]),
	Icon(idiom: .iPad, name: "Settings", 			size: 29,   scales: [1, 2]),
	Icon(idiom: .iPad, name: "Spotlight", 			size: 40,   scales: [1, 2]),
	Icon(idiom: .iPad, name: "Spotlight-Legacy", 	size: 50,   scales: [1, 2]),
	Icon(idiom: .iPad, name: "App-Legacy",			size: 72,   scales: [1, 2]),
	Icon(idiom: .iPad, name: "App",					size: 76,   scales: [1, 2]),
	Icon(idiom: .iPad, name: "App-12.9-inch",		size: 83.5, scales: [2]),

	// iOS AppStore
	Icon(idiom: .iOSMarketing, name: "AppStore",	size: 1024, scales: [1]),

	// AppleWatch
	Icon(idiom: .watch, name: "NotificationCenter", role: .notificationCenter, subType: .watch38mm, size: 24, scales: [2]),
	Icon(idiom: .watch, name: "NotificationCenter", role: .notificationCenter, subType: .watch42mm, size: 27.5, scales: [2]),

	Icon(idiom: .watch, name: "CompanionSettings", role: .companionSettings, size: 29, scales: [2, 3]),

	Icon(idiom: .watch, name: "HomeScreen", role: .appLauncher, subType: .watch38mm, size: 40, scales: [2]),
	Icon(idiom: .watch, name: "HomeScreen", role: .appLauncher, subType: .watch40mm, size: 44, scales: [2]),
	Icon(idiom: .watch, name: "HomeScreen", role: .appLauncher, subType: .watch44mm, size: 50, scales: [2]),

	Icon(idiom: .watch, name: "ShortLook", role: .quickLook, subType: .watch38mm, size: 86, scales: [2]),
	Icon(idiom: .watch, name: "ShortLook", role: .quickLook, subType: .watch42mm, size: 98, scales: [2]),
	Icon(idiom: .watch, name: "ShortLook", role: .quickLook, subType: .watch44mm, size: 108, scales: [2]),

	// AppleWatch AppStore
	Icon(idiom: .watchMarketing, name: "AppStore",	size: 1024, scales: [1]),

	// Mac
	Icon(idiom: .mac, name: "16pt",	  size: 16,   scales: [1, 2]),
	Icon(idiom: .mac, name: "32pt",	  size: 32,   scales: [1, 2]),
	Icon(idiom: .mac, name: "128pt",  size: 128,  scales: [1, 2]),
	Icon(idiom: .mac, name: "256pt",  size: 256,  scales: [1, 2]),
	Icon(idiom: .mac, name: "512pt",  size: 512,  scales: [1, 2]),
]

var imageEntries = Array<Dictionary<String, String>>()

for icon in icons {
	for scale in icon.scales {
		let pixelsWide = Int(round(icon.size * scale))
		let pixelsHigh = Int(round(icon.size * scale))
		guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixelsWide, pixelsHigh: pixelsHigh, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSColorSpaceName.deviceRGB, bytesPerRow: 4 * pixelsWide, bitsPerPixel: 32) else {
			print("Could not create bitmap\n")
			exit(-1)
		}


		let context = NSGraphicsContext(bitmapImageRep: bitmap)
		NSGraphicsContext.current = context

		let rect = NSRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
		pdf.draw(in: rect)
		overlayPdf?.draw(in: rect)

		guard let data = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
			print("Could not get PDF data from bitmap\n")
			exit(-1)
		}

		imageEntries.append(icon.assetCatalogEntry(for: scale))

		let fileName = icon.fileName(for: scale)
		let outputUrl = appIconSetDir.appendingPathComponent(fileName)
		do {
			try data.write(to: outputUrl)
		} catch {
			print("Could not write PNG to file: \(error)\n")
		}
	}
}

let info: [String: Any] = [
	"version": 1,
	"author": "xcode",
]

let appIconContents: [String: Any] = [
	"images": imageEntries,
	"info": info,
]

let catalogContents: [String: Any] = [
	"info": info,
]

do {
	let data = try JSONSerialization.data(withJSONObject: appIconContents, options: [.prettyPrinted])
	try data.write(to: appIconSetDir.appendingPathComponent("Contents.json"))
} catch {
	print("Could not write Contents.json to file: \(error)\n")
}

do {
	let data = try JSONSerialization.data(withJSONObject: catalogContents, options: [.prettyPrinted])
	try data.write(to: outputDir.appendingPathComponent("Contents.json"))
} catch {
	print("Could not write Contents.json to file: \(error)\n")
}
