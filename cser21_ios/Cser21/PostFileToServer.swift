//
//  PostFileToServer.swift
//  Cser21
//
//  Created by Hung-Catalina on 4/7/20.
//  Copyright © 2020 High Sierra. All rights reserved.
//

import Foundation
import Alamofire
class PostFileToServer{
    var app21: App21? = nil
    func execute(result: Result) -> Void {
        
        do{
            let decoder = JSONDecoder()
            let pinfo = try decoder.decode(PostInfo.self, from: result.params!.data(using: .utf8)!)
            
            let url = pinfo.server ?? "" /* your API url */
            
            let headers: HTTPHeaders = [
                /* "Authorization": "your_access_token",  in case you need authorization header */
                "Content-type": "multipart/form-data",
                //"Bearer": pinfo.token ?? ""
            ]
            
            AF.upload(multipartFormData: { (multipartFormData) in
                let down = DownloadFileTask()
                let fn = down.getName(path: pinfo.path!)
                let data = down.localToData(filePath: pinfo.path!)
                //multipartFormData.append(data, withName: "image", fileName: "image.png", mimeType: "image/png")
                multipartFormData.append(data, withName: "file", fileName: fn, mimeType: "file/*")
                
            }, to: url, usingThreshold: UInt64.init(), method: .post, headers: headers).responseJSON(completionHandler: { (response) in
                
                if let err = response.error{
                    print(err)
                    result.success = false
                    result.error = err.localizedDescription
                    self.app21?.App21Result(result: result)
                    return
                }
                
                let json = response.value
                let jsonStr = String(data: response.data!, encoding: String.Encoding.utf8)

                if (json != nil)
                {
                    result.success = true;
                    result.data = JSON(jsonStr) ;//JSON(json!)
                    self.app21?.App21Result(result: result)
                }
            })
        }
        catch{
            
        }
    }
    
}
class PostInfo : Codable{
    var server: String?;
    var path: String?;
    var token: String?;
}
