//
//  StopService.swift
//

import Combine
import UIKit

protocol StopsService {
    var service: APIServiceProtocol { get }
    
    /// Stops schedule.
    func stopSchedule(stopId:String,
                      numberOfDepartures: Int,
                      showBlockIds: Bool,
                      timeRange: TimeInterval,
                      date: Date) -> AnyPublisher<[StopViewerModel], APIError>
    
    /// Stops times.
    func stopTimes(stopId:String,
                   numberOfDepartures: Int,
                   showBlockIds: Bool,
                   timeRange: TimeInterval,
                   startTime: TimeInterval, nearbyRadius: Int) -> AnyPublisher<[StopViewerModel], APIError>
}

extension StopsService {
    /// Stops times.
    func stopTimes(stopId:String,
                   numberOfDepartures: Int = 3,
                   showBlockIds: Bool = false,
                   timeRange: TimeInterval = TimeInterval(172800),
                   startTime: TimeInterval, nearbyRadius: Int = 250) -> AnyPublisher<[StopViewerModel], APIError> {
        return service.request(with: StopEndpoint.stopTimes(stopId,
                                                            numberOfDepartures,
                                                            showBlockIds,
                                                            timeRange,
                                                            startTime, nearbyRadius).request)
            .eraseToAnyPublisher()
    }
    
    /// Stops schedule.
    func stopSchedule(stopId:String,
                      numberOfDepartures: Int = 3,
                      showBlockIds: Bool = false,
                      timeRange: TimeInterval = TimeInterval(172800),
                      date: Date) -> AnyPublisher<[StopViewerModel], APIError> {
        return service.request(with: StopEndpoint.stopSchedule(stopId,
                                                               numberOfDepartures,
                                                               showBlockIds,
                                                               timeRange,
                                                               date).request)
            .eraseToAnyPublisher()
    }
}
