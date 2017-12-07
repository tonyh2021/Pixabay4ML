//
//  ImageUrlManager.swift
//  Pixabay4ML
//
//  Created by qd-hxt on 2017/12/7.
//  Copyright © 2017年 qding. All rights reserved.
//

import Foundation
import Alamofire
import Fuzi

class ImageUrlManager {
    static let shared = ImageUrlManager()
    
    var urls: [String] = []
    
    fileprivate init() {
        
    }
    
    deinit {
    }
    
    public func getUrl(_ completion: @escaping (String) -> Void) {
        let pagi = random(min: 1, max: 1000)
        let urlString = "https://pixabay.com/zh/photos/?image_type=photo&order=popular&orientation=horizontal&cat=animals&pagi=\(pagi)"

        Alamofire.request(urlString, method: .get).responseString { response in
//            print("\(response.result.isSuccess)")
            if let html = response.result.value {
                if let url = self.parseHTML(html) {
//                    print(url)
                    completion (url)
                }
            }
        }
    }
    
    /// 解析html文档，暂存urls，返回获取到的url
    ///
    /// - Parameter html: html
    /// - Returns: url
    func parseHTML(_ html :String) -> String? {
//        print(html)
        do {
            // 获取 Document 文档
            let doc = try HTMLDocument(string: html, encoding: String.Encoding.utf8)
            
            // 通过 CSS 解析
            let urls = doc.css(".item a img").map({ element -> String? in
                if let srcset = element["srcset"] {
                    //解析url
                    if let url = srcset.split(separator: " ").first {
                        return String(url)
                    }
                } else if let srcset = element["data-lazy-srcset"] {
                    if let url = srcset.split(separator: " ").first {
                        return String(url)
                    }
                }
                return nil
            })
            if (urls.count > 0) {
                let index = random(min: 0, max: urls.count)
                return urls[index]
            } else {
                return nil
            }
        } catch let error {
            print(error)
            return nil
        }
    }
    
    /// 返回 min 到 max 之间的随机数 比如：[min, max)  [0, 100)
    func random(min: Int, max: Int) -> Int {
        let y = arc4random() % UInt32(max) + UInt32(min)
//        print(Int(y))
        return Int(y)
    }
}
