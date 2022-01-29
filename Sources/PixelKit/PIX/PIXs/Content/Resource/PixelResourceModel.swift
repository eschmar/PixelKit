//
//  File.swift
//  
//
//  Created by Anton Heestand on 2021-12-13.
//

import Foundation
import RenderKit

public typealias PixelResourceModel = PixelContentModel & NodeResourceContentModel

public struct PixelResourceModelDecoder {
    
    public static func decode(from decoder: Decoder, model: PixelResourceModel) throws -> PixelResourceModel {
        
        try PixelContentModelDecoder.decode(from: decoder, model: model) as! PixelResourceModel
    }
}
