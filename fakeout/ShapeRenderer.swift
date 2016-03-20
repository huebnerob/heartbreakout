//
//  ShapeRenderer.swift
//  fakeout
//
//  Created by Robert Huebner on 3/10/16.
//  Copyright © 2016 trainjam. All rights reserved.
//

import UIKit
import CoreGraphics
import WatchKit

protocol Drawable
{
    func drawInContext(context: CGContextRef)
    var stepFunction: (Drawable -> Void)? { get set }
}

extension Drawable
{
    func step()
    {
        self.stepFunction?(self)
    }
}

final class Rect: Drawable
{
    init(origin: CGPoint, size: CGSize)
    {
        self.cgRect = CGRect(origin: origin, size: size)
    }
    
    var fillColor = UIColor.orangeColor()
    
    var cgRect: CGRect
    
    func drawInContext(context: CGContextRef)
    {
//        print("drawing rect: \(self.cgRect)")
        
        CGContextSetFillColorWithColor(context, self.fillColor.CGColor)
        CGContextFillRect(context, self.cgRect)
    }
    
    var stepFunction: (Drawable -> Void)?
}

final class ShapeRenderer
{
    var size = CGSize(width: 78, height: 93)
    static let backgroundColor = UIColor.clearColor()
    
    var shapes: [Drawable] = []
    
    func render() -> UIImage?
    {
        UIGraphicsBeginImageContext(self.size)
        defer { UIGraphicsEndImageContext() }
    
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        CGContextSetFillColorWithColor(context, self.dynamicType.backgroundColor.CGColor)
        CGContextFillRect(context, CGRect(origin: .zero, size: self.size))
        
        for shape in self.shapes
        {
            shape.drawInContext(context)
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        return image
    }
    
    func step()
    {
        for shape in self.shapes
        {
            shape.stepFunction?(shape)
        }
    }
}

final class RenderStepper
{
    let renderer: ShapeRenderer
    let stepInterval: NSTimeInterval
    let imageHandler: UIImage? -> Void

    var valid = true
    
    private let queue = dispatch_queue_create("RenderStepper", DISPATCH_QUEUE_SERIAL)
    
    init(renderer: ShapeRenderer, stepInterval: NSTimeInterval, imageHandler: UIImage? -> Void)
    {
        self.renderer = renderer
        self.stepInterval = stepInterval
        self.imageHandler = imageHandler
    }
    
    func startStepping()
    {
        self.step()
    }
    
    private func scheduleNextStep()
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * self.stepInterval)), self.queue)
        {
            self.step()
        }
    }
    
    private func step()
    {
        let image = self.renderer.render()
        
        self.renderer.step()
        
        dispatch_async(dispatch_get_main_queue())
        {
//            print("calling image handler with image: \(image)")
            
            self.imageHandler(image)
        }
        
        if self.valid
        {
            self.scheduleNextStep()
        }
    }
}

extension WKInterfacePicker
{
    private static var AssumedAspectRatio: CGFloat { return 312.0 / 39.0 }
    private static var ImageWidth: CGFloat { return 390.0 }
    private static var ImageCount: Int { return 10 }
    private static var PaddleWidthRatio: CGFloat { return 0.4 }
    private static var PaddleColor: UIColor { return UIColor.blueColor() }
    
    func setUpDog()
    {
        let paddleWidth = self.dynamicType.ImageWidth * self.dynamicType.PaddleWidthRatio
        let paddleHeight = self.dynamicType.ImageWidth / self.dynamicType.AssumedAspectRatio
        let paddleSize = CGSize(width: paddleWidth, height: paddleHeight)
        let paddleY: CGFloat = 0.0
        let firstPaddleX: CGFloat = 0.0
        let firstPaddleOrigin = CGPoint(x: firstPaddleX, y: paddleY)
        
        let paddleXDelta: CGFloat = (self.dynamicType.ImageWidth - paddleWidth) / CGFloat(self.dynamicType.ImageCount - 1)
        
        let paddleRect = Rect(origin: firstPaddleOrigin, size: paddleSize)
        paddleRect.fillColor = self.dynamicType.PaddleColor
        paddleRect.stepFunction = { rect in
            guard let rect = rect as? Rect else { return }
            
            rect.cgRect.offsetInPlace(dx: paddleXDelta, dy: 0.0)
        }
        
        let renderer = ShapeRenderer()
        renderer.size = CGSize(width: self.dynamicType.ImageWidth, height: self.dynamicType.ImageWidth / self.dynamicType.AssumedAspectRatio)
        renderer.shapes.append(paddleRect)
        
        var images: [UIImage] = []
        
        for _ in 0..<self.dynamicType.ImageCount
        {
            guard let image = renderer.render() else { continue }
            
            images.append(image)
            renderer.step()
        }
        
        let items = images.map { image -> WKPickerItem in
            let item = WKPickerItem()
            item.contentImage = WKImage(image: image)
            return item
        }
        
        self.setItems(items)
    }
}

