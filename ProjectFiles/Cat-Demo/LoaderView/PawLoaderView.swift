//
//  PawLoaderView.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

final class PawLoaderView: UIView {

    private let paw = UIImageView(image: UIImage(systemName: "pawprint.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

 private func setup() {
        isUserInteractionEnabled = true
        backgroundColor = UIColor.black.withAlphaComponent(0.15)

        paw.translatesAutoresizingMaskIntoConstraints = false
        paw.tintColor = .systemPink
        paw.contentMode = .scaleAspectFit
        addSubview(paw)

        NSLayoutConstraint.activate([
            paw.centerXAnchor.constraint(equalTo: centerXAnchor),
            paw.centerYAnchor.constraint(equalTo: centerYAnchor),
            paw.widthAnchor.constraint(equalToConstant: 44),
            paw.heightAnchor.constraint(equalToConstant: 44)
        ])

        alpha = 0
        startAnimating()
    }

    func startAnimating() {
        paw.layer.removeAllAnimations()

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.9
        pulse.toValue = 1.15
        pulse.duration = 0.6
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = -0.12
        rotate.toValue = 0.12
        rotate.duration = 0.6
        rotate.autoreverses = true
        rotate.repeatCount = .infinity
        rotate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        paw.layer.add(pulse, forKey: "pulse")
        paw.layer.add(rotate, forKey: "rotate")
    }

    private var shownAt: Date?
    
    func show(in view: UIView) {
        shownAt = Date()
        frame = view.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if superview == nil { view.addSubview(self) }

        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
    }

    func hide(minDuration: TimeInterval = 0) {
        let elapsed = shownAt.map { Date().timeIntervalSince($0) } ?? 0
        let remaining = max(0, minDuration - elapsed)

        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
    }
}
