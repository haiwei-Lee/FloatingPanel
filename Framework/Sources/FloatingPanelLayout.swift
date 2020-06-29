// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

@objc public enum FloatingPanelLayoutReferenceGuide: Int {
    case superview = 0
    case safeArea = 1
}

private extension FloatingPanelLayoutReferenceGuide {
    func layoutGuide(vc: UIViewController) -> LayoutGuideProvider {
        switch self {
        case .safeArea:
            return vc.fp_safeAreaLayoutGuide
        case .superview:
            return vc.view
        }
    }
}

@objc public enum FloatingPanelPosition: Int {
    case top
    case left
    case bottom
    case right
}

extension FloatingPanelPosition {
    func mainLocation(_ point: CGPoint) -> CGFloat {
        switch self {
        case .top, .bottom: return point.y
        case .left, .right: return point.x
        }
    }

    func mainDimension(_ size: CGSize) -> CGFloat {
        switch self {
        case .top, .bottom: return size.height
        case .left, .right: return size.width
        }
    }

    func mainDimensionAnchor(_ layoutGuide: LayoutGuideProvider) -> NSLayoutDimension {
        switch self {
        case .top, .bottom: return layoutGuide.heightAnchor
        case .left, .right: return layoutGuide.widthAnchor
        }
    }

    func crossDimension(_ size: CGSize) -> CGFloat {
        switch self {
        case .top, .bottom: return size.width
        case .left, .right: return size.height
        }
    }

    func inset(_ insets: UIEdgeInsets) -> CGFloat {
        switch self {
        case .top: return insets.top
        case .left: return insets.left
        case .bottom: return insets.bottom
        case .right: return insets.right
        }
    }
}

@objc public enum FloatingPanelReferenceEdge: Int {
    case top
    case left
    case bottom
    case right
}

private extension FloatingPanelReferenceEdge {
    func inset(of insets: UIEdgeInsets) -> CGFloat {
        switch self {
        case .top: return insets.top
        case .left: return insets.left
        case .bottom: return insets.bottom
        case .right: return insets.right
        }
    }
    func mainDimension(_ size: CGSize) -> CGFloat {
        switch self {
        case .top, .bottom: return size.height
        case .left, .right: return size.width
        }
    }
}

@objc public protocol FloatingPanelLayoutAnchoring {
    var referenceGuide: FloatingPanelLayoutReferenceGuide { get }
    func layoutConstraints(_ fpc: FloatingPanelController, for position: FloatingPanelPosition) -> [NSLayoutConstraint]
}

@objc final public class FloatingPanelLayoutAnchor: NSObject, FloatingPanelLayoutAnchoring /*, NSCopying */ {
    @objc public init(absoluteInset: CGFloat, edge: FloatingPanelReferenceEdge, referenceGuide: FloatingPanelLayoutReferenceGuide) {
        self.inset = absoluteInset
        self.referenceGuide = referenceGuide
        self.referenceEdge = edge
        self.isAbsolute = true
    }

    @objc public init(fractionalInset: CGFloat, edge: FloatingPanelReferenceEdge, referenceGuide: FloatingPanelLayoutReferenceGuide) {
        self.inset = fractionalInset
        self.referenceGuide = referenceGuide
        self.referenceEdge = edge
        self.isAbsolute = false
    }
    fileprivate let inset: CGFloat
    fileprivate let isAbsolute: Bool
    @objc public let referenceGuide: FloatingPanelLayoutReferenceGuide
    @objc public let referenceEdge: FloatingPanelReferenceEdge
}

public extension FloatingPanelLayoutAnchor {
    func layoutConstraints(_ vc: FloatingPanelController, for position: FloatingPanelPosition) -> [NSLayoutConstraint] {
        let layoutGuide = referenceGuide.layoutGuide(vc: vc)
        switch position {
        case .top:
            return layoutConstraints(layoutGuide, for: vc.surfaceView.bottomAnchor)
        case .left:
            return layoutConstraints(layoutGuide, for: vc.surfaceView.rightAnchor)
        case .bottom:
            return layoutConstraints(layoutGuide, for:  vc.surfaceView.topAnchor)
        case .right:
            return layoutConstraints(layoutGuide, for: vc.surfaceView.leftAnchor)
        }
    }

