//
//  TripInfoMonitorView.swift
//

import SwiftUI

struct TripInfoMonitorView: View {
    @State var titleInfo: String
    @State var lastCheckedTime: String
    @State var descriptionText: String
    @State var isSnoozed: Bool = false
    @State var isPaused: Bool = false
    
    let snoozedTitle = "Trip monitoring is paused for today"
    let pausedTitle = "Trip monitoring is paused"
    let snoozedDescription = "Resume trip monitoring to see the updated status"
    let pausedDescription = "Resume trip monitoring to see the updated status"
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {

        VStack(alignment: .center, spacing: 0, content: {
            VStack{
                HStack{
                    if isPaused{
                        TextLabel("\(pausedTitle)".localized(), .bold, .title2)
                            .foregroundColor(Color.black)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    
                    else if isSnoozed{
                        TextLabel("\(snoozedTitle)".localized(), .bold, .title2)
                            .foregroundColor(Color.black)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    else{
                        TextLabel("\(titleInfo)".localized(), .bold, .title2)
                            .foregroundColor(Color.black)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }.padding(.all,10).frame(minHeight:80)
                
                HStack{
                    TextLabel("Last checked: %1".localized("\(lastCheckedTime)"))
                    Spacer()
                }.padding(.all,10)
            }.background(Color.gray.opacity(0.13)).border(Color.gray.opacity(0.13), width: 0.77)
            
            VStack{
                HStack{
                    if isPaused{
                        TextLabel("\(pausedDescription)".localized())
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical:true)
                            
                        Spacer()
                    }
                    
                    else if isSnoozed{
                        TextLabel("\(snoozedDescription)".localized())
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical:true)
                        Spacer()
                    }
                    else{
                        TextLabel("\(descriptionText)".localized())
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical:true)
                        Spacer()
                    }
                }.padding(.all,10)
                
                
                HStack{
                    if isPaused{
                        Button(action: {
                            isPaused.toggle()
                        }, label: {
                            Image(systemName: "arrowtriangle.right.fill")
                            TextLabel("Resume".localized())
                        }).roundedBorder()
                            .addAccessibility(text: AvailableAccessibilityItem.resumeButton.rawValue.localized())
                    }
                    
                    else if isSnoozed{
                        Button(action: {
                            isSnoozed.toggle()
                        }, label: {
                            Image(systemName: "arrowtriangle.right.fill")
                            TextLabel("Resume trip analysis".localized())
                        }).roundedBorder()
                            .addAccessibility(text: AvailableAccessibilityItem.unSnoozeButton.rawValue.localized())
                    }
                    else{
                        Button(action: {
                            isSnoozed.toggle()
                        }, label: {
                            Image(systemName: "pause.fill")
                            TextLabel("Pause for the rest of the day".localized())
                        }).roundedBorder()
                            .addAccessibility(text: AvailableAccessibilityItem.snoozeButton.rawValue.localized())
                        
                        Button(action: {
                            isPaused.toggle()
                        }, label: {
                            Image(systemName: "pause.fill")
                            TextLabel("Pause until resumed".localized())
                        }).roundedBorder()
                            .addAccessibility(text: AvailableAccessibilityItem.pauseUntilResumedButton.rawValue.localized())
                    }
                    
                    Spacer()
                }.padding(.top, 10).padding(.all,10)
            }.border(Color.gray.opacity(0.77), width: 0.77)
        })
    }
}

