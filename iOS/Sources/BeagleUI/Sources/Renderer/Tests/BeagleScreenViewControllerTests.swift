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

import XCTest
@testable import BeagleUI
import SnapshotTesting

final class BeagleScreenViewControllerTests: XCTestCase {
    
    func test_onViewDidLoad_backGroundColorShouldBeSetToWhite() {
        // Given
        let component = SimpleComponent()
        let sut = Beagle.screen(.declarative(component.content.toScreen()))
        
        // When
        sut.viewDidLoad()
        
        // Then

        // TODO: uncomment this when using Xcode > 10.3 (which will support iOS 13)
        // if #available(iOS 13.0, *) {
        //    XCTAssertEqual(sut.view.backgroundColor, .systemBackground)
        // } else {
            XCTAssertEqual(sut.view.backgroundColor, .white)
        // }
    }
    
    func test_onViewWillAppear_navigationBarShouldBeHidden() {
        // Given
        let component = SimpleComponent()
        let sut = Beagle.screen(.declarative(component.content.toScreen()))
        let navigation = UINavigationController(rootViewController: sut)
        
        // When
        sut.viewWillAppear(false)
        
        // Then
        XCTAssertTrue(navigation.isNavigationBarHidden)
    }
    
    func test_whenLoadScreenFails_itShouldCall_didFailToLoadWithError_onDelegate() {
        // Given
        let url = "www.something.com"
        let networkStub = NetworkStub(
            componentResult: .failure(.networkError(NSError()))
        )
        
        let delegateSpy = BeagleScreenDelegateSpy()
        
        _ = BeagleScreenViewController(viewModel: .init(
            screenType: .remote(.init(url: url)),
            dependencies: BeagleScreenDependencies(
                network: networkStub
            ),
            delegate: delegateSpy
        ))
        
        // Then
        XCTAssertTrue(delegateSpy.didFailToLoadWithErrorCalled)
    }
    
    func test_handleSafeArea() {
        let sut = safeAreaController(content: Text(""))
        assertSnapshotImage(sut, size: CGSize(width: 200, height: 200))
    }
    
