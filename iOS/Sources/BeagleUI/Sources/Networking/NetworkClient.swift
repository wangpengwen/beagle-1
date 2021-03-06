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

public protocol NetworkClient {
    typealias Error = NetworkError
    typealias Result = BeagleUI.Result<Data, NetworkError>

    typealias RequestCompletion = (Result) -> Void

    @discardableResult
    func executeRequest(
        _ request: Request,
        completion: @escaping RequestCompletion
    ) -> RequestToken?
}

public struct NetworkError: Error {
    public let error: Error

    public init(error: Error) {
        self.error = error
    }
}

/// Token reference to cancel a request
public protocol RequestToken {
    func cancel()
}

public protocol DependencyNetworkClient {
    var networkClient: NetworkClient { get }
}
