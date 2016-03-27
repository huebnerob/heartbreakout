//
//  InterfaceController.swift
//  fakeout WatchKit Extension
//
//  Created by Robert Huebner on 3/10/16.
//  Copyright © 2016 trainjam. All rights reserved.
//

import WatchKit

final class InterfaceController: WKInterfaceController
{
    @IBOutlet private weak var mainGroup: WKInterfaceGroup!
    @IBOutlet private weak var centeredLabel: WKInterfaceLabel!
    @IBOutlet private weak var paddlePicker: WKInterfacePicker!
    
    private let heartRate = HeartRateMonitor()
    
    private var isSetup = false
    
    private var speed: CGFloat = 2.0

    override func willActivate()
    {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        guard !self.isSetup else { return }
        self.isSetup = true
        
        let renderer = ShapeRenderer()
        
        let rect = Rect(origin: CGPoint(x: 20.0, y: 25.0), size: CGSize(width: 5.0, height: 5.0))
        
        var verticalDirection: CGFloat = 1.0
        var horizontalDirection: CGFloat = 1.0
        let maxSize = renderer.size
        
        rect.stepFunction = { rect in
            guard let rect = rect as? Rect else { return }
            
            rect.cgRect.offsetInPlace(dx: self.speed * horizontalDirection, dy: self.speed * verticalDirection)
            
            if rect.cgRect.maxX > maxSize.width { horizontalDirection = -1.0 }
            else if rect.cgRect.minX < 0.0 { horizontalDirection = 1.0 }
            
            if rect.cgRect.maxY > maxSize.height { verticalDirection = -1.0 }
            else if rect.cgRect.minY < 0.0 { verticalDirection = 1.0 }
        }
        renderer.shapes.append(rect)
        
        let stepper = RenderStepper(renderer: renderer, stepInterval: 0.02) { [weak self] image in
            self?.mainGroup.setBackgroundImage(image)
        }
        
        stepper.startStepping()
        
        self.centeredLabel.setText("~.~")
        
        self.heartRate.startMonitoring { newHeartRate in
            
            if newHeartRate > self.heartRate.averageHeartRate
            {
                self.centeredLabel.setTextColor(.redColor())
                self.speed = 4.0
            }
            else if newHeartRate < self.heartRate.averageHeartRate
            {
                self.centeredLabel.setTextColor(.greenColor())
                self.speed = 1.0
            }
            else
            {
                self.centeredLabel.setTextColor(.yellowColor())
                self.speed = 2.0
            }
            
            self.centeredLabel.setText("\(Int(newHeartRate)) bpm")
        }
        
        self.heartRate.requestPermission()
        
        self.paddlePicker.setUpDog()
    }
    
    override func didDeactivate()
    {
        super.didDeactivate()
        
        self.heartRate.endMonitoring()
    }
}
