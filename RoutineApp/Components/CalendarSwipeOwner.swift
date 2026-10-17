import ObjectiveC
import SwiftUI
import UIKit

struct CalendarSwipeOwner: UIViewRepresentable {
    func makeUIView(context: Context) -> CalendarSwipeOwnerView {
        CalendarSwipeOwnerView()
    }

    func updateUIView(_ uiView: CalendarSwipeOwnerView, context: Context) {}
}

final class CalendarSwipeOwnerView: UIView {
    private weak var registeredGuard: NavigationSwipeGuard?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        registeredGuard?.unregister(self)
        registeredGuard = nil

        guard window != nil else {
            return
        }

        register()
    }

    private func register(retryOnce: Bool = true) {
        guard window != nil, registeredGuard == nil else {
            return
        }

        guard let navigationController = enclosingNavigationController else {
            if retryOnce {
                DispatchQueue.main.async { [weak self] in
                    self?.register(retryOnce: false)
                }
            }
            return
        }

        let swipeGuard = NavigationSwipeGuard.shared(for: navigationController)
        swipeGuard.register(self)
        registeredGuard = swipeGuard
    }

    private var enclosingNavigationController: UINavigationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let navigationController = (current as? UIViewController)?.navigationController {
                return navigationController
            }
            responder = current.next
        }
        return nil
    }
}

private final class NavigationSwipeGuard: NSObject, UIGestureRecognizerDelegate {
    private static var associationKey: UInt8 = 0
    private static let leftEdgeExclusion: CGFloat = 24

    private let pan = UIPanGestureRecognizer()
    private let cards = NSHashTable<UIView>.weakObjects()
    private let wiredRecognizers = NSHashTable<UIGestureRecognizer>.weakObjects()
    private weak var navigationController: UINavigationController?
    private var touchStart: CGPoint?

    static func shared(for navigationController: UINavigationController) -> NavigationSwipeGuard {
        if let existing = objc_getAssociatedObject(navigationController, &associationKey) as? NavigationSwipeGuard {
            return existing
        }

        let created = NavigationSwipeGuard(navigationController: navigationController)
        objc_setAssociatedObject(navigationController, &associationKey, created, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return created
    }

    private init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
        pan.delegate = self
        pan.cancelsTouchesInView = false
        pan.delaysTouchesBegan = false
        pan.delaysTouchesEnded = false
        navigationController.view.addGestureRecognizer(pan)
    }

    func register(_ card: UIView) {
        cards.add(card)
        wirePopRecognizers()
    }

    func unregister(_ card: UIView) {
        cards.remove(card)
    }

    private func wirePopRecognizers() {
        guard let navigationController else {
            return
        }

        var popRecognizers = [navigationController.interactivePopGestureRecognizer]

        if #available(iOS 26, *) {
            popRecognizers.append(navigationController.interactiveContentPopGestureRecognizer)
        }

        for case let recognizer? in popRecognizers where wiredRecognizers.contains(recognizer) == false {
            recognizer.require(toFail: pan)
            wiredRecognizers.add(recognizer)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touchStart = touch.location(in: pan.view)
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = pan.view, let start = touchStart else {
            return false
        }

        let velocity = pan.velocity(in: view)
        guard abs(velocity.x) >= abs(velocity.y) else {
            return false
        }

        guard start.x > Self.leftEdgeExclusion, isBelowNavigationBar(start, in: view) else {
            return false
        }

        return cards.allObjects.contains { card in
            card.window != nil && visibleFrame(of: card, in: view).contains(start)
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    private func isBelowNavigationBar(_ point: CGPoint, in view: UIView) -> Bool {
        guard let navigationBar = navigationController?.navigationBar else {
            return true
        }

        return point.y >= navigationBar.convert(navigationBar.bounds, to: view).maxY
    }

    private func visibleFrame(of card: UIView, in view: UIView) -> CGRect {
        var rect = card.bounds
        var current: UIView = card

        while let parent = current.superview {
            rect = current.convert(rect, to: parent)

            if parent.clipsToBounds || parent is UIScrollView {
                rect = rect.intersection(parent.bounds)
            }

            current = parent

            if parent === view {
                break
            }
        }

        return rect
    }
}