    private func layoutConstraints(_ layoutGuide: LayoutGuideProvider, for edgeAnchor: NSLayoutYAxisAnchor) -> [NSLayoutConstraint] {
        switch referenceEdge {
        case .top:
            if isAbsolute {
                return [edgeAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: inset)]
            }
            let offsetAnchor = layoutGuide.topAnchor.anchorWithOffset(to: edgeAnchor)
            return [offsetAnchor.constraint(equalTo:layoutGuide.heightAnchor, multiplier: inset)]
        case .bottom:
            if isAbsolute {
                return [layoutGuide.bottomAnchor.constraint(equalTo: edgeAnchor, constant: inset)]
            }
            let offsetAnchor = edgeAnchor.anchorWithOffset(to: layoutGuide.bottomAnchor)
            return [offsetAnchor.constraint(equalTo: layoutGuide.heightAnchor, multiplier: inset)]
        default:
            fatalError("Unsupported reference edges")
        }
    }

    private func layoutConstraints(_ layoutGuide: LayoutGuideProvider, for edgeAnchor: NSLayoutXAxisAnchor) -> [NSLayoutConstraint] {
        switch referenceEdge {
        case .left:
            if isAbsolute {
                return [edgeAnchor.constraint(equalTo: layoutGuide.leftAnchor, constant: inset)]
            }
            let offsetAnchor = layoutGuide.leftAnchor.anchorWithOffset(to: edgeAnchor)
            return [offsetAnchor.constraint(equalTo: layoutGuide.widthAnchor, multiplier: inset)]
        case .right:
            if isAbsolute {
                return [layoutGuide.rightAnchor.constraint(equalTo: edgeAnchor, constant: inset)]
            }
            let offsetAnchor = edgeAnchor.anchorWithOffset(to: layoutGuide.rightAnchor)
            return [offsetAnchor.constraint(equalTo: layoutGuide.widthAnchor, multiplier: inset)]
        default:
            fatalError("Unsupported reference edges")
        }
    }
}

@objc final public class FloatingPanelIntrinsicLayoutAnchor: NSObject, FloatingPanelLayoutAnchoring /*, NSCopying */ {
    @objc public init(absoluteOffset offset: CGFloat, referenceGuide: FloatingPanelLayoutReferenceGuide = .safeArea) {
        self.offset = offset
        self.referenceGuide = referenceGuide
        self.isAbsolute = true
    }
    // offset = 0.0 -> All content visible
    // offset = 1.0 -> All content invisible
    @objc public init(fractionalOffset offset: CGFloat, referenceGuide: FloatingPanelLayoutReferenceGuide = .safeArea) {
        self.offset = offset
        self.referenceGuide = referenceGuide
        self.isAbsolute = false
    }
    fileprivate let offset: CGFloat
    fileprivate let isAbsolute: Bool
    @objc public let referenceGuide: FloatingPanelLayoutReferenceGuide
}

public extension FloatingPanelIntrinsicLayoutAnchor {
    func layoutConstraints(_ vc: FloatingPanelController, for position: FloatingPanelPosition) -> [NSLayoutConstraint] {
        let surfaceIntrinsicLength = position.mainDimension(vc.surfaceView.intrinsicContentSize)
        let constant = isAbsolute ? surfaceIntrinsicLength - offset : surfaceIntrinsicLength * (1 - offset)
        let layoutGuide = referenceGuide.layoutGuide(vc: vc)
        switch position {
        case .top:
            return [vc.surfaceView.bottomAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: constant)]
        case .left:
            return [vc.surfaceView.rightAnchor.constraint(equalTo: layoutGuide.leftAnchor, constant: constant)]
        case .bottom:
            return [vc.surfaceView.topAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -constant)]
        case .right:
            return [vc.surfaceView.leftAnchor.constraint(equalTo: layoutGuide.rightAnchor, constant: -constant)]
        }
    }
}

@objc public protocol FloatingPanelLayout {
    /// The position of the panel in the view of `FloatingPanelController`.
    @objc var position: FloatingPanelPosition { get }

    /// The initial state when the layout is applied.
    @objc var initialState: FloatingPanelState { get }

