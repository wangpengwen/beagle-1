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

public class NetworkClientDefault: NetworkClient {

    public typealias Dependencies = DependencyUrlBuilder & DependencyLogger

    public var session = URLSession.shared
    let dependencies: Dependencies

    public var httpRequestBuilder = HttpRequestBuilder()
    public var cacheService = MemoryCacheService()

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    enum ClientError: Swift.Error {
        case invalidHttpResponse
        case invalidUrl
    }

    public func executeRequest(
        _ request: Request,
        completion: @escaping RequestCompletion
    ) -> RequestToken? {
        switch request.type {
        case .fetchComponent, .submitForm:
            return doRequest(request, completion: completion)
        case .fetchImage:
            break
        }

        if let cache = try? cacheService.loadData(from: request.url).get() {
            completion(.success(cache))
            return nil
        } else {
            return doRequest(request, completion: completion)
        }
    }

    @discardableResult
    private func doRequest(
        _ request: Request,
        completion: @escaping RequestCompletion
    ) -> RequestToken? {
        guard let url = dependencies.urlBuilder.build(path: request.url) else {
            dependencies.logger.log(Log.network(.couldNotBuildUrl(url: request.url)))
            completion(.failure(.init(error: ClientError.invalidUrl)))
            return nil
        }

        let build = httpRequestBuilder.build(
            url: url,
            requestType: request.type,
            additionalData: request.additionalData as? HttpAdditionalData
        )
                
        let urlRequest = build.toUrlRequest()

        let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            self.dependencies.logger.log(Log.network(.httpResponse(response: .init(data: data, reponse: response))))
            self.saveDataToCacheIfNeeded(data: data, request: request)
            completion(self.handleResponse(data: data, response: response, error: error))
        }
        dependencies.logger.log(Log.network(.httpRequest(request: .init(url: urlRequest))))

        task.resume()
        return task
    }

    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Swift.Error?
    ) -> NetworkClient.Result {
        if let error = error {
            return .failure(.init(error: error))
        }

        guard
            let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode),
            let data = data
        else {
            return .failure(NetworkError(error: ClientError.invalidHttpResponse))
        }

        return .success(data)
    }

    private func saveDataToCacheIfNeeded(data: Data?, request: Request) {
        guard case .fetchImage = request.type, let data = data else { return }
        cacheService.save(data: data, key: request.url)
    }
}

extension URLSessionDataTask: RequestToken { }
