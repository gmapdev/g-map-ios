//
//  FareTableViewAODA.swift
//

import SwiftUI

struct FareTableViewAODA: View{
    @ObservedObject var fareTableViewModel = FareTableManager.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        
        ZStack(alignment: .center){
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.5))
            .zIndex(9990)
            .accessibilityAddTraits(.isButton)
            .addAccessibility(text: "Double tap to dismiss the Fares Table".localized())
            .accessibilityAction {
                fareTableViewModel.pubIsShowingFareTable.toggle()
                fareTableViewModel.hierarchyExpandedValue.removeAll()
            }
            .onTapGesture {
                fareTableViewModel.pubIsShowingFareTable.toggle()
                fareTableViewModel.hierarchyExpandedValue.removeAll()
            }
            VStack{
                // Title + Cancel Button
                HStack{
                    TextLabel("Fare Table".localized(), .bold , .title)
                        .foregroundStyle(Color.white)
                        .padding()
                        .addAccessibility(text: "Fare Table".localized())
                    Spacer()
                    Button {
                        fareTableViewModel.pubIsShowingFareTable = false
                        fareTableViewModel.hierarchyExpandedValue.removeAll()
                    } label: {
                        Image("cancel_icon")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(Color.white)
                            .frame(width: AccessibilityManager.shared.getFontSize() - 40, height: AccessibilityManager.shared.getFontSize() - 40)
                            .addAccessibility(text: "Close Button, Double tap to dismiss the Fares Table".localized())
                    }.padding()
                }.background(Color.java_main)
                ScrollView{
                    // Content
                    VStack(spacing:0){
                        HStack{
                            TextLabel("Type of Payment".localized(), .bold , .title2)
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .addAccessibility(text: "Type of Payment".localized())
                            Spacer()
                        }
                        DropDownViewAODA()
                        
                        let categories = fareTableViewModel.getHierarchyViewOptions()
                        let orderedCategories = fareTableViewModel.orderedCategories
                        if categories.count > 0 && orderedCategories.count > 0 {
                            ForEach (0..<orderedCategories.count) { index in
                                ForEach(Array(categories.keys), id: \.self) { key in
                                    if key == orderedCategories[index]{
                                        HierarchyItemViewAODA(title: key, amount: fareTableViewModel.getPrice(for: fareTableViewModel.selectedMediumType, fareProducts: categories[key]), subItems: fareTableViewModel.getsubItemsforKey(key: key)){ selectedCategory in
                                            fareTableViewModel.selectedCategory = RiderCategoryType(rawValue: selectedCategory)
                                        }
                                    }
                                }
                            }
                        }

                        Spacer()
                        
                        // Note with Clickable Link
                        (Text("*").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.title3.size)).foregroundColor(.black) + 
                         Text("Reduced fare").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.title3.size)).foregroundColor(.blue) +
                         Text(" applies only to seniors and disabled individuals. Youth ride free.").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.title3.size)).foregroundColor(.black))
                        .padding()
                        .addAccessibility(text: "Reduced Fare applies only to seniors and disabled individuals. Youth ride free, Double tap to open Link".localized())
                        .onTapGesture {
                            if let url = URL(string: "https://info.myorca.com/using-orca/ways-to-save/") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .background(Color.white)
            .frame(width: ScreenSize.width() - 40, height: ScreenSize.height() * 0.85)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .zIndex(9999)
        }
    }
}
struct DropDownViewAODA: View{
    @ObservedObject var fareTableViewModel = FareTableManager.shared
    @State var showOptions : Bool = false
    @State var selectedOption : FareMedium = .cash
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        VStack{
            HStack{
                Button(action: {
                    showOptions.toggle()
                    
                }, label: {
                    HStack{
                        TextLabel(selectedOption.lable().localized())
                            .font(.title3)
                            .foregroundStyle(.black)
                            .padding(.all, 10)
                        Spacer()
                        Image(showOptions ? "ic_up" : "ic_down")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: AccessibilityManager.shared.getFontSize() - 25, height: AccessibilityManager.shared.getFontSize() - 25)
                            .foregroundColor(.black)
                            .padding(.all, 10)
                    }
                })
            }.addAccessibility(text: "%1 selected, Double tap to change".localized(selectedOption.lable().localized()))
            
