//
//  FareTableManager.swift
//

import Foundation

class FareTableManager : ObservableObject{
    
    @Published var pubIsShowingFareTable = false
    @Published var pubItineraryCategorisedFares : [String : [FareProduct]]?
    @Published var pubSelectedItinerary: OTPItinerary?
    @Published var selectedMediumType : FareMedium = .cash
    @Published var selectedCategory: RiderCategoryType?
    @Published var filteredTotalCost : [String : [FareProduct]]?
  
    @Published var hierarchyExpandedValue : [String] = []
    
    var orderedCategories = [RiderCategoryType.adult.rawValue, RiderCategoryType.youth.rawValue, RiderCategoryType.senior.rawValue]
    var orderedMediums = [FareMedium.cash, FareMedium.orca, FareMedium.orca_lift]
    
    /// Shared instance to hold the value.
    static var shared: FareTableManager = {
        let instance = FareTableManager()
        return instance
    }()
    
    /// Hierarchy expanded.
    /// - Parameters:
    ///   - option: Parameter description
    func hierarchyExpanded(option: String) {
        if hierarchyExpandedValue.contains(option){
            hierarchyExpandedValue.removeAll(where: {$0 == option})
        }else{
            hierarchyExpandedValue.append(option)
        }
    }
    
    /// Get drop down options
    /// - Returns: [FareMedium]
    /// Retrieves drop down options.
    func getDropDownOptions() -> [FareMedium] {
        var mediumsSet: Set<FareMedium> = []
        
        if let calculatedCost = pubItineraryCategorisedFares {
            for fareProducts in calculatedCost.values {
                for item in fareProducts {
                    let medium = item.product.medium.name
                    mediumsSet.insert(medium)
                }
            }
        }
        return mediumsSet.map {$0}
    }
    
    /// Get hierarchy view options
    /// - Returns: [String : [FareProduct]]
    /// Retrieves hierarchy view options.
    func getHierarchyViewOptions() -> [String : [FareProduct]]{

        var filteredTotalCost: [String : [FareProduct]] = [:]
        
        if let calculatedCost = pubItineraryCategorisedFares {
            for (key, fareProducts) in calculatedCost {
                let filteredFareProducts = fareProducts.filter { $0.product.medium.name == self.selectedMediumType }
                if !filteredFareProducts.isEmpty {
                    filteredTotalCost[key] = filteredFareProducts
                }
            }
        }
        return filteredTotalCost
    }
    
    /// Get price.
    /// - Parameters:
    ///   - for: Parameter description
    ///   - fareProducts: Parameter description
    /// - Returns: Double
    func getPrice(for meduim : FareMedium, fareProducts: [FareProduct]?) -> Double {
        var total: Double = 0.0
        if let products = fareProducts{
            let filteredProducts = products.filter { $0.product.medium.name == meduim}
            for product in filteredProducts {
                if !(product.product.name == "transfer"){
                    var price = 0.0
                    if let doublePrice = Double(product.product.price.amount){
                        price = doublePrice
                    }
                    total += price
                }
            }
        }
        return total
    }
    
    /// Get order modes
    /// - Returns: [String]
    /// Retrieves order modes.
    func getOrderModes() -> [String]{
        var itineraryModes : [String] = []
        if let itinerary = pubSelectedItinerary{
            if let legs = itinerary.legs{
                for leg in legs {
                    if let route = leg.route{
                        if let shortName = route.shortName{
                            itineraryModes.append(shortName)
                        }else if let longName = route.longName{
                            itineraryModes.append(longName)
                        }
                    }
                }
            }
        }
        return itineraryModes
    }
    
    /// Getsub itemsfor key.
    /// - Parameters:
    ///   - key: Parameter description
    /// - Returns: [FareMedium: Double]
    func getsubItemsforKey(key: String) -> [FareMedium: Double]{
        var mediumPrices: [FareMedium: Double] = [:]
        if let calculatedCost = pubItineraryCategorisedFares, let subItems = calculatedCost[key] {
            for product in subItems {
                let medium = product.product.medium.name
                if !(product.product.name == "transfer"){
                    var price = 0.0
                    if let doublePrice = Double(product.product.price.amount){
                        price = doublePrice
                    }
                    if let existingPrice = mediumPrices[medium] {
                        
                        mediumPrices[medium] = existingPrice + price
                    } else {
                        mediumPrices[medium] = price
                    }
                }
            }
        }
        return mediumPrices
    }
    