    func test_handleKeyboard() {
        let sut = safeAreaController(
            content: Text(
                "My Content",
                alignment: .center,
                appearance: .init(backgroundColor: "#00FFFF"),
                flex: Flex(grow: 1)
            )
        )
        
        let image = UIImage(named: "keybaord", in: Bundle(for: BeagleScreenViewControllerTests.self), compatibleWith: nil)
        let keyboard = UIImageView(image: image)
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        keyboard.sizeToFit()
        keyboard.backgroundColor = .black
        keyboard.alpha = 0.8
        
        sut.view.addSubview(keyboard)
        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: sut.view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: sut.view.trailingAnchor),
            keyboard.bottomAnchor.constraint(equalTo: sut.view.bottomAnchor)
        ])
        
        postKeyboardNotification()
        assertSnapshotImage(sut, size: CGSize(width: 414, height: 896))
    }
    
    private func safeAreaController(content: ServerDrivenComponent) -> UIViewController {
        let screen = Screen(
            appearance: Appearance(backgroundColor: "#0000FF"),
            navigationBar: NavigationBar(title: "Test Safe Area"),
            child: Container(
                children: [content],
                flex: Flex(grow: 1, margin: .init(all: .init(value: 10, type: .real))),
                appearance: Appearance(backgroundColor: "#00FF00")
            )
        )
        let screenController = Beagle.screen(.declarative(screen))
        screenController.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        let navigation = UINavigationController(rootViewController: screenController)
        navigation.navigationBar.barTintColor = .white
        navigation.navigationBar.isTranslucent = true
        screenController.viewWillAppear(false)
        
        let label = UILabel()
        label.text = "Safe Area"
        label.textAlignment = .center
        label.backgroundColor = UIColor.yellow.withAlphaComponent(0.4)
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.red.cgColor
        label.translatesAutoresizingMaskIntoConstraints = false
        screenController.view.addSubview(label)
        
        let guide = screenController.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: guide.topAnchor),
            label.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        return navigation
    }
    
    func postKeyboardNotification() {
        let notification = Notification(
            name: NSNotification.Name.UIKeyboardWillChangeFrame,
            object: nil,
            userInfo: [
                UIKeyboardAnimationDurationUserInfoKey: 0,
                UIKeyboardIsLocalUserInfoKey: 1,
                UIKeyboardAnimationCurveUserInfoKey: 7,
                UIKeyboardFrameBeginUserInfoKey: CGRect(x: 0, y: 896, width: 414, height: 346),
                UIKeyboardFrameEndUserInfoKey: CGRect(x: 0, y: 550, width: 414, height: 346)
            ]
        )
        NotificationCenter.default.post(notification)
    }
    
    func test_whenLoadScreenSucceeds_itShouldSetupTheViewWithTheResult() {
        // Given
        let viewToReturn = UIView()
        viewToReturn.tag = 1234

        let loaderStub = NetworkStub(
            componentResult: .success(SimpleComponent().content)
        )

        let dependencies = BeagleDependencies()
        dependencies.network = loaderStub

        let sut = BeagleScreenViewController(viewModel: .init(
            screenType: .remote(.init(url: "www.something.com")),
            dependencies: dependencies
        ))

        assertSnapshotImage(sut, size: CGSize(width: 50, height: 25))
    }
    
    func test_loadPreFetchedScreen() {
        
        let url = "screen-url"
        let cache = CacheManager(maximumScreensCapacity: 30)
        cache.saveComponent(Text("PreFetched Component", appearance: .init(backgroundColor: "#00FF00")), forPath: url)
        let network = NetworkStub(componentResult: .success(Text("Remote Component", appearance: .init(backgroundColor: "#00FFFF"))))
        let dependencies = BeagleDependencies()
        dependencies.cacheManager = cache
        dependencies.network = network
        
        let screen = BeagleScreenViewController(viewModel: .init(
            screenType: .remote(.init(url: url, fallback: nil)),
            dependencies: dependencies
        ))
        
        assertSnapshotImage(screen, size: CGSize(width: 100, height: 75))
    }
    
    func test_whenLoadScreenFails_itShouldRenderFallbackScreen() {
        let delegate = BeagleScreenDelegateSpy()
        let error = Request.Error.networkError(NSError(domain: "test", code: 1, description: "Network Error"))
        let network = NetworkStub(componentResult: .failure(error))
        let fallback = Text(
            "Fallback screen.\n\(error.localizedDescription)",
            appearance: .init(backgroundColor: "#FF0000")
        ).toScreen()
        let dependencies = BeagleDependencies()
        dependencies.network = network
        
        let screen = BeagleScreenViewController(viewModel: .init(
            screenType: .remote(.init(url: "url", fallback: fallback)),
            dependencies: dependencies,
            delegate: delegate
        ))
        XCTAssertNotNil(delegate.errorPassed)
        assertSnapshotImage(screen, size: CGSize(width: 300, height: 100))
    }

    func test_whenLoadScreenWithDeclarativeText_isShouldRenderCorrectly() throws {

        let json = try jsonFromFile(fileName: "declarativeText1")
        let screen = BeagleScreenViewController(viewModel: .init(screenType: .declarativeText(json)))

        assertSnapshotImage(screen, size: CGSize(width: 256, height: 512))
    }

    func test_whenReloadScreenWithDeclarativeText_isShouldRenderCorrectly() throws {

        let json = try jsonFromFile(fileName: "declarativeText2")

        let screen = BeagleScreenViewController(viewModel: .init(screenType: .declarative(Screen(child: Container(children: [])))))
        screen.reloadScreen(with: .declarativeText(json))

        assertSnapshotImage(screen, size: CGSize(width: 256, height: 512))
    }
}

// MARK: - Testing Helpers

struct SimpleComponent {
    var content = Container(children:
        [Text("Mock")]
    )
}
final class BeagleScreenDelegateSpy: BeagleScreenDelegate {
    
    private(set) var didFailToLoadWithErrorCalled = false
    private(set) var viewModel: BeagleScreenViewModel?
    private(set) var errorPassed: ViewModel.State.Error?
    
    func beagleScreen(viewModel: BeagleScreenViewModel, didFailToLoadWithError error: ViewModel.State.Error) {
        didFailToLoadWithErrorCalled = true
        self.viewModel = viewModel
        errorPassed = error
    }
}