    /// The layout anchors to specify the snapping locations for each state.
    @objc var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] { get }

    /// Returns X-axis and width layout constraints of the surface view of a floating panel.
    /// You must not include any Y-axis and height layout constraints of the surface view
    /// because their constraints will be configured by the floating panel controller.
    /// By default, the width of a surface view fits a safe area.
    @objc optional func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint]

    /// Returns a CGFloat value to determine the backdrop view's alpha for a state.
    ///
    /// Default is 0.3 at full state, otherwise 0.0.
    @objc optional func backdropAlpha(for state: FloatingPanelState) -> CGFloat
}

@objcMembers
open class FloatingPanelBottomLayout: NSObject, FloatingPanelLayout {
    public override init() {
        super.init()
    }
    open var initialState: FloatingPanelState {
        return .half
    }

    open var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 18.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 69.0, edge: .bottom, referenceGuide: .safeArea),
        ]
    }

    open var position: FloatingPanelPosition {
        return .bottom
    }

    open func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.fp_safeAreaLayoutGuide.leftAnchor, constant: 0.0),
            surfaceView.rightAnchor.constraint(equalTo: view.fp_safeAreaLayoutGuide.rightAnchor, constant: 0.0),
        ]
    }

    open func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return state == .full ? 0.3 : 0.0
    }
}

struct LayoutSegment {
    let lower: FloatingPanelState?
    let upper: FloatingPanelState?
}

class FloatingPanelLayoutAdapter {
    weak var vc: FloatingPanelController!
    private weak var surfaceView: FloatingPanelSurfaceView!
    private weak var backdropView: FloatingPanelBackdropView!
    private let defaultLayout = FloatingPanelBottomLayout()

    fileprivate var layout: FloatingPanelLayout {
        didSet {
            surfaceView.position = position
        }
    }

    private var safeAreaInsets: UIEdgeInsets {
        return vc?.fp_safeAreaInsets ?? .zero
    }

    private var initialConst: CGFloat = 0.0

    private var fixedConstraints: [NSLayoutConstraint] = []
    private var fullConstraints: [NSLayoutConstraint] = []
    private var halfConstraints: [NSLayoutConstraint] = []
    private var tipConstraints: [NSLayoutConstraint] = []
    private var offConstraints: [NSLayoutConstraint] = []
    private var fitToBoundsConstraint: NSLayoutConstraint?

    private(set) var interactionEdgeConstraint: NSLayoutConstraint?
    private(set) var animationEdgeConstraint: NSLayoutConstraint?

    private var staticConstraint: NSLayoutConstraint?

    private var activeStates: Set<FloatingPanelState> {
        return Set(layout.anchors.keys)
    }

    var initialState: FloatingPanelState {
        layout.initialState
    }

    var position: FloatingPanelPosition {
        layout.position
    }

    var orderedStates: [FloatingPanelState] {
        return activeStates.sorted(by: {
            return $0.order < $1.order
        })
    }

    var validStates: Set<FloatingPanelState> {
        return activeStates.union([.hidden])
    }

    var sortedDirectionalStates: [FloatingPanelState] {
        return activeStates.sorted(by: {
            switch position {
            case .top, .left:
                return $0.order < $1.order
            case .bottom, .right:
                return $0.order > $1.order
            }
        })
    }

    private var directionalLeastState: FloatingPanelState {
        return sortedDirectionalStates.first ?? .hidden
    }

    private var directionalMostState: FloatingPanelState {
        return sortedDirectionalStates.last ?? .hidden
    }

    var edgeLeastState: FloatingPanelState {
        if orderedStates.count == 1 {
            return .hidden
        }
        return orderedStates.first ?? .hidden
    }
    
    var edgeMostState: FloatingPanelState {
        if orderedStates.count == 1 {
            return orderedStates[0]
        }
        return orderedStates.last ?? .hidden
    }

    var edgeMostY: CGFloat {
        return position(for: edgeMostState)
    }

    var adjustedContentInsets: UIEdgeInsets {
        switch position {
        case .top:
            return UIEdgeInsets(top: safeAreaInsets.top,
                                left: 0.0,
                                bottom: 0.0,
                                right: 0.0)
        case .left:
            return UIEdgeInsets(top: 0.0,
                                left: safeAreaInsets.left,
                                bottom: 0.0,
                                right: 0.0)
        case .bottom:
            return UIEdgeInsets(top: 0.0,
                                left: 0.0,
                                bottom: safeAreaInsets.bottom,
                                right: 0.0)
        case .right:
            return UIEdgeInsets(top: 0.0,
                                left: 0.0,
                                bottom: 0.0,
                                right: safeAreaInsets.right)
        }
    }

