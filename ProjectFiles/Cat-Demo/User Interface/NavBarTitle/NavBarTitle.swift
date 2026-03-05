//
//  NavBarTitle.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

// MARK: - Nav Title UI
extension ViewController {
    
    func configureNavBarTitle() {
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 8
        
        let icon = UIImageView(image: UIImage(systemName: "cat.fill"))
        icon.tintColor = .systemPink
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 26).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 26).isActive = true
        
        addGlowAnimation(to: icon)
        
        let label = UILabel()
        label.text = "Cat Breeds"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        
        container.addArrangedSubview(icon)
        container.addArrangedSubview(label)
        
        navigationItem.titleView = container
    }
    
    func addGlowAnimation(to view: UIView) {
        view.layer.shadowColor = UIColor.systemPink.cgColor
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = .zero
        
        let glow = CABasicAnimation(keyPath: "shadowOpacity")
        glow.fromValue = 0.2
        glow.toValue = 2
        glow.duration = 2
        glow.autoreverses = true
        glow.repeatCount = .infinity
        glow.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(glow, forKey: "glow")
    }
}
