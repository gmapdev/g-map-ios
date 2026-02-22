//
//  Flow.swift
//

import Foundation
import SwiftUI

public struct HFlow<Content>: View
where Content : View
{
    public var body: Flow<Content>
}


public extension HFlow {
    /// A view that arranges its children in a horizontal flow.
    /// This view returns a flexible preferred height to its parent layout.
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of
    ///     subviews.
    ///   - content: A view builder that creates the content of this flow.
    init(alignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.body = Flow(.horizontal,
                         alignment: Alignment(horizontal: .leading, vertical: alignment),
                         spacing: spacing,
                         content: content)
    }
    
    /// A view that arranges its children in a horizontal flow.
    /// This view returns a flexible preferred height to its parent layout.
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same vertical screen coordinate for every child view.
    ///   - horizontalSpacing: The distance between horizontally adjacent
    ///     subviews, or `nil` if you want the flow to choose a default distance
    ///     for each pair of subviews.
    ///   - verticalSpacing: The distance between vertically adjacent
    ///   - content: A view builder that creates the content of this flow.
    init(alignment: VerticalAlignment = .center,
         horizontalSpacing: CGFloat? = nil,
         verticalSpacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.body = Flow(.horizontal,
                         alignment: Alignment(horizontal: .leading, vertical: alignment),
                         horizontalSpacing: horizontalSpacing,
                         verticalSpacing: verticalSpacing,
                         content: content)
    }
}

public struct Flow<Content>: View
where Content : View
{
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: alignment) {
                Color.clear
                    .hidden()
                
                FlowLayout(alignment: alignment,
                           axis: axis,
                           content: content,
                           horizontalSpacing: horizontalSpacing ?? 8,
                           size: geometry.size,
                           verticalSpacing: verticalSpacing ?? 8)
                .transaction {
                    updateTransaction($0)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear { contentSize = geometry.size }
                            .onChange(of: geometry.size) { newValue in
                                DispatchQueue.main.async {
                                    withTransaction(transaction) {
                                        contentSize = newValue
                                    }
                                }
                            }
                    }
                    .hidden()
                )
            }
        }
        .frame(width: axis == .horizontal ? contentSize.width : nil,
               height: axis == .vertical ? contentSize.height : nil)
    }
    
    @State private var contentSize = CGSize.zero
    @State private var transaction = Transaction()
    
    private var alignment: Alignment
    private var axis: Axis
    private var content: () -> Content
    private var horizontalSpacing: CGFloat?
    private var verticalSpacing: CGFloat?
}


public extension Flow {
    /// A view that arranges its children in a flow.
    /// This view returns a flexible preferred size, orthogonal to the layout axis, to its parent layout.
    /// - Parameters:
    ///   - axis: The layout axis of this flow.
    ///   - alignment: The guide for aligning the subviews in this flow on both
    ///     the x- and y-axes.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of
    ///     subviews.
    ///   - content: A view builder that creates the content of this flow.
    init(_ axis: Axis,
         alignment: Alignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.alignment = alignment
        self.axis = axis
        self.content = content
        self.horizontalSpacing = spacing
        self.verticalSpacing = spacing
    }
    
