//
//  HeartRate.swift
//  fakeout
//
//  Created by Robert Huebner on 3/11/16.
//  Copyright © 2016 trainjam. All rights reserved.
//

import HealthKit

final class HeartRate: NSObject, HKWorkoutSessionDelegate
{
    typealias HeartRateHandler = (newHeartRate: Double) -> Void
    
    private static let PollInterval: NSTimeInterval = 1.0
    
    private var handler: HeartRateHandler?
    private var session: HKWorkoutSession?
    {
        didSet
        {
            self.session?.delegate = self
        }
    }
    
    private var continuePolling = true
    
    private var heartRates: [Double] = []
    
    var averageHeartRate: Double
    {
        return self.heartRates.reduce(0.0, combine: +) / max(Double(self.heartRates.count), 1.0)
    }
    
    let healthStore: HKHealthStore? = {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        return HKHealthStore()
    }()
    
    // MARK: -
    
    func requestPermission()
    {
        guard let healthStore = self.healthStore else {
            print("no health store")
            
            return
        }
        
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
    
    func startMonitoring(handler: HeartRateHandler)
    {
        self.handler = handler
        
        self.session = HKWorkoutSession(activityType: .Running, locationType: .Indoor)
        
        guard let session = self.session else { return }
        
        self.healthStore?.startWorkoutSession(session)
    }
    
    func endMonitoring()
    {
        self.handler = nil
        
        guard let session = self.session else { return }
        
        self.healthStore?.endWorkoutSession(session)
    }
    
    // MARK: -
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate)
    {
        switch toState
        {
        case .NotStarted:
            break
        case .Running:
            self.startPollingHeartRate()
        case .Ended:
            self.endPollingHeartRate()
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError)
    {
        print("HKWorkoutSession error: \(error)")
        
        self.endPollingHeartRate()
    }
    
    // MARK: - 
    
    private func startPollingHeartRate()
    {
        self.continuePolling = true
        
        self.scheduleNextPoll()
    }
    
    private func endPollingHeartRate()
    {
        self.continuePolling = false
    }
    
    private func scheduleNextPoll()
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(self.dynamicType.PollInterval * Double(NSEC_PER_SEC))), dispatch_get_main_queue())
        {
            guard self.continuePolling else { return }
            
            self.sendHeartRateReading()
            
            self.scheduleNextPoll()
        }
    }
    
    private func sendHeartRateReading()
    {
        guard let heartRateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { fatalError("unable to create heart rate type") }
        let device = HKDevice.localDevice()
        let datePredicate = HKQuery.predicateForSamplesWithStartDate(self.session?.startDate, endDate: self.session?.endDate ?? NSDate(), options: .None)
        let devicePredicate = HKQuery.predicateForObjectsFromDevices([device])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, devicePredicate])
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
    
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortByDate]) { (_, returnedSamples, error) -> Void in
            
            guard let samples = returnedSamples as? [HKQuantitySample] else {
                // Add proper error handling here...
                print("*** an error occurred: \(error?.localizedDescription) ***")
                return
            }
            
            let unit = HKUnit(fromString: "count/min")
            let heartRates = samples.map { $0.quantity.doubleValueForUnit(unit) }
            
            guard let heartRate = heartRates.last else
            {
                print("no heart found")
                
                return
            }
            
            self.heartRates.append(heartRate)
            
            self.handler?(newHeartRate: heartRate)
        }
        
        self.healthStore?.executeQuery(query)
    }
}