            if showOptions{
                let options = fareTableViewModel.getDropDownOptions()
                let orderedMediums = fareTableViewModel.orderedMediums
                if options.count > 0 && orderedMediums.count > 0{
                    ForEach (0..<orderedMediums.count) { index in
                        ForEach(0..<options.count) { i in
                            if options[i] == orderedMediums[index]{
                                DropDownItemViewAODA(option: options[i]){ option in
                                    self.selectedOption = option
                                    fareTableViewModel.selectedMediumType = option
                                    showOptions = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .border(.gray, width: 1)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

struct DropDownItemViewAODA: View{
    @ObservedObject var fareTableViewModel = FareTableManager.shared
    var option: FareMedium
    var action: ((FareMedium) -> Void)? = nil
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        VStack(spacing:0){
            Button {
                action?(option)
                fareTableViewModel.hierarchyExpandedValue.removeAll()
            } label: {
                HStack{
                    TextLabel(option.lable().localized())
                        .font(.title3)
                        .foregroundStyle(.black)
                        .padding(.leading, 10)
                        .padding(.bottom, 5)
                    Spacer()
                }
            }
            Divider()
        }.addAccessibility(text: "%1, Double tap to select".localized(option.lable().localized()))
    }
}

struct HierarchyItemViewAODA: View {
    
    @ObservedObject var fareTableViewModel = FareTableManager.shared
    @State var showSubItem: Bool = false
    var title : String
    var amount: Double
    var subItems : [FareMedium: Double]
    var action: ((String) -> Void)? = nil
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack{
            VStack(spacing:0){
                Button {
                    action?(title)
                    fareTableViewModel.hierarchyExpanded(option: title)
                    showSubItem.toggle()
                } label: {
                    VStack{
                        HStack{
                            Spacer()
                            Group{
                                Text(showSubItem ? "- " : "+ ")
                                    .font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.body.size))
                                +
                                Text(fareTableViewModel.getTitleName(title: title).localized())
                                    .font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.body.size))
                            }
                            .font(.title2)
                            .foregroundStyle(Color.black)
                            .padding(.all, 10)
                            Spacer()
                        }
                        if !showSubItem{
                            HStack{
                                Spacer()
                                TextLabel("$\(String(format: "%.2f", amount))", .bold , .title2)
                                    .foregroundStyle(Color.black)
                                    .padding(.all, 10)
                                Spacer()
                            }
                        }
                    }
                    .background(Color(hex: "#D9D9D9"))
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .addAccessibility(text: showSubItem ? "For %1, Double tap to Close".localized(fareTableViewModel.getTitleName(title: title), String(format: "%.2f", amount)) : "For %1 total amount is %2, Double tap to Expand".localized(title.capitalizingFirstLetter(), String(format: "%.2f", amount)))
                    
                }
                if showSubItem {
                    let orderedMediums = fareTableViewModel.orderedMediums
                    if orderedMediums.count > 0{
                        ForEach (0..<orderedMediums.count) { index in
                            ForEach(Array(subItems.keys), id: \.self) { key in
                                if key == orderedMediums[index]{
                                    if key == fareTableViewModel.selectedMediumType{
                                        HierarchySubItemViewAODA(showChildItems: true,subItemTitle: key.lable(), price: subItems[key] ?? 0, medium: key)
                                    }else{
                                        HierarchySubItemViewAODA(showChildItems: false,subItemTitle: key.lable(), price: subItems[key] ?? 0, medium: key)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct HierarchySubItemViewAODA: View {
    @ObservedObject var fareTableViewModel = FareTableManager.shared
    @State var showChildItems: Bool = false
    var subItemTitle : String
    var price: Double
    var medium: FareMedium
    
    var body : some View {
        VStack{
            Button {
                showChildItems.toggle()
            } label: {
                HStack{
                    Spacer()
                    VStack(spacing:0){
                        HStack{
                            Spacer()
                            Image(showChildItems ? "ic_up" : "ic_down")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: AccessibilityManager.shared.getFontSize() - 25, height: AccessibilityManager.shared.getFontSize() - 25)
                                .foregroundColor(.black)
                                .padding([.vertical, .leading], 10)
                            TextLabel(subItemTitle.localized(),.bold, .title3)
                                .foregroundStyle(Color.black)
                            Spacer()
                        }
                        HStack{
                            Spacer()
                            TextLabel("$\(String(format: "%.2f",price))",.bold, .title3)
                                .foregroundStyle(Color.black)
                                .padding(.all, 10)
                            Spacer()
                        }
                    }
                    .background(Color(hex: "#F2F2F2"))
                    .border(.black, width: 1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .frame(width: ScreenSize.width() - 60)
                }.addAccessibility(text: showChildItems ? "For %1 total amount is %2, Double tap to Close".localized(subItemTitle, String(format: "%.2f", price)) : "For %1 amount is %2, Double tap to Expand".localized(subItemTitle, String(format: "%.2f", price)))
                    .accessibilityAction {
                        showChildItems.toggle()
                    }
                
                
            }
            
            if showChildItems {
                VStack(spacing:0){
                    let orderModes = fareTableViewModel.getOrderModes()
                    let childItems = fareTableViewModel.getModeNamesAndPrices(medium: medium)
                    if childItems.count > 0 && orderModes.count > 0{
                        ForEach (0..<orderModes.count){ index in
                            ForEach (0..<childItems.count) { i in
                                if childItems[i].product.modeName == orderModes[index]{
                                    ChildItemViewAODA(product: childItems[i], isLast: index == childItems.count - 1, isTransfer: childItems[i].product.transferredAmount != nil)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ChildItemViewAODA: View {
    @ObservedObject var viewModel = FareTableManager.shared
    var product: FareProduct
    var isLast: Bool
    var isTransfer: Bool
    var verticalLineHeight: CGFloat = 255
    
    var body : some View {
        HStack(spacing: 0){
            Spacer()
            ZStack{
                // Vertical Line
                VStack{
                    Rectangle()
                        .fill(Color(hex: "#D9D9D9"))
                }
                .frame(width: 8, height: isTransfer ? viewModel.getVerticalLineHeight(isLast: isLast, totalHeight: verticalLineHeight) + 300 : viewModel.getVerticalLineHeight(isLast: isLast, totalHeight: verticalLineHeight))
                .offset(x: 15,y: isTransfer ? viewModel.getVerticalLineYvalue(isLast: isLast, totalHeight: verticalLineHeight + 300) : viewModel.getVerticalLineYvalue(isLast: isLast, totalHeight: verticalLineHeight))
                
                // Horizontal Line
                HStack{
                    Rectangle()
                        .fill(Color(hex: "#D9D9D9"))
                }
                .frame(width: 30, height: 8)
                .offset(x: 30,y: 0)
            }
            Spacer()
            HStack(spacing: 0){
                VStack(spacing: 0){
                    VStack(spacing:0){
                        HStack{
                            Spacer()
                            TextLabel(viewModel.getModeString(product: product))
                                .font(.body)
                                .padding(.all, 5)
                            Spacer()
                        }.padding(5)
                        HStack{
                            Spacer()
                            TextLabel(viewModel.getPriceString(product: product))
                                .font(.body)
                                .padding(.horizontal, 10)
                            Spacer()
                        }
                    }.addAccessibility(text: "for transit %1 amount is $%2".localized(viewModel.getModeString(product: product),viewModel.getPriceString(product: product)))
                    if isTransfer{
                        HStack{
                            TextLabel("Transfer discount of $\(String(format: "%.2f",product.product.transferredAmount ?? 0)) is applied.")
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundStyle(Color.red)
                                .padding(.bottom, 5)
                        }.addAccessibility(text: "Transfer discount of $%1 is applied.".localized(String(format: "%.2f",product.product.transferredAmount ?? 0)))
                    }
                }
                .background(Color(hex:"#F2F2F2"))
                .border(.black, width: 1)
                .padding(.trailing, 20)
                .frame(width: ScreenSize.width() - 120)
                
            }.padding(.vertical, 10)
            
        }
        .frame(height: isTransfer ? 550 : 250)
    }
}

struct FareTableViewAODA_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        FareTableView()
    }
}