    /// A view that arranges its children in a flow.
    /// This view returns a flexible preferred size, orthogonal to the layout axis, to its parent layout.
    /// - Parameters:
    ///   - axis: The layout axis of this flow.
    ///   - alignment: The guide for aligning the subviews in this flow on both
    ///     the x- and y-axes.
    ///   - horizontalSpacing: The distance between horizontally adjacent
    ///     subviews, or `nil` if you want the flow to choose a default distance
    ///     for each pair of subviews.
    ///   - verticalSpacing: The distance between vertically adjacent
    ///   - content: A view builder that creates the content of this flow.
    init(_ axis: Axis,
         alignment: Alignment = .center,
         horizontalSpacing: CGFloat? = nil,
         verticalSpacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.alignment = alignment
        self.axis = axis
        self.content = content
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
}


private extension Flow {
    /// Update transaction.
    /// - Parameters:
    ///   - _: Parameter description
    /// Updates transaction.
    func updateTransaction(_ newValue: Transaction) {
        if transaction.animation != newValue.animation
            || transaction.disablesAnimations != newValue.disablesAnimations
            || transaction.isContinuous != newValue.isContinuous
        {
            DispatchQueue.main.async {
                transaction = newValue
            }
        }
    }
}

struct FlowLayout<Content>: View
where Content : View
{
    var alignment: Alignment
    var axis: Axis
    var content: () -> Content
    var horizontalSpacing: CGFloat
    var size: CGSize
    var verticalSpacing: CGFloat
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        var alignments: [CGSize] = []
        
        var currentIndex = 0
        var lineFirstIndex = 0
        var isLastLineAdjusted = false
        var leading: CGFloat = 0
        var top: CGFloat = 0
        var maxValue: CGFloat = 0
        var maxLineValue: CGFloat = 0
        var maxIndex: Int? = nil
        
        ZStack(alignment: .topLeading) {
            content()
                .fixedSize()
                .alignmentGuide(.leading) { dimensions in
                    if let maxIndex = maxIndex, currentIndex > maxIndex {
                        currentIndex %= maxIndex
                    }
                    
                    if alignments.indices.contains(currentIndex) {
                        return alignments[currentIndex].width
                    }
                    
                    switch axis {
                    case .horizontal:
                        if (abs(top - dimensions.height) > size.height) {
                            //Adjust previous lines
                            if -top > maxLineValue {
                                let adjustment = (maxLineValue + top)
                                * (dimensions[alignment.vertical] / dimensions[.bottom])
                                
                                for index in 0..<lineFirstIndex {
                                    alignments[index].height += adjustment
                                }
                            }
                            
                            maxLineValue = max(maxLineValue, -top)
                            
                            let adjustment = (maxLineValue + top)
                            * (dimensions[alignment.vertical] / dimensions[.bottom])
                            
                            //Adjust current line
                            for index in lineFirstIndex..<currentIndex {
                                alignments[index].height -= adjustment
                            }
                            
                            leading -= (top == 0 ? dimensions.width : maxValue) + horizontalSpacing
                            top = 0
                            lineFirstIndex = currentIndex
                            maxValue = dimensions.width
                        } else {
                            maxValue = max(maxValue, dimensions.width)
                        }
                        
                        alignments.append(CGSize(width: leading, height: top))
                        top -= dimensions.height + verticalSpacing
                        return alignments[currentIndex].width
                        
                    case .vertical:
                        if (abs(leading - dimensions.width) > size.width) {
                            //Adjust previous lines
                            if -leading > maxLineValue {
                                let adjustment = (maxLineValue + leading)
                                * (dimensions[alignment.horizontal] / dimensions[.trailing])
                                
                                for index in 0..<lineFirstIndex {
                                    alignments[index].width += adjustment
                                }
                            }
                            
                            maxLineValue = max(maxLineValue, -leading)
                            
                            let adjustment = (maxLineValue + leading)
                            * (dimensions[alignment.horizontal] / dimensions[.trailing])
                            
                            //Adjust current line
                            for index in lineFirstIndex..<currentIndex {
                                alignments[index].width -= adjustment
                            }
                            
                            top -= (leading == 0 ? dimensions.height : maxValue) + verticalSpacing
                            leading = 0
                            lineFirstIndex = currentIndex
                            maxValue = dimensions.height
                        } else {
                            maxValue = max(maxValue, dimensions.height)
                        }
                        
                        alignments.append(CGSize(width: leading, height: top))
                        leading -= dimensions.width + horizontalSpacing
                        return alignments[currentIndex].width
                    }
                }
                .alignmentGuide(.top) { _ in
                    if let maxIndex = maxIndex, currentIndex > maxIndex {
                        currentIndex %= maxIndex
                    }
                    
                    let top: CGFloat
                    if alignments.indices.contains(currentIndex) {
                        top = alignments[currentIndex].height
                    } else {
                        top = 0
                    }
                    
                    currentIndex += 1
                    return top
                }
            
            Color.clear
                .frame(width: 1, height: 1)
                .alignmentGuide(.leading) { dimensions in
                    if maxIndex == nil {
                        maxIndex = currentIndex
                    }
                    
                    if !isLastLineAdjusted, let lastIndex = alignments.indices.last {
                        switch axis {
                        case .horizontal:
                            let adjustment = (maxLineValue + top)
                            * (dimensions[alignment.vertical] / dimensions[.bottom])
                            
                            for index in lineFirstIndex...lastIndex {
                                alignments[index].height -= adjustment
                            }
                            
                        case .vertical:
                            let adjustment = (maxLineValue + leading)
                            * (dimensions[alignment.horizontal] / dimensions[.trailing])
                            
                            for index in lineFirstIndex...lastIndex {
                                alignments[index].width -= adjustment
                            }
                        }
                        
                        isLastLineAdjusted = true
                    }
                    
                    currentIndex = 0
                    lineFirstIndex = 0
                    leading = 0
                    top = 0
                    maxValue = 0
                    maxLineValue = 0
                    return 0
                }
                .hidden()
        }
        .frame(width: axis == .vertical ? 0 : nil,
               height: axis == .horizontal ? 0 : nil,
               alignment: alignment)
    }
}

public struct VFlow<Content>: View
where Content : View
{
    public var body: Flow<Content>
}


public extension VFlow {
    /// A view that arranges its children in a vertical flow.
    /// This view returns a flexible preferred width to its parent layout.
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same horizontal screen coordinate for every child view.
    ///   - spacing: The distance between adjacent subviews, or `nil` if you
    ///     want the flow to choose a default distance for each pair of
    ///     subviews.
    ///   - content: A view builder that creates the content of this flow.
    init(alignment: HorizontalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.body = Flow(.vertical,
                         alignment: Alignment(horizontal: alignment, vertical: .top),
                         spacing: spacing,
                         content: content)
    }
    
    /// A view that arranges its children in a vertical flow.
    /// This view returns a flexible preferred width to its parent layout.
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this flow. This
    ///     guide has the same horizontal screen coordinate for every child view.
    ///   - horizontalSpacing: The distance between horizontally adjacent
    ///     subviews, or `nil` if you want the flow to choose a default distance
    ///     for each pair of subviews.
    ///   - verticalSpacing: The distance between vertically adjacent
    ///   - content: A view builder that creates the content of this flow.
    init(alignment: HorizontalAlignment = .center,
         horizontalSpacing: CGFloat? = nil,
         verticalSpacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content)
    {
        self.body = Flow(.vertical,
                         alignment: Alignment(horizontal: alignment, vertical: .top),
                         horizontalSpacing: horizontalSpacing,
                         verticalSpacing: verticalSpacing,
                         content: content)
    }
}
