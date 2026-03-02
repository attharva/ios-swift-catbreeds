//
//  AlertView.swift
//  Cat-Demo
//
//  Created by Atharva Kulkarni on 25/02/26.
//

import UIKit

// MARK: - Alert
extension ViewController {

    func showAlert(
        title: String = "Something went wrong",
        message: String,
        retryHandler: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        if let retryHandler {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                retryHandler()
            })
        }

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))

        present(alert, animated: true)
    }
    
}


