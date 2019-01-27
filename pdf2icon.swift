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
	print("Usage: \(CommandLine.arguments[0]) icon outputdir\n")
	exit(-1)
}

let iconPath = URL(fileURLWithPath:CommandLine.arguments[1])
let outputDir = URL(fileURLWithPath:CommandLine.arguments[2], isDirectory: true)

guard let data = try? Data(contentsOf: iconPath), let pdf = NSPDFImageRep(data: data) else {
	print("Could not load icon\n")
	exit(-1)
}

try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let outputSizes:[(String, CGFloat, [CGFloat])] = [
	// (name, point size of the icon, [scales])
	("iPhone-Notification", 20, [2, 3]),
	("iPhone-Settings", 29, [2, 3]),
	("iPhone-Spotlight", 40, [2, 3]),
	("iPhone-App", 60, [2, 3]),
	("iPhone-App", 60, [2, 3]),
	("iPad-Notifications", 20, [1, 2]),
	("iPad-Settings", 29, [1, 2]),
	("iPad-Spotlight", 40, [1, 2]),
	("iPad-App", 76, [1, 2]),
	("iPad-Pro(12.9inch)", 83.5, [2]),
	("App Store", 1024, [1]),
]

for (name, dimensions, scales) in outputSizes {
	for scale in scales {
		let pixelsWide = Int(round(dimensions * scale))
		let pixelsHigh = Int(round(dimensions * scale))
		guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixelsWide, pixelsHigh: pixelsHigh, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSColorSpaceName.deviceRGB, bytesPerRow: 4 * pixelsWide, bitsPerPixel: 32) else {
			print("Could not create bitmap\n")
			exit(-1)
		}
		
		
		let context = NSGraphicsContext(bitmapImageRep: bitmap)
		NSGraphicsContext.current = context
		pdf.draw(in: NSRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh))
		
		guard let data = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
			print("Could not get PDF data from bitmap\n")
			exit(-1)
		}
		
		let dimensionString = Int(round(dimensions)) == Int(dimensions) ? String(Int(dimensions)) : String(format: "%.01f", dimensions)
		
		let fileName = "\(name)@\(Int(scale))x-\(dimensionString).png"
		let outputUrl = outputDir.appendingPathComponent(fileName)
		do {
			try data.write(to: outputUrl)
		} catch {
			print("Could not write PNG to file: \(error)\n")
		}
	}
}
