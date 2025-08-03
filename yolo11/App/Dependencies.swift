//
//  Dependencies.swift
//  yolo11
//
//  Created by tim on 2025/8/3.
//

import Foundation

// 依赖注入管理器
@Observable
class Dependencies {
    static let shared = Dependencies()
    
    private init() {}
    
    // 在这里添加应用所需的共享依赖
    // 例如：用户管理器、网络服务等
}