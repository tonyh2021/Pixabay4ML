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
    
    public func getUrl(_ completion: @escaping (String?) -> Void) {
        let page = random(min: 1, max: 5)
        let per_page = 100
        
        let apiString = "https://pixabay.com/api/?key=7318185-03d52677622dc8dced9a4332d&min_width=750&min_height=1334&image_type=photo&order=popular&orientation=vertical&category=animals&page=\(page)&per_page=\(per_page)"

        Alamofire.request(apiString, method: .get)
            .responseJSON { response in
                switch response.result {
                case .failure(let error):
                    print(error)
                    completion(nil)
                    return
                case .success(let data):
                    guard let json = data as? [String : AnyObject] else {
                        completion(nil)
                        return
                    }
                    guard let hits = json["hits"] as? [[String : AnyObject]] else {
                        completion(nil)
                        return
                    }
                    let index = self.random(min: 0, max: per_page)
                    guard let webformatURL = hits[index]["webformatURL"] as? String else {
                        completion(nil)
                        return
                    }
                    completion(webformatURL)
                }
        }
        
        //使用 html，后面使用 pixabay 提供的 api
//        let urlString = "https://pixabay.com/zh/photos/?min_width=750&min_height=1334&image_type=photo&order=popular&orientation=vertical&cat=animals&pagi=\(pagi)"
        
//        Alamofire.request(apiString, method: .get).responseString { response in
//            //            print("\(response.result.isSuccess)")
//            if let html = response.result.value {
//                if let url = self.parseHTML(html) {
//                    completion (url)
//                }
//            }
//        }
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
//                    print(srcset)
                    //解析url
                    let url = srcset.split(separator: " ").map(String.init)[2]
                    return url
                } else if let srcset = element["data-lazy-srcset"] {
                    let url = srcset.split(separator: " ").map(String.init)[2]
                    return url
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
