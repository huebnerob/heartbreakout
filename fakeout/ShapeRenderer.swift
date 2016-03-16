//
//  ShapeRenderer.swift
//  fakeout
//
//  Created by Robert Huebner on 3/10/16.
//  Copyright © 2016 trainjam. All rights reserved.
//

import UIKit
import CoreGraphics

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
    static let size = CGSize(width: 78, height: 93)
    static let backgroundColor = UIColor.clearColor()
    
    var shapes: [Drawable] = []
    
    func render() -> UIImage?
    {
        UIGraphicsBeginImageContext(self.dynamicType.size)
        defer { UIGraphicsEndImageContext() }
    
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        CGContextSetFillColorWithColor(context, self.dynamicType.backgroundColor.CGColor)
        CGContextFillRect(context, CGRect(origin: .zero, size: self.dynamicType.size))
        
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