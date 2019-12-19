//
//  File.swift
//  
//
//  Created by Aaron Satterfield on 12/9/19.
//

import Foundation
import UIKit

import UIKit

class ContentView: UIScrollView {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()
    
    var image: UIImage
    var contentFrame = CGRect.zero
    
    var hasZoomed: Bool {
        return zoomScale != 1.0
    }
    
    // MARK: - Initializers
    init(image: UIImage) {
        self.image = image
        super.init(frame: CGRect.zero)
        
        configure()
        
        fetchImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    func configure() {
        addSubview(imageView)
        
        delegate = self
        isMultipleTouchEnabled = true
        minimumZoomScale = 1.0
        maximumZoomScale = 3.0
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(scrollViewDoubleTapped(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTapRecognizer)
                
    }
    
    // MARK: - Update
    func update(with image: UIImage) {
        self.image = image
        fetchImage()
    }
    
    // MARK: - Fetch
    private func fetchImage () {
        imageView.image = image
        self.isUserInteractionEnabled = true
        self.configureImageView()
    }
    
    // MARK: - Recognizers
    @objc func scrollViewDoubleTapped(_ recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: imageView)
        let newZoomScale = zoomScale > minimumZoomScale
            ? minimumZoomScale
            : maximumZoomScale
        
        let width = contentFrame.size.width / newZoomScale
        let height = contentFrame.size.height / newZoomScale
        let x = pointInView.x - (width / 2.0)
        let y = pointInView.y - (height / 2.0)
        
        let rectToZoomTo = CGRect(x: x, y: y, width: width, height: height)
        
        zoom(to: rectToZoomTo, animated: true)
    }
    
    
    // MARK: - Layout
    
    func configureImageView() {
        guard let image = imageView.image else {
            centerImageView()
            return
        }
        
        let imageViewSize = imageView.frame.size
        let imageSize = image.size
        let realImageViewSize: CGSize
        
        if imageSize.width / imageSize.height > imageViewSize.width / imageViewSize.height {
            realImageViewSize = CGSize(
                width: imageViewSize.width,
                height: imageViewSize.width / imageSize.width * imageSize.height)
        } else {
            realImageViewSize = CGSize(
                width: imageViewSize.height / imageSize.height * imageSize.width,
                height: imageViewSize.height)
        }
        
        imageView.frame = CGRect(origin: CGPoint.zero, size: realImageViewSize)
        
        centerImageView()
    }
    
    func centerImageView() {
        let boundsSize = contentFrame.size
        var imageViewFrame = imageView.frame
        
        if imageViewFrame.size.width < boundsSize.width {
            imageViewFrame.origin.x = (boundsSize.width - imageViewFrame.size.width) / 2.0
        } else {
            imageViewFrame.origin.x = 0.0
        }
        
        if imageViewFrame.size.height < boundsSize.height {
            imageViewFrame.origin.y = (boundsSize.height - imageViewFrame.size.height) / 2.0
        } else {
            imageViewFrame.origin.y = 0.0
        }
        
        imageView.frame = imageViewFrame
    }
    
    
}

// MARK: - LayoutConfigurable
extension ContentView {
    
    @objc func configureLayout() {
        contentFrame = frame
        contentSize = frame.size
        imageView.frame = frame
        zoomScale = minimumZoomScale
        
        configureImageView()
    }
}

// MARK: - UIScrollViewDelegate
extension ContentView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }
}
