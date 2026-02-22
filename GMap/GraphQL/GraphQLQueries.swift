//
//  GraphQLQueries.swift
//


import Foundation
// MARK: - This Class will hold all the GraphQL Queries for ITS/GMap
class GraphQLQueries{
    
    static let shared : GraphQLQueries = {
        let mgr = GraphQLQueries()
        return mgr
    }()
    
    var tripPlan : String {
        get{
              return   """
                query Plan($arriveBy: Boolean, $banned: InputBanned, $bikeReluctance: Float, $carReluctance: Float, $date: String, $fromPlace: String!, $mobilityProfile: String, $modes: [TransportMode], $numItineraries: Int, $preferred: InputPreferred, $time: String, $toPlace: String!, $unpreferred: InputUnpreferred, $walkReluctance: Float, $walkSpeed: Float, $wheelchair: Boolean) {
                  plan(
                    arriveBy: $arriveBy
                    banned: $banned
                    bikeReluctance: $bikeReluctance
                    carReluctance: $carReluctance
                    date: $date
                    fromPlace: $fromPlace
                    locale: "en"
                    mobilityProfile: $mobilityProfile
                    numItineraries: $numItineraries
                    preferred: $preferred
                    time: $time
                    toPlace: $toPlace
                    transportModes: $modes
                    unpreferred: $unpreferred
                    walkReluctance: $walkReluctance
                    walkSpeed: $walkSpeed
                    wheelchair: $wheelchair
                  ) {
                    itineraries {
                      accessibilityScore
                      duration
                      endTime
                      legs {
                        accessibilityScore
                        agency {
                          alerts {
                            alertDescriptionText
                            alertHeaderText
                            alertUrl
                            effectiveStartDate
                            id
                          }
                          gtfsId
                          id: gtfsId
                          name
                          timezone
                          url
                        }
                        alerts {
                          alertDescriptionText
                          alertHeaderText
                          alertUrl
                          effectiveStartDate
                          id
                        }
                        arrivalDelay
                        departureDelay
                        distance
                        dropOffBookingInfo {
                          contactInfo {
                            bookingUrl
                            infoUrl
                            phoneNumber
                          }
                          earliestBookingTime {
                            daysPrior
                            time
                          }
                          latestBookingTime {
                            daysPrior
                            time
                          }
                          message
                        }
                        dropoffType
                        duration
                        endTime
                        fareProducts {
                          id
                          product {
                            __typename
                            id
                            medium {
                              id
                              name
                            }
                            name
                            riderCategory {
                              id
                              name
                            }
                            ... on DefaultFareProduct {
                              price {
                                amount
                                currency {
                                  code
                                  digits
                                }
                              }
                            }
                          }
                        }
                        from {
                          lat
                          lon
                          name
                          rentalVehicle {
                            id
                            network
                          }
                          stop {
                            alerts {
                              alertDescriptionText
                              alertHeaderText
                              alertUrl
                              effectiveStartDate
                              id
                            }
                            code
                            gtfsId
                            id
                            lat
                            lon
                          }
                          vertexType
                        }
                        headsign
                        interlineWithPreviousLeg
                        intermediateStops {
                          lat
                          locationType
                          lon
                          name
                          stopCode: code
                          stopId: id
                        }
                        legGeometry {
                          length
                          points
                        }
                        mode
                        pickupBookingInfo {
                          contactInfo {
                            bookingUrl
                            infoUrl
                            phoneNumber
                          }
                          earliestBookingTime {
                            daysPrior
                            time
                          }
                          latestBookingTime {
                            daysPrior
                            time
                          }
                          message
                        }
                        pickupType
                        realTime
                        realtimeState
                        rentedBike
                        rideHailingEstimate {
                          arrival
                          maxPrice {
                            amount
                            currency {
                              code
                            }
                          }
                          minPrice {
                            amount
                            currency {
                              code
                            }
                          }
                          provider {
                            id
                          }
                        }
                        route {
                          alerts {
                            alertDescriptionText
                            alertHeaderText
                            alertUrl
                            effectiveStartDate
                            id
                          }
                          color
                          gtfsId
                          id: gtfsId
                          longName
                          shortName
                          textColor
                          type
                        }
                        startTime
                        steps {
                          absoluteDirection
                          alerts {
                            alertDescriptionText
                            alertHeaderText
                            alertUrl
                            effectiveStartDate
                            id
                          }
                          area
                          distance
                          elevationProfile {
                            distance
                            elevation
                          }
                          lat
                          lon
                          relativeDirection
                          stayOn
                          streetName
                        }
                        to {
                          lat
                          lon
                          name
                          rentalVehicle {
                            id
                            network
                          }
                          stop {
                            alerts {
                              alertDescriptionText
                              alertHeaderText
                              alertUrl
                              effectiveStartDate
                              id
                            }
                            code
                            gtfsId
                            id
                            lat
                            lon
                          }
                          vertexType
                        }
                        transitLeg
                        trip {
                          arrivalStoptime {
                            stop {
                              gtfsId
                              id
                            }
                            stopPosition
                          }
                          departureStoptime {
                            stop {
                              gtfsId
                              id
                            }
                            stopPosition
                          }
                          gtfsId
                          id
                        }
                      }
                      startTime
                      transfers: numberOfTransfers
                      waitingTime
                      walkTime
                    }
                    routingErrors {
                      code
                      description
                      inputField
                    }
                  }
                }
                """
        }
    }
    
