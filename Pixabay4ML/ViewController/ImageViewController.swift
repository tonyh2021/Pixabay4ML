//
//  ImageViewController.swift
//  Pixabay4ML
//
//  Created by qd-hxt on 2017/12/7.
//  Copyright © 2017年 qding. All rights reserved.
//

import UIKit
import Kingfisher
import CoreML

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var model: Inceptionv3!
    
    var inputImage: UIImage?
    
    @IBOutlet weak var labelView: UIView!
    
    @IBOutlet weak var classLabel: UILabel!
    
    @IBOutlet weak var probLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = true
        
        imageView.kf.indicatorType = .activity
        imageView.kf.indicator?.startAnimatingView()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        imageView.addGestureRecognizer(tap)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        let image = UIImage(named:"cat")
        imageView.image = image
        
        labelView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        classLabel.isHidden = true
        probLabel.isHidden = true
        
        model = Inceptionv3()
        
        let deadline = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.predictImage(image!)
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
//        let tappedImage = tapGestureRecognizer.view as! UIImageView
//        print(tappedImage)
        imageView.image = nil
        imageView.kf.indicator?.startAnimatingView()
        loadImage()
    }

    func loadImage() {
        imageView.isUserInteractionEnabled = false
        classLabel.isHidden = true
        probLabel.isHidden = true
        
        ImageUrlManager.shared.getUrl {
            guard let urlString = $0 else {
                self.refreshUI(nil)
                return
            }

            let url = URL(string:urlString)!
            self.imageView.kf.setImage(with: url,
                                       placeholder: nil,
                                       options: [.transition(ImageTransition.fade(1))],
                                       progressBlock: { receivedSize, totalSize in
                                        print("\(receivedSize)/\(totalSize)")
            },
                                       completionHandler: { image, error, cacheType, imageURL in
                                        self.predictImage(image!)
            })
        }
    }
    
    func predictImage(_ image:UIImage) {
        
        //将图像转成 299*299 的正方形
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
//        将 newImage 转成 CVPixelBuffer，CVPixelBuffer 是在主存储器中保存像素的图像缓冲区，由于CV开头，所以它是属于 CoreVideo 模块的。
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3

        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        /// 预测图片
        if let prediction = try? model.prediction(image: pixelBuffer!) {
            refreshUI(prediction)
        } else {
            refreshUI(nil)
        }
    }
    
    func refreshUI(_ prediction : Inceptionv3Output?) {
        if prediction != nil {
            imageView.kf.indicator?.stopAnimatingView()
            
            classLabel.isHidden = false
            classLabel.alpha = 0
            
            let classLabelText = prediction!.classLabel.split(separator: ",").first!
            classLabel.text = "ClassLabel : \(String(describing: classLabelText))"
            
            probLabel.isHidden = false
            probLabel.alpha = 0
            
            let prop = Double(prediction!.classLabelProbs[prediction!.classLabel]!)
            let propText = String(format: "%.2f", prop)
            probLabel.text = "Prob : \(propText)"
            
            UIView.animate(withDuration: 0.1, animations: {
                self.classLabel.alpha = 1
                self.probLabel.alpha = 1
            }) { _ in
                self.imageView.isUserInteractionEnabled = true
            }
        } else {
            imageView.kf.indicator?.stopAnimatingView()
            classLabel.isHidden = false
            classLabel.text = "Load failed...Tap the screen to reload."
            imageView.isUserInteractionEnabled = true
        }
    }
}
