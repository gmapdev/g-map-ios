//
//  BottomSlideBarView.swift
//

import SwiftUI
import Lock

enum BottomSlideBarPosition: String {
    case bottom = "Bottom"
    case middle = "Middle"
    case top = "Top"
}

class BottomSlideBarViewModel: ObservableObject {
    @Published var currentDragOffsetY: CGFloat = 0
    @Published var pubIsDraggable: Bool = true
    @Published var isSliderFullOpen: Bool = false
    @Published var pubBottomSlideBarPosition: BottomSlideBarPosition = .bottom
    var lastOffset: CGFloat = 0
    
    /// Shared.
    /// - Parameters:
    ///   - BottomSlideBarViewModel: Parameter description
    public static var shared: BottomSlideBarViewModel = {
        let mgr = BottomSlideBarViewModel()
        return mgr
    }()
}

struct BottomSlideBarView<Content: View>: View {
    @ObservedObject var envManager = EnvironmentManager.shared
    @ObservedObject var bottomSlideBarModel = BottomSlideBarViewModel.shared
    
    @GestureState private var gestureOffset: CGFloat = 0
    @State var currentOffsetY: CGFloat = 0

    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content
	var backgroundColor: Color = .main
    let enableDrag: Bool
    let enableCloseIndicator: Bool
    let isFullScreen: Bool
	let bottomSliderMinRatio = 0.15
    
    
    /// Min height:  c g float, max height:  c g float, background color:  color = .main, enable drag:  bool, is full screen:  bool, current offset y: c g float, enable close indicator:  bool, @ view builder content: ()->  content
    /// Initializes a new instance.
    /// - Parameters:
    ///   - minHeight: CGFloat
    ///   - maxHeight: CGFloat
    ///   - backgroundColor: Color = .main
    ///   - enableDrag: Bool
    ///   - isFullScreen: Bool
    ///   - currentOffsetY: CGFloat
    ///   - enableCloseIndicator: Bool
    ///   - content: (
    /// - Returns: Content)
    init(minHeight: CGFloat, maxHeight: CGFloat, backgroundColor: Color = .main, enableDrag: Bool, isFullScreen: Bool, currentOffsetY:CGFloat, enableCloseIndicator: Bool, @ViewBuilder content: ()-> Content){
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.content = content()
        self.backgroundColor = backgroundColor
        self.enableDrag = enableDrag
        self.isFullScreen = isFullScreen
        self.enableCloseIndicator = enableCloseIndicator
        /// Initializes a new instance.
        /// - Parameters:

        ///   - initialValue: currentOffsetY

        /// - Parameters:
        _currentOffsetY = State(initialValue: currentOffsetY)
    }
        
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        GeometryReader { proxy -> AnyView in
            let height = proxy.frame(in: .global).height
            return AnyView(
            ZStack{
                VStack(spacing: 0){
                    if enableDrag{
                        VStack(spacing: 0){
                            Spacer().frame(height: 15)
                            HStack{
                                Spacer()
                                indicatorView
                                    .accessibility(label: Text(TabBarMenuManager.shared.currentViewTab == .planTrip ? "Trip detail panel is at %1, double tap to slide %2".localized(bottomSlideBarModel.pubBottomSlideBarPosition.rawValue, bottomSlideBarModel.pubBottomSlideBarPosition == .top ? "down" : "up") : "Route panel is at %1, double tap to slide %2".localized(bottomSlideBarModel.pubBottomSlideBarPosition.rawValue, bottomSlideBarModel.pubBottomSlideBarPosition == .top ? "down" : "up")).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
                                    .onTapGesture(count: 2, perform: {
                                        if bottomSlideBarModel.pubBottomSlideBarPosition != .top && envManager.accessibilityEnabled{
                                            bottomSlideBarModel.pubBottomSlideBarPosition = .top
                                            currentOffsetY = -maxHeight + minHeight
                                            bottomSlideBarModel.isSliderFullOpen = true
                                        }
                                        else if envManager.accessibilityEnabled{
                                            bottomSlideBarModel.pubBottomSlideBarPosition = .bottom
                                            currentOffsetY = 0
                                            bottomSlideBarModel.isSliderFullOpen = false
                                        }
                                    })
                                    .accessibilityAction {
                                        if bottomSlideBarModel.pubBottomSlideBarPosition != .top && envManager.accessibilityEnabled{
                                            bottomSlideBarModel.pubBottomSlideBarPosition = .top
                                            currentOffsetY = -maxHeight + minHeight
                                            bottomSlideBarModel.isSliderFullOpen = true
                                        }
                                        else if envManager.accessibilityEnabled{
                                            bottomSlideBarModel.pubBottomSlideBarPosition = .bottom
                                            currentOffsetY = 0
                                            bottomSlideBarModel.isSliderFullOpen = false
                                        }
                                    }
                                Spacer()
                            }
                            Spacer().frame(height: 15)
                        }
                    }
                    if enableCloseIndicator{
                        VStack(spacing: 0){
                            Spacer().frame(height: 15)
                            HStack{
                                Spacer()
                                closeIndicator
                                    .accessibility(label: Text("Double tap to close bottom panel".localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
                                    .accessibilityAddTraits(.allowsDirectInteraction)
                                Spacer()
                            }
                        }
                    }
                    
                    self.content.frame(alignment: .bottom)

                /// Initializes a new instance.
                /// - Parameters:

                ///   - maxHeight: .infinity
                }.frame(maxHeight: .infinity, alignment: .top)
            }
                .frame(height: isFullScreen ? ScreenSize.height() - 80 : minHeight-currentOffsetY > 0 ? minHeight-currentOffsetY : minHeight, alignment: .top)
                .accessibility(identifier: "panel")
                .background(backgroundColor)
                .clipShape(RoundedCorner(radius: isFullScreen ? 0 : 15, corners: [.topLeft, .topRight]))
                .offset(y: isFullScreen ? minHeight : height - minHeight)
                .offset(y: currentOffsetY)
                .gesture(
                    DragGesture()
                        .updating($gestureOffset, body: { value, out, _ in
                            out = value.translation.height
                            onChange()
                        })
                        .onEnded({ value in
                            withAnimation {
                                offsetPanel()
                            }
                            bottomSlideBarModel.lastOffset = currentOffsetY
                            
                            DispatchQueue.main.async {
                                let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y: Helper.shared.getDeafultViewHeight(heightPosition: bottomSlideBarModel.pubBottomSlideBarPosition) ))
                                let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
                                MapManager.shared.setCenterArea(viewArea: viewArea, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width, edgeInset: edgeInsets)
                            }
                        })
                )
         )
        }
    }
    
