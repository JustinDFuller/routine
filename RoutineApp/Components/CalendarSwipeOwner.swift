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

    private let pan = UIPanGestureRecognizer()
    private let cards = NSHashTable<UIView>.weakObjects()

    static func shared(for navigationController: UINavigationController) -> NavigationSwipeGuard {
        if let existing = objc_getAssociatedObject(navigationController, &associationKey) as? NavigationSwipeGuard {
            return existing
        }

        let created = NavigationSwipeGuard(navigationController: navigationController)
        objc_setAssociatedObject(navigationController, &associationKey, created, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return created
    }

    private init(navigationController: UINavigationController) {
        super.init()
        pan.delegate = self
        pan.cancelsTouchesInView = false
        pan.delaysTouchesBegan = false
        pan.delaysTouchesEnded = false
        navigationController.view.addGestureRecognizer(pan)
        navigationController.interactivePopGestureRecognizer?.require(toFail: pan)

        if #available(iOS 26, *) {
            navigationController.interactiveContentPopGestureRecognizer?.require(toFail: pan)
        }
    }

    func register(_ card: UIView) {
        cards.add(card)
    }

    func unregister(_ card: UIView) {
        cards.remove(card)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = pan.view else {
            return false
        }

        let velocity = pan.velocity(in: view)
        guard abs(velocity.x) > abs(velocity.y) else {
            return false
        }

        let translation = pan.translation(in: view)
        let location = pan.location(in: view)
        let start = CGPoint(x: location.x - translation.x, y: location.y - translation.y)

        return cards.allObjects.contains { card in
            card.window != nil && card.convert(card.bounds, to: view).contains(start)
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
