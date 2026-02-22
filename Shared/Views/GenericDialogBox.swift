//
//  GenericDialogBox.swift
//

import SwiftUI

class GenericDialogBoxManager: ObservableObject {
    
    @Published var pubPresentGenericDialogBox = false
    var title: String = ""
    var message: String = ""
    var primaryButtonText: String?
    var secondaryButtonText: String?
    var onConfirm: ((String)-> Void)?
    
    /// Shared.
    /// - Parameters:
    ///   - GenericDialogBoxManager: Parameter description
    public static var shared: GenericDialogBoxManager = {
        let mgr = GenericDialogBoxManager()
        return mgr
    }()
    
    /// Present.
    /// - Parameters:
    ///   - title: Parameter description
    ///   - message: Parameter description
    ///   - primaryButtonText: Parameter description
    ///   - secondaryButtonText: Parameter description
    ///   - onConfirm: Parameter description
    /// - Returns: Void)?)
    public func present(title: String, message: String, primaryButtonText: String?, secondaryButtonText: String?, onConfirm: ((String)->Void)?){
        self.title = title
        self.message = message
        self.primaryButtonText = primaryButtonText
        self.secondaryButtonText = secondaryButtonText
        self.onConfirm = onConfirm
        DispatchQueue.main.async {
            self.pubPresentGenericDialogBox = true
        }
    }
}

struct GenericDialogBox: View {
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        
        var buttonText = GenericDialogBoxManager.shared.primaryButtonText ?? ""
        if buttonText.count <= 0 {
            buttonText = GenericDialogBoxManager.shared.secondaryButtonText ?? ""
        }
        return ZStack{
            VStack{
                Spacer()
                HStack(){
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .zIndex(1)
            
            VStack{
                Spacer().frame(height: 100 + ScreenSize.safeTop())
                Spacer()
                HStack{
                    Spacer().frame(width: 50)
                    ZStack{
                        VStack{
                            Spacer()
                            HStack(){
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(Color.main)
                        .cornerRadius(10)
                        
                        VStack(alignment: .leading){
                            Spacer().frame(height:20)
                            HStack{
                                Spacer()
                                TextLabel(GenericDialogBoxManager.shared.title, .bold, .title).foregroundStyle(Color.white)
                                Spacer()
                            }
                            
                            Spacer()
                            
                            HStack{
                                Spacer().frame(width:10)
                                TextLabel(GenericDialogBoxManager.shared.message, .regular, .title2).foregroundStyle(Color.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer().frame(width:10)
                            }
                            
                            Spacer()
                            
                            HStack{
                                Spacer().frame(width:10)
                                
                                if let pButtonText = GenericDialogBoxManager.shared.primaryButtonText,
                                   let sButtonText = GenericDialogBoxManager.shared.secondaryButtonText{
                                    Button(action: {
                                        GenericDialogBoxManager.shared.onConfirm?(sButtonText)
                                        GenericDialogBoxManager.shared.pubPresentGenericDialogBox = false
                                    }, label: {
                                        HStack{
                                            Spacer()
                                            TextLabel(sButtonText, .regular, .body).foregroundColor(Color.white).padding(15)
                                            Spacer()
                                        }
                                        .background(Color.gray)
                                        .cornerRadius(5)
                                    })
                                    Spacer()
                                    Button(action: {
                                        GenericDialogBoxManager.shared.onConfirm?(pButtonText)
                                        GenericDialogBoxManager.shared.pubPresentGenericDialogBox = false
                                    }, label: {
                                        HStack{
                                            Spacer()
                                            TextLabel(pButtonText, .regular, .body).foregroundColor(Color.white).padding(15)
                                            Spacer()
                                        }
                                        .background(Color.green)
                                        .cornerRadius(5)
                                    })
                                }
                                else{
                                    Spacer()
                                    Button(action: {
                                        GenericDialogBoxManager.shared.onConfirm?(buttonText)
                                        GenericDialogBoxManager.shared.pubPresentGenericDialogBox = false
                                    }, label: {
                                        HStack{
                                            Spacer()
                                            TextLabel(buttonText, .regular, .body).foregroundColor(Color.white).padding(15)
                                            Spacer()
                                        }
                                        .frame(width:80)
                                        .background(Color.green)
                                        .cornerRadius(5)
                                    })
                                    Spacer()
                                }
                                
                                Spacer().frame(width:10)
                            }
                            Spacer().frame(height:20)
                        }
                        .background(Color.main)
                        Spacer().frame(height:20)
                    }
                    .cornerRadius(10)
                    .frame(height:ScreenSize.height() * 0.27)
                    Spacer().frame(width: 50)
                }
                
                Spacer()
                Spacer().frame(height: 100 + ScreenSize.safeBottom())
            }
            .zIndex(2)
        }
    }
}
#Preview {
    GenericDialogBox()
}