    /// Offset panel
    /// Offset panel.
    func offsetPanel(){
        if enableDrag{
            if currentOffsetY < 0{//moving up
                if -currentOffsetY > (maxHeight - minHeight) / 2{
                    bottomSlideBarModel.pubBottomSlideBarPosition = .top
                    currentOffsetY = -maxHeight + minHeight
                    bottomSlideBarModel.isSliderFullOpen = true
                }
                else if -currentOffsetY < (maxHeight - minHeight) / 2 && -currentOffsetY > minHeight{
                    currentOffsetY = 0
                    if bottomSliderMinRatio != 0.5 {
                        currentOffsetY = -(maxHeight)/3
                    }
                    bottomSlideBarModel.pubBottomSlideBarPosition = .middle
                    bottomSlideBarModel.isSliderFullOpen = false
                }
                else if  -currentOffsetY < minHeight{
                    bottomSlideBarModel.pubBottomSlideBarPosition = .bottom
                    currentOffsetY = 0
                    bottomSlideBarModel.isSliderFullOpen = false
                }
                else {
                    bottomSlideBarModel.pubBottomSlideBarPosition = .bottom
                    currentOffsetY = 0
                    bottomSlideBarModel.isSliderFullOpen = false
                }
            }else {//moving down
                if currentOffsetY < minHeight {
                    bottomSlideBarModel.pubBottomSlideBarPosition = .bottom
                    currentOffsetY = 0
                    bottomSlideBarModel.isSliderFullOpen = false
                }
                else if currentOffsetY < (maxHeight - minHeight) / 2 && -currentOffsetY > minHeight{
                    currentOffsetY = 0
                    if bottomSliderMinRatio != 0.5 {
                        currentOffsetY = -(maxHeight)/3
                    }
                    bottomSlideBarModel.pubBottomSlideBarPosition = .middle
                    bottomSlideBarModel.isSliderFullOpen = false
                }
                else {
                    bottomSlideBarModel.pubBottomSlideBarPosition = .bottom
                    currentOffsetY = 0
                    bottomSlideBarModel.isSliderFullOpen = false
                }
            }

            bottomSlideBarModel.lastOffset = currentOffsetY
        }
    }
    
    /// On change
    /// Handles change.
    func onChange(){
        DispatchQueue.main.async{
            if enableDrag{
                currentOffsetY = gestureOffset + bottomSlideBarModel.lastOffset
            }
        }
    }
    
    /// Indicator view.
    /// - Parameters:
    ///   - some: Parameter description
    var indicatorView: some View {
        VStack {
            if AccessibilityManager.shared.pubIsLargeFontSize {
                closeIndicator
            } else {
                indicator
            }
        }
    }
    
    /// Indicator.
    /// - Parameters:
    ///   - some: Parameter description
    private var indicator: some View{
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor == Color.white ? Color.gray.opacity(0.3) : Color.white.opacity(0.3))
                .frame(width: 50, height: 6, alignment: .center)
    }
    
    /// Close indicator.
    /// - Parameters:
    ///   - some: Parameter description
    private var closeIndicator: some View{
        Button(action: {
            MapManager.shared.isMapSettings = false
        }, label: {
            Image(bottomSlideBarModel.pubBottomSlideBarPosition == .bottom  ? "ic_uparrow" : "ic_downarrow")
                .renderingMode(.template)
                .resizable()
                .foregroundColor(Color.white)
                .frame(width: 40, height: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 10, alignment: .center)
        })
    }
}