    var routeInfo: String {
        get{
                 return  #"""
                  query RouteInfo($routeId: String!) {
                    route(id: $routeId) {
                      __typename
                      id: gtfsId
                      desc
                      agency {
                        __typename
                        id: gtfsId
                        name
                        url
                        timezone
                        lang
                        phone
                      }
                      longName
                      shortName
                      mode
                      type
                      color
                      textColor
                      bikesAllowed
                      routeBikesAllowed: bikesAllowed
                      url
                      patterns {
                        __typename
                        id
                        headsign
                        name
                        patternGeometry {
                          __typename
                          points
                          length
                        }
                        stops {
                          __typename
                          code
                          id: gtfsId
                          lat
                          lon
                          name
                          locationType
                          routes {
                            __typename
                            textColor
                            color
                          }
                        }
                      }
                    }
                  }
                  """#
        }
    }
    
    var routeList: String{
        get{
                  #"""
                  query RoutesList {
                    routes {
                      __typename
                      id: gtfsId
                      agency {
                        __typename
                        id: gtfsId
                        name
                        url
                        timezone
                        lang
                        phone
                        fareUrl
                      }
                      bikesAllowed
                      color
                      longName
                      mode
                      routeBikesAllowed: bikesAllowed
                      shortName
                      sortOrder
                      textColor
                      type
                      url
                      desc
                    }
                  }
                  """#
        }
    }
    
    var graphQLStopTimes: String{
        get{
          #"""
              query StopTimes($stopId: String!) {
                stop(id: $stopId) {
                  name
                  lat
                  lon
                  code
                  id: gtfsId
                  stoptimesForPatterns(numberOfDepartures: 3) {
                    pattern {
                      headsign
                      desc: name
                      route {
                        routeId: gtfsId
                        agency {
                          name
                          id: gtfsId
                        }
                        shortName
                        type
                        mode
                        longName
                        color
                        textColor
                      }
                    }
                    times: stoptimes {
                      serviceDay
                      departureDelay
                      realtimeState
                      realtimeDeparture
                      scheduledDeparture
                      headsign
                      trip {
                        id: gtfsId
                        route {
                          shortName
                        }
                      }
                    }
                  }
              }
          }
          """#
        }
    }
    
    var graphQLStopSchedules: String{
        get{
                  #"""
                  query StopTimes(
                            $serviceDay: Long!
                            $stopId: String!
                          ) {
                              stop(id: $stopId) {
                                gtfsId
                                code
                                lat
                                lon
                                locationType
                                name
                                wheelchairBoarding
                                routes {
                                  id: gtfsId
                                  agency {
                                    gtfsId
                                    name
                                  }
                                  longName
                                  mode
                                  color
                                  textColor
                                  shortName
                                  patterns {
                                    id
                                    headsign
                                  }
                                }
                               stoptimesForPatterns(numberOfDepartures: 1000, startTime: $serviceDay, omitNonPickups: true, omitCanceled: false) {
                                  pattern {
                                    desc: name
                                    headsign
                                    id: code
                                    route {
                                    routeId: gtfsId
                                    shortName
                                    type
                                    mode
                                    longName
                                    color
                                    textColor
                                      agency {
                                         name
                                         id: gtfsId
                                      }
                                    }
                                    stops {
                                      id: gtfsId
                                    }
                                  }
                                  times: stoptimes {
                                    __typename
                                    arrivalDelay
                                    departureDelay
                                    headsign
                                    realtime
                                    realtimeArrival
                                    realtimeDeparture
                                    realtimeState
                                    scheduledArrival
                                    scheduledDeparture
                                    serviceDay
                                    stop {
                                      __typename
                                      id: gtfsId
                                    }
                                    timepoint
                                    trip {
                                      __typename
                                      id
                                    }
                                  }
                                }
                              }
                            }
                  """#
        }
    }
    
    var shorterStopTimesQueryForOperators: String{
        get{
                  #"""
                  query StopTimes(
                            $stopId: String!
                          ) {
                              stop(id: $stopId) {
                                gtfsId
                                code
                                routes {
                                  id: gtfsId
                                  agency {
                                    gtfsId
                                    name
                                  }
                                  patterns {
                                    id
                                    headsign
                                  }
                                }
                                stoptimesForPatterns(numberOfDepartures: 100, omitNonPickups: true, omitCanceled: false) {
                                  pattern {
                                    desc: name
                                    headsign
                                    id: code
                                    route {
                                      agency {
                                        gtfsId
                                        name
                                      }
                                      gtfsId
                                    }
                                  }
                                }
                              }
                            }
                  """#
        }
    }

    var vehiclePosition: String{
        get{
                  #"""
                  query VehiclePosition($routeId: String!) {
                    route(id: $routeId) {
                      __typename
                      patterns {
                        __typename
                        id
                        vehiclePositions {
                          __typename
                          vehicleId
                          label
                          lat
                          lon
                          stopRelationship {
                            __typename
                            status
                            stop {
                              __typename
                              name
                              gtfsId
                            }
                          }
                          speed
                          heading
                          lastUpdated
                        }
                      }
                    }
                  }
                  """#
        }
    }
    
    var sharedVehicleLocations: String {
        get{
                      #"""
                     query rentalVehicle {
                       rentalVehicles {
                         id
                         vehicleId
                         name
                         allowPickupNow
                         network
                         lon
                         lat
                         rentalUris{
                           ios
                           android
                           web
                         }
                         operative
                         vehicleType{
                           formFactor
                           propulsionType
                         }
                       }
                     }
                     """#
        }
    }
    
    var mapStops: String {
        get{
          #"""
         query mapStops {
           stops {
            id: gtfsId
            code
            lat
            lon
            name
            stoptimesWithoutPatterns {
                serviceDay
            }
         }
         }
         """#
        }
    }
    
    var feedsQuery: String {
        get{
            #"""
            query FeedsQuery {
              feeds {
                feedId
                publisher {
                  name
                }
              }
            }
            """#
        }
    }

    
}