    /*
    Returns a constraint based value in the interaction and animation.

    So that it doesn't need to call `surfaceView.layoutIfNeeded()`
    after every interaction and animation update. It has an effect on
    the smooth interaction because the content view doesn't need to update
    its layout frequently.
    */
    var surfaceLocation: CGPoint {
        get {
            var pos: CGFloat
            if let interactionConstraint = interactionEdgeConstraint {
                pos = interactionConstraint.constant
            } else if let animationConstraint = animationEdgeConstraint, let anchor = layout.anchors[vc.state] {
                switch position {
                case .top, .bottom:
                    switch referenceEdge(of: anchor) {
                    case .top:
                        pos = animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos += safeAreaInsets.top
                        }
                    case .bottom:
                        pos = vc.view.bounds.height + animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos -= safeAreaInsets.bottom
                        }
                    default:
                        fatalError("Unsupported reference edges")
                    }
                case .left, .right:
                    switch referenceEdge(of: anchor) {
                    case .left:
                        pos = animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos += safeAreaInsets.left
                        }
                    case .right:
                        pos = vc.view.bounds.width + animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos -= safeAreaInsets.right
                        }
                    default:
                        fatalError("Unsupported reference edges")
                    }
                }
            } else {
                let displayScale = surfaceView.traitCollection.displayScale
                pos = displayTrunc(edgePosition(surfaceView.frame), by: displayScale)
            }
            switch position {
            case .top, .bottom:
                return CGPoint(x: 0.0, y: pos)
            case .left, .right:
                return CGPoint(x: pos, y: 0.0)
            }
        }
        set {
            let pos = position.mainLocation(newValue)
            if let interactionConstraint = interactionEdgeConstraint {
                interactionConstraint.constant = pos
            } else if let animationConstraint = animationEdgeConstraint, let anchor = layout.anchors[vc.state] {
                let refEdge = referenceEdge(of: anchor)
                switch refEdge {
                case .top, .left:
                    animationConstraint.constant = pos
                    if anchor.referenceGuide == .safeArea {
                        animationConstraint.constant -= refEdge.inset(of: safeAreaInsets)
                    }
                case .bottom, .right:
                    animationConstraint.constant = pos - position.mainDimension(vc.view.bounds.size)
                    if anchor.referenceGuide == .safeArea {
                        animationConstraint.constant += refEdge.inset(of: safeAreaInsets)
                    }
                }
            } else {
                switch position {
                case .top:
                    return surfaceView.frame.origin.y = pos - surfaceView.bounds.height
                case .left:
                    return surfaceView.frame.origin.x = pos - surfaceView.bounds.width
                case .bottom:
                    return surfaceView.frame.origin.y = pos
                case .right:
                    return surfaceView.frame.origin.x = pos
                }
            }
        }
    }

    var offsetFromEdgeMost: CGFloat {
        switch position {
        case .top, .left:
            return edgePosition(surfaceView.presentationFrame) - position(for: directionalMostState)
        case .bottom, .right:
            return position(for: directionalLeastState) - edgePosition(surfaceView.presentationFrame)
        }
    }

    private var hiddenAnchor: FloatingPanelLayoutAnchoring {
        switch position {
        case .top:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .top, referenceGuide: .superview)
        case .left:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .left, referenceGuide: .superview)
        case .bottom:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .bottom, referenceGuide: .superview)
        case .right:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .right, referenceGuide: .superview)
        }
    }

    init(vc: FloatingPanelController,
         surfaceView: FloatingPanelSurfaceView,
         backdropView: FloatingPanelBackdropView,
         layout: FloatingPanelLayout) {
        self.vc = vc
        self.layout = layout
        self.surfaceView = surfaceView
        self.backdropView = backdropView
    }

    func surfaceLocation(for state: FloatingPanelState) -> CGPoint {
        let pos = displayTrunc(position(for: state), by: surfaceView.traitCollection.displayScale)
        switch layout.position {
        case .top, .bottom:
            return CGPoint(x: 0.0, y: pos)
        case .left, .right:
            return CGPoint(x: pos, y: 0.0)
        }
    }

    func position(for state: FloatingPanelState) -> CGFloat {
        let bounds = vc.view.bounds
        let anchor = layout.anchors[state] ?? self.hiddenAnchor

        switch anchor {
        case let ianchor as FloatingPanelIntrinsicLayoutAnchor:
            let surfaceIntrinsicLength = position.mainDimension(surfaceView.intrinsicContentSize)
            let diff = ianchor.isAbsolute ? ianchor.offset : surfaceIntrinsicLength * ianchor.offset

            var referenceBoundsLength = position.mainDimension(bounds.size)
            switch position {
            case .top, .left:
                return referenceBoundsLength - surfaceIntrinsicLength - diff
            case .bottom, .right:
                if anchor.referenceGuide == .safeArea {
                    referenceBoundsLength -= position.inset(safeAreaInsets)
                }
                return referenceBoundsLength - surfaceIntrinsicLength + diff
            }
        case let anchor as FloatingPanelLayoutAnchor:
            let referenceBounds = anchor.referenceGuide == .safeArea ? bounds.inset(by: safeAreaInsets) : bounds
            let diff = anchor.isAbsolute ? anchor.inset : position.mainDimension(referenceBounds.size) * anchor.inset
            switch anchor.referenceEdge {
            case .top:
                return referenceBounds.minY + diff
            case .left:
                return referenceBounds.minX + diff
            case .bottom:
                return referenceBounds.maxY - diff
            case .right:
                return referenceBounds.maxX - diff
            }
        default:
            fatalError("Unsupported a FloatingPanelLayoutAnchoring object")
        }
     }

    private func edgePosition(_ frame: CGRect) -> CGFloat {
        switch position {
        case .top:
            return frame.maxY
        case .left:
            return frame.maxX
        case .bottom:
            return frame.minY
        case .right:
            return frame.minX
        }
    }

    private func referenceEdge(of anchor: FloatingPanelLayoutAnchoring) -> FloatingPanelReferenceEdge {
        switch anchor {
        case is FloatingPanelIntrinsicLayoutAnchor:
            switch position {
            case .top: return .top
            case .left: return .left
            case .bottom: return .bottom
            case .right: return .right
            }
        case let anchor as FloatingPanelLayoutAnchor:
            return anchor.referenceEdge
        default:
            fatalError("Unsupported a FloatingPanelLayoutAnchoring object")
        }
    }

    func prepareLayout() {
        NSLayoutConstraint.deactivate(fixedConstraints)

        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        backdropView.translatesAutoresizingMaskIntoConstraints = false

        // Fixed constraints of surface and backdrop views
        let surfaceConstraints: [NSLayoutConstraint]
        if let constraints = layout.prepareLayout?(surfaceView: surfaceView, in: vc.view) {
            surfaceConstraints = constraints
        } else {
            switch position {
            case .top, .bottom:
                surfaceConstraints = [
                    surfaceView.leftAnchor.constraint(equalTo: vc.fp_safeAreaLayoutGuide.leftAnchor, constant: 0.0),
                    surfaceView.rightAnchor.constraint(equalTo: vc.fp_safeAreaLayoutGuide.rightAnchor, constant: 0.0),
                ]
            case .left, .right:
                surfaceConstraints = [
                    surfaceView.topAnchor.constraint(equalTo: vc.fp_safeAreaLayoutGuide.topAnchor, constant: 0.0),
                    surfaceView.bottomAnchor.constraint(equalTo: vc.fp_safeAreaLayoutGuide.bottomAnchor, constant: 0.0),
                ]
            }
        }
        let backdropConstraints = [
            backdropView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 0.0),
            backdropView.leftAnchor.constraint(equalTo: vc.view.leftAnchor,constant: 0.0),
            backdropView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: 0.0),
            backdropView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: 0.0),
            ]

        fixedConstraints = surfaceConstraints + backdropConstraints

        NSLayoutConstraint.deactivate(constraint: self.fitToBoundsConstraint)
        self.fitToBoundsConstraint = nil

        if vc.contentMode == .fitToBounds {
            switch position {
            case .top:
                fitToBoundsConstraint = surfaceView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-top"
            case .left:
                fitToBoundsConstraint = surfaceView.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-left"
            case .bottom:
                fitToBoundsConstraint = surfaceView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-bottom"
            case .right:
                fitToBoundsConstraint = surfaceView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-right"
            }
            fitToBoundsConstraint?.priority = .defaultHigh
        }

        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)

        if let fullAnchor = layout.anchors[.full] {
            fullConstraints = fullAnchor.layoutConstraints(vc, for: position)
            fullConstraints.forEach {
                $0.identifier = "FloatingPanel-full-constraint"
            }
        }
        if let halfAnchor = layout.anchors[.half] {
            halfConstraints = halfAnchor.layoutConstraints(vc, for: position)
            halfConstraints.forEach {
                $0.identifier = "FloatingPanel-half-constraint"
            }
        }
        if let tipAnchors = layout.anchors[.tip] {
            tipConstraints = tipAnchors.layoutConstraints(vc, for: position)
            tipConstraints.forEach {
                $0.identifier = "FloatingPanel-tip-constraint"
            }
        }
        let hiddenAnchor = layout.anchors[.hidden] ?? self.hiddenAnchor
        offConstraints = hiddenAnchor.layoutConstraints(vc, for: position)
        offConstraints.forEach {
            $0.identifier = "FloatingPanel-hidden-constraint"
        }
    }

    func startInteraction(at state: FloatingPanelState, offset: CGPoint = .zero) {
        if let edgeConstraint = self.interactionEdgeConstraint {
            initialConst = edgeConstraint.constant
            return
        }

        tearDownAnimationEdgeConstraint()

        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)

        initialConst = edgePosition(surfaceView.frame) + offset.y

        let interactionConstraint: NSLayoutConstraint
        switch position {
        case .top:
            interactionConstraint = surfaceView.bottomAnchor.constraint(equalTo: vc.view.topAnchor, constant: initialConst)
        case .left:
            interactionConstraint = surfaceView.rightAnchor.constraint(equalTo: vc.view.leftAnchor, constant: initialConst)
        case .bottom:
            interactionConstraint = surfaceView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: initialConst)
        case .right:
            interactionConstraint = surfaceView.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: initialConst)
        }

        interactionConstraint.priority = .defaultHigh
        interactionConstraint.identifier = "FloatingPanel-interaction"

        NSLayoutConstraint.activate([interactionConstraint])
        self.interactionEdgeConstraint = interactionConstraint
    }

    func endInteraction(at state: FloatingPanelState) {
        // Don't deactivate `interactiveTopConstraint` here because it leads to
        // unsatisfiable constraints

        if self.interactionEdgeConstraint == nil {
            // Actiavate `interactiveTopConstraint` for `fitToBounds` mode.
            // It goes throught this path when the pan gesture state jumps
            // from .begin to .end.
            startInteraction(at: state)
        }
    }

    func setUpAnimationEdgeConstraint(to state: FloatingPanelState) -> (NSLayoutConstraint, CGFloat) {
        NSLayoutConstraint.deactivate(constraint: animationEdgeConstraint)

        let anchor = layout.anchors[state] ?? self.hiddenAnchor

        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)
        NSLayoutConstraint.deactivate(constraint: interactionEdgeConstraint)
        interactionEdgeConstraint = nil

        let layoutGuideProvider: LayoutGuideProvider
        switch anchor.referenceGuide {
        case .safeArea:
            layoutGuideProvider = vc.fp_safeAreaLayoutGuide
        case .superview:
            layoutGuideProvider = vc.view
        }
        let currentY = position.mainLocation(surfaceLocation)
        let baseHeight = position.mainDimension(vc.view.bounds.size)

        let animationConstraint: NSLayoutConstraint
        var targetY = position(for: state)

        switch position {
        case .top:
            switch referenceEdge(of: anchor) {
            case .top:
                animationConstraint = surfaceView.bottomAnchor.constraint(equalTo: layoutGuideProvider.topAnchor,
                                                                          constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.top
                    targetY -= safeAreaInsets.top
                }
            case .bottom:
                let baseHeight = vc.view.bounds.height
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.bottomAnchor.constraint(equalTo: layoutGuideProvider.bottomAnchor,
                                                                          constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.bottom
                    targetY += safeAreaInsets.bottom

                }
            default:
                fatalError("Unsupported reference edges")
            }
        case .left:
            switch referenceEdge(of: anchor) {
            case .left:
                animationConstraint = surfaceView.rightAnchor.constraint(equalTo: layoutGuideProvider.leftAnchor,
                                                                          constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.right
                    targetY -= safeAreaInsets.right
                }
            case .right:
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.rightAnchor.constraint(equalTo: layoutGuideProvider.rightAnchor,
                                                                          constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.left
                    targetY += safeAreaInsets.left
                }
            default:
                fatalError("Unsupported reference edges")
            }
        case .bottom:
            switch referenceEdge(of: anchor) {
            case .top:
                animationConstraint = surfaceView.topAnchor.constraint(equalTo: layoutGuideProvider.topAnchor,
                                                                       constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.top
                    targetY -= safeAreaInsets.top
                }
            case .bottom:
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.topAnchor.constraint(equalTo: layoutGuideProvider.bottomAnchor,
                                                                       constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.bottom
                    targetY += safeAreaInsets.bottom

                }
            default:
                fatalError("Unsupported reference edges")
            }
        case .right:
            switch referenceEdge(of: anchor) {
            case .left:
                animationConstraint = surfaceView.leftAnchor.constraint(equalTo: layoutGuideProvider.leftAnchor,
                                                                         constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.left
                    targetY -= safeAreaInsets.left
                }
            case .right:
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.leftAnchor.constraint(equalTo: layoutGuideProvider.rightAnchor,
                                                                         constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.right
                    targetY += safeAreaInsets.right
                }
            default:
                fatalError("Unsupported reference edges")
            }
        }

        animationConstraint.priority = .defaultHigh
        animationConstraint.identifier = "FloatingPanel-deceleration"

        NSLayoutConstraint.activate([animationConstraint])
        self.animationEdgeConstraint = animationConstraint
        return (animationConstraint, targetY)
    }

    private func tearDownAnimationEdgeConstraint() {
        NSLayoutConstraint.deactivate(constraint: animationEdgeConstraint)
        animationEdgeConstraint = nil
    }

    // The method is separated from prepareLayout(to:) for the rotation support
    // It must be called in FloatingPanelController.traitCollectionDidChange(_:)
    func updateStaticConstraint() {
        guard let vc = vc else { return }
        NSLayoutConstraint.deactivate(constraint: staticConstraint)
        staticConstraint = nil

        if vc.contentMode == .fitToBounds {
            surfaceView.containerOverflow = 0
            return
        }

        let anchor = layout.anchors[self.edgeMostState]!
        if anchor is FloatingPanelIntrinsicLayoutAnchor {
            var constant = layout.position.mainDimension(surfaceView.intrinsicContentSize)
            if anchor.referenceGuide == .safeArea {
                constant += position.inset(safeAreaInsets)
            }
            staticConstraint = position.mainDimensionAnchor(surfaceView).constraint(equalToConstant: constant)
        } else {
            switch position {
            case .top, .left:
                staticConstraint = position.mainDimensionAnchor(surfaceView).constraint(equalToConstant: position(for: self.directionalMostState))
            case .bottom, .right:
                staticConstraint = position.mainDimensionAnchor(vc.view).constraint(equalTo: position.mainDimensionAnchor(surfaceView),
                                                                                    constant: position(for: self.directionalLeastState))
            }
        }

        switch position {
        case .top, .bottom:
            staticConstraint?.identifier = "FloatingPanel-static-height"
        case .left, .right:
            staticConstraint?.identifier = "FloatingPanel-static-width"
        }

        NSLayoutConstraint.activate(constraint: staticConstraint)

        surfaceView.containerOverflow = position.mainDimension(vc.view.bounds.size)
    }

    func updateInteractiveEdgeConstraint(diff: CGFloat, overflow: Bool, allowsRubberBanding: (UIRectEdge) -> Bool) {
        defer {
            log.debug("update surface location = \(surfaceLocation)")
        }

        let minConst: CGFloat = position(for: directionalLeastState)
        let maxConst: CGFloat = position(for: directionalMostState)

        var const = initialConst + diff

        let base = position.mainDimension(vc.view.bounds.size)
        // Rubberbanding top buffer
        if allowsRubberBanding(.top), const < minConst {
            let buffer = minConst - const
            const = minConst - rubberbandEffect(for: buffer, base: base)
        }

        // Rubberbanding bottom buffer
        if allowsRubberBanding(.bottom), const > maxConst {
            let buffer = const - maxConst
            const = maxConst + rubberbandEffect(for: buffer, base: base)
        }

        if overflow == false {
            const = min(max(const, minConst), maxConst)
        }

        interactionEdgeConstraint?.constant = const
    }

    // According to @chpwn's tweet: https://twitter.com/chpwn/status/285540192096497664
    // x = distance from the edge
    // c = constant value, UIScrollView uses 0.55
    // d = dimension, either width or height
    private func rubberbandEffect(for buffer: CGFloat, base: CGFloat) -> CGFloat {
        return (1.0 - (1.0 / ((buffer * 0.55 / base) + 1.0))) * base
    }

    func activateLayout(for state: FloatingPanelState, forceLayout: Bool = false) {
        defer {
            if forceLayout {
                layoutSurfaceIfNeeded()
                log.debug("activateLayout for \(state) -- surface.presentation = \(self.surfaceView.presentationFrame) surface.frame = \(self.surfaceView.frame)")
            } else {
                log.debug("activateLayout for \(state)")
            }
        }

        // Must deactivate `interactiveTopConstraint` here
        NSLayoutConstraint.deactivate(constraint: self.interactionEdgeConstraint)
        self.interactionEdgeConstraint = nil

        tearDownAnimationEdgeConstraint()

        NSLayoutConstraint.activate(fixedConstraints)

        if vc.contentMode == .fitToBounds {
            NSLayoutConstraint.activate(constraint: self.fitToBoundsConstraint)
        }

        var state = state

        setBackdropAlpha(of: state)

        if validStates.contains(state) == false {
            state = layout.initialState
        }

        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)
        switch state {
        case .full:
            NSLayoutConstraint.activate(fullConstraints)
        case .half:
            NSLayoutConstraint.activate(halfConstraints)
        case .tip:
            NSLayoutConstraint.activate(tipConstraints)
        case .hidden:
            NSLayoutConstraint.activate(offConstraints)
        default:
            break
        }
    }

    private func layoutSurfaceIfNeeded() {
        #if !TEST
        guard surfaceView.window != nil else { return }
        #endif
        surfaceView.superview?.layoutIfNeeded()
    }

    private func setBackdropAlpha(of target: FloatingPanelState) {
        if target == .hidden {
            self.backdropView.alpha = 0.0
        } else {
            self.backdropView.alpha = backdropAlpha(for: target)
        }
    }

    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return layout.backdropAlpha?(for: state) ?? defaultLayout.backdropAlpha(for: state)
    }

    func checkLayout() {
        // Verify layout configurations
        assert(activeStates.count > 0)
        assert(validStates.contains(layout.initialState),
               "Does not include an initial state (\(layout.initialState)) in (\(validStates))")
        let statePosOrder = activeStates.sorted(by: { position(for: $0) < position(for: $1) })
        assert(sortedDirectionalStates == statePosOrder,
               "Check your layout anchors because the state order(\(statePosOrder)) must be (\(sortedDirectionalStates))).")
    }
}

