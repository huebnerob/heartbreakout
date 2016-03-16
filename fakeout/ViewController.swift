//
//  ViewController.swift
//  fakeout
//
//  Created by Robert Huebner on 3/10/16.
//  Copyright © 2016 trainjam. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let healthStore = HKHealthStore()
    
        guard let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { fatalError("unable to create heart rate type") }
        
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: [heartRateType]) { (success, error) in
            if success
            {
                print("permission granted")
            }
            else
            {
                print("permission error: \(error ?? "nil")")
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        
        
    }
}

