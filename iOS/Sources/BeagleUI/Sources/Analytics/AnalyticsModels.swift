/*
 * Copyright 2020 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

public protocol AnalyticsEvent: Codable { }

public struct AnalyticsClick: AnalyticsEvent {
    
    public let category: String
    public let label: String?
    public let value: String?
    
    public init(
        category: String,
        label: String? = nil,
        value: String? = nil
    ) {
        self.category = category
        self.label = label
        self.value = value
    }
}

public struct AnalyticsScreen: AnalyticsEvent {
    public let screenName: String
    
    public init(screenName: String) {
        self.screenName = screenName
    }
}
