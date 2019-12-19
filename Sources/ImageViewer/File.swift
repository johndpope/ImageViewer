//
//  Extension+UIImage.swift
//  
//
//  Created by Aaron Satterfield on 12/10/19.
//

import Foundation
import UIKit

extension UIImage {
    
    static func blank(size: CGSize, color: UIColor = .black) -> UIImage {
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        UIGraphicsGetCurrentContext()?.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()?.fill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    
}