    /// Get mode names and prices.
    /// - Parameters:
    ///   - medium: Parameter description
    /// - Returns: [FareProduct]
    func getModeNamesAndPrices(medium: FareMedium) -> [FareProduct]{
        var fares: [FareProduct] = []
        if let category = selectedCategory{
            let key = category.rawValue
            if let calculatedCost = pubItineraryCategorisedFares, let subItems = calculatedCost[key] {
                for i in 0..<subItems.count{
                    let productMedium = subItems[i].product.medium.name
                    if productMedium == medium {
                        fares.append(subItems[i])
                    }
                }
            }
        }
        return updateTranferAmount(fares: fares)
    }
    
    /// Update tranfer amount.
    /// - Parameters:
    ///   - fares: Parameter description
    /// - Returns: [FareProduct]
    func updateTranferAmount(fares: [FareProduct]) -> [FareProduct]{
        var transferProduct: [FareProduct] = []
        var products = fares
        transferProduct = products.filter({ $0.product.name == "transfer"})
        var remainingProducts = elementsNotInSubArray(mainArray: products, subArray: transferProduct)
        for item in transferProduct{
            let replacingItem = findSecondOccurrenceOrFirst(item.product.modeName, in: remainingProducts)
            if let replacingItem = replacingItem {
                for i in 0..<remainingProducts.count{
                    if remainingProducts[i] == replacingItem {
                        var price = 0.0
                        if let doublePrice = Double(item.product.price.amount){
                            price = doublePrice
                        }
                        remainingProducts[i].product.transferredAmount = price
                    }
                }
            }
        }
        return remainingProducts
    }
    
    /// Elements not in sub array.
    /// - Parameters:
    ///   - mainArray: [T]
    ///   - subArray: [T]
    /// - Returns: [T]
    func elementsNotInSubArray<T: Equatable>(mainArray: [T], subArray: [T]) -> [T] {
        var resultArray: [T] = []
        for element in mainArray {
            if !subArray.contains(element) {
                resultArray.append(element)
            }
        }
        return resultArray
    }
    
    /// Find second occurrence or first.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - in: Parameter description
    /// - Returns: FareProduct?
    func findSecondOccurrenceOrFirst(_ item: String, in array: [FareProduct]) -> FareProduct? {
        var firstOccurrence: FareProduct?
        var secondOccurrence: FareProduct?

        for element in array {
            if element.product.modeName == item {
                if firstOccurrence == nil {
                    firstOccurrence = element
                } else if secondOccurrence == nil {
                    secondOccurrence = element
                    break
                }
            }
        }
        return secondOccurrence ?? firstOccurrence
    }
    
    /// Get mode string.
    /// - Parameters:
    ///   - product: Parameter description
    /// - Returns: String
    func getModeString(product: FareProduct) -> String{
        return product.product.modeName
    }
    /// Get price string.
    /// - Parameters:
    ///   - product: Parameter description
    /// - Returns: String
    /// Retrieves price string.
    func getPriceString(product: FareProduct) -> String {
        let price = product.product.price.amount
        if price == "-" {
            return "-"
        } else {
            let doublePrice = Double(price)
            let returnPrice = String(format: "%.2f",doublePrice ?? 0.0)
            return "$" + returnPrice.replacingOccurrences(of: "-", with: "")
        }
    }
    
    /// Get vertical line yvalue.
    /// - Parameters:
    ///   - isLast: Parameter description
    ///   - totalHeight: Parameter description
    /// - Returns: CGFloat
    func getVerticalLineYvalue(isLast : Bool, totalHeight: CGFloat) -> CGFloat{
        return isLast ? -(((totalHeight / 2) / 2) - 4) : 0
    }
    
    /// Get vertical line height.
    /// - Parameters:
    ///   - isLast: Parameter description
    ///   - totalHeight: Parameter description
    /// - Returns: CGFloat
    func getVerticalLineHeight(isLast : Bool, totalHeight: CGFloat) -> CGFloat{
        return isLast ? totalHeight / 2 : totalHeight
    }
    /// Get title name.
    /// - Parameters:
    ///   - title: Parameter description
    /// - Returns: String
    /// Retrieves title name.
    func getTitleName(title:String) -> String{
        let riderCategory = RiderCategoryType(rawValue: title)
        if let category = riderCategory {
            return category.lable()
        }
        return title
    }
    
}