extension FloatingPanelLayoutAdapter {
    func segument(at pos: CGFloat, forward: Bool) -> LayoutSegment {
        /// ----------------------->Y
        /// --> forward                <-- backward
        /// |-------|===o===|-------|  |-------|-------|===o===|
        /// |-------|-------x=======|  |-------|=======x-------|
        /// |-------|-------|===o===|  |-------|===o===|-------|
        /// pos: o/x, seguement: =

        let sortedStates = sortedDirectionalStates

        let upperIndex: Int?
        if forward {
            upperIndex = sortedStates.firstIndex(where: { pos < position(for: $0) })
        } else {
            upperIndex = sortedStates.firstIndex(where: { pos <= position(for: $0) })
        }

        switch upperIndex {
        case 0:
            return LayoutSegment(lower: nil, upper: sortedStates.first)
        case let upperIndex?:
            return LayoutSegment(lower: sortedStates[upperIndex - 1], upper: sortedStates[upperIndex])
        default:
            return LayoutSegment(lower: sortedStates[sortedStates.endIndex - 1], upper: nil)
        }
    }
}

extension FloatingPanelController {
    var _layout: FloatingPanelLayout {
        get { floatingPanel.layoutAdapter.layout }
        set { floatingPanel.layoutAdapter.layout = newValue}
    }
}
