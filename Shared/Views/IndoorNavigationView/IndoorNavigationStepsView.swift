//
//  IndoorNavigationStepsView.swift
//

import Foundation
import SwiftUI

struct IndoorNavigationStepsView: View {
    @ObservedObject var indoor = IndoorNavigationManager.shared
    @ObservedObject var jmapManager = JMapManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let frameHeight = ScreenSize.height() * 0.60
        ZStack{
            // Mask
            VStack{
                Spacer()
                HStack{
                    Spacer()
                }
            }
            .zIndex(1)
            .background(Color.black.opacity(0.7))
            
            if JMapManager.shared.pubPresentTurnbyTurnNote {
                HStack{
                    Spacer().frame(width: 10)
                    VStack{
                        Spacer().frame(height:ScreenSize.safeTop() + 15)
                        VStack(alignment:.leading){
                            HStack{
                                VStack{
                                    HStack{
                                        Text("Route Instructions").font(.system(size:24)).bold().foregroundStyle(Color.white)
                                            .padding([.leading, .top], 20)
                                        Spacer()
                                    }
                                    HStack(spacing:0){
                                        Image(systemName: "mappin.circle")
                                            .resizable()
                                            .foregroundColor(Color.white)
                                            .frame(width:22, height:22)
                                            .padding(.trailing, 5)
                                        
                                        Text("\(Int(jmapManager.totalDistance())) Feet").font(.system(size: 18)).bold().foregroundStyle(Color.white)
                                        Spacer()
                                        
                                    }.padding([.leading, .bottom], 20)
                                }
                                Spacer()
                            }
                            ScrollView{
                                ForEach(0..<JMapManager.shared.turnByTurnInstructions.count, id: \.self) { index in
                                    HStack{
                                        Image(JMapManager.shared.directionIconName(JMapManager.shared.turnByTurnInstructions[index].instruction)).renderingMode(.template).resizable().foregroundColor(Color.white).frame(width:35, height:35).padding(5)
                                        VStack(alignment:.leading){
                                            Text("\(JMapManager.shared.turnByTurnInstructions[index].instruction)").font(.system(size:20)).bold().foregroundStyle(Color.white)
                                            if index != JMapManager.shared.turnByTurnInstructions.count - 1 {
                                                Text("after \(Int( JMapManager.shared.turnByTurnInstructions[index].distance)) feet").font(.system(size:13)).foregroundStyle(Color.white)
                                            }
                                        }
                                        Spacer()
                                        if let floor = JMapManager.shared.turnByTurnInstructions[index].floor,
                                            index != JMapManager.shared.turnByTurnInstructions.count - 1 {
                                            HStack{
                                                Text(floor).font(.title3).bold().foregroundStyle(Color.white).padding(.horizontal, 5)
                                            }
                                            .padding(.horizontal, 10)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                            Spacer().frame(width: 10)
                                        }
                                    }.padding(5)
                                }
                            }
                        }
                        .background(Color.main)
                        .frame(maxHeight:frameHeight)
                        .cornerRadius(20)
                        .padding(20)
                        .overlay {
                            Button(action: {
                                JMapManager.shared.pubPresentStepsPanel = false
                                JMapManager.shared.pubPresentTurnbyTurnNote = false
                            }, label: {
                                Image(systemName: "multiply.circle")
                                    .resizable()
                                    .foregroundColor(Color.white)
                                    .frame(width:35, height:35)
                                .background(Color.main)
                                .cornerRadius(17.5)
                                .offset(
                                    x:((ScreenSize.width() - 60) / 2),
                                    y:-(frameHeight / 2)
                                )
                                
                            })
                        }
                        Spacer()
                    }
                    Spacer().frame(width: 10)
                }
                .background(Color.black.opacity(0.6))
                .onTapGesture {
                    JMapManager.shared.pubPresentStepsPanel = false
                    JMapManager.shared.pubPresentTurnbyTurnNote = false
                }
                .zIndex(5)
            }
            
        }
    }
}
