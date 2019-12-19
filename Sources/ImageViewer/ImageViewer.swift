import UIKit

public protocol ImageViewerControllerPresentationDelegate: class {

    func imageViewerWillPresent()
    func imageViewerDidDismiss()
    
}


public class ImageViewer {
    
    public static func present(from presentingController: UIViewController, with initialImage: UIImage, fullImageSource: URL? = nil, sourceFrame: CGRect?, presentationDelegate: ImageViewerControllerPresentationDelegate? = nil) {
        let controller = ImageViewerController()
        controller.sourceFrame = sourceFrame
        controller.image = initialImage
        controller.fullImageSource = fullImageSource
        controller.modalPresentationStyle = .overFullScreen
        controller.presentationDelegate = presentationDelegate
        presentingController.present(controller, animated: false, completion: nil)
    }
    
}

class ImageViewerController: UIViewController {
    
    var didSetConstraints = false
    var didFinishInitialAnimation = false
    var didSetIntialLayout = false
    var needsAnimatedLayout = true
    open internal(set) var presented = false
    open weak var presentationDelegate: ImageViewerControllerPresentationDelegate?

    var sourceFrame: CGRect?
    var image: UIImage?
    let fakeTextField = UITextField()
    var fullImageSource: URL? {
        didSet {
            downloadFullImage()
        }
    }
    
    private let transitionDuration: TimeInterval = 0.25
    
    lazy var transitionManager: LightboxTransition = LightboxTransition()

    lazy var contentView: ContentView = {
        assert(self.image != nil, "No image was given to the view")
        let image = self.image ?? UIImage.blank(size: CGSize(width: 10, height: 10))
        let c = ContentView(image: image)
        c.backgroundColor = .clear
        c.addGestureRecognizer(panGestureRecognizer)
        return c
    }()
    
    lazy var presentingImageView: UIImageView = {
        let i = UIImageView()
        i.contentMode = .scaleAspectFit
        i.image = self.image
        return i
    }()

    lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Close", for: .normal)
        b.tintColor = .white
        b.addTarget(self, action: #selector(self.dismissFullScreen), for: .touchUpInside)
        return b
    }()
    
    // Interactive dismiss
    var interactive = false
    var initialFrame: CGRect = .zero
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
      let gesture = UIPanGestureRecognizer()
      gesture.addTarget(self, action: #selector(handlePanGesture(_:)))
      gesture.delegate = self

      return gesture
      }()


    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        view.addSubview(contentView)
        view.addSubview(presentingImageView)
        insertCloseButton()
        
//        transitionManager.lightboxController = self
//        transitionManager.scrollView = contentView
//        transitioningDelegate = transitionManager

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performPresentationAnimation()
    }

    func insertCloseButton() {
        view.addSubview(closeButton)
        closeButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        closeButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.frame != .zero else {
            return
        }
        contentView.frame = view.bounds
    }
    
    func performPresentationAnimation() {
        if let orignalFrame = sourceFrame {
            presentingImageView.frame = orignalFrame
        }
        self.presentationDelegate?.imageViewerWillPresent()
        UIView.animate(withDuration: transitionDuration, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.presentingImageView.frame = self.view.bounds
            self.view.backgroundColor = .black
        }, completion: {
            guard $0 else { return }
            self.contentView.configureLayout()
            self.presentingImageView.isHidden = true
        })
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.contentView.configureLayout()
        }, completion: nil)
    }

    @objc func dismissFullScreen() {
        dismiss()
    }
    
    func downloadFullImage() {
        guard let url = fullImageSource else {
            return
        }
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                self.image = image
                self.contentView.update(with: image)
            }
        }.resume()
    }
    
    func dismiss() {
        guard let orignalFrame = sourceFrame else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        contentView.imageView.isHidden = true
        presentingImageView.frame = contentView.frame
        presentingImageView.isHidden = false
        closeButton.isHidden = true
        UIView.animate(withDuration: transitionDuration, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            self.presentingImageView.frame = orignalFrame
            self.view.backgroundColor = .clear
        }, completion: {
            guard $0 else { return }
            self.dismiss(animated: false, completion: {
                self.presentationDelegate?.imageViewerDidDismiss()
            })
        })
    }
    
}

extension ImageViewerController: UIGestureRecognizerDelegate {
    
    // MARK: - Pan gesture recognizer
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentView)
        let percentage = max(abs(translation.y) / UIScreen.main.bounds.height / 1.5, abs(translation.x) / UIScreen.main.bounds.width / 1.5)
        let velocity = gesture.velocity(in: contentView)
        
        switch gesture.state {
        case .began:
            interactive = true
            presented = false
            initialFrame = contentView.frame
            closeButton.isHidden = true
        case .changed:
            //   update(percentage)
            contentView.frame.origin.y = initialFrame.origin.y + translation.y
            contentView.frame.origin.x = initialFrame.origin.x + translation.x

            view.backgroundColor = UIColor.black.withAlphaComponent(1.0-percentage)
       //     contentView.reduceFrameBy(original: initialFrame, percent: percentage)
        case .ended, .cancelled:
            
            var time = translation.y * 3 / abs(velocity.y)
            if time > 1 { time = 0.7 }
            
            interactive = false
            presented = true
            
            if percentage > 0.1 {
                //finish()
                closeButton.alpha = 0
                self.dismiss()
            } else {
                // cancel()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.035) {
                    self.closeButton.isHidden = false
                    UIView.animate(withDuration: self.transitionDuration, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                        self.contentView.frame = self.initialFrame
                        self.view.backgroundColor = UIColor.black
                    })
                }
            }
        default: break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard contentView.zoomScale == contentView.minimumZoomScale else {
            return false
        }
        var result = false
        
        if gestureRecognizer as? UIPanGestureRecognizer != nil {
            result = true
        }
        
        return result
    }
    
}

extension UIView {
    
//    func reduceFrameBy(original: CGRect, percent: CGFloat) {
//        let newWidth = original.width*percent
//        let newHeight = original.height*percent
//
//        let lostWidth = (frame.width-newWidth)/2.0
//        let lostHeight = (frame.height-newHeight)/2.0
//
//      //  frame.size.height = newHeight
//        //frame.size.width = newWidth
//    }
    
}
