// Copyright (c) 2017 Spotify AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
@testable import SpotifyLogin

class SpotifyLoginTests: XCTestCase {
    
    func testURLParsing() {
        let urlBuilder = URLBuilder(clientID: "id",
                                    clientSecret: "secret",
                                    redirectURL: URL(string: "spotify.com")!,
                                    showDialog: false)
        // Parse valid url
        let validURL = URL(string: "scheme://?code=spotify")!
        let parsedValidURL = urlBuilder.parse(url: validURL)
        XCTAssertFalse(parsedValidURL.error)
        XCTAssertEqual(parsedValidURL.code, "spotify")
        // Parse invalid url
        let invalidURL = URL(string: "http://scheme")!
        let parsedInvalidURL = urlBuilder.parse(url: invalidURL)
        XCTAssertTrue(parsedInvalidURL.error)
        XCTAssertNil(parsedInvalidURL.code)
    }
    
    func testCanHandleURL() {
        let urlBuilder = URLBuilder(clientID: "id",
                                    clientSecret: "secret",
                                    redirectURL: URL(string: "spotify://")!,
                                    showDialog: false)
        // Handle valid URL
        let validURL = URL(string: "spotify://")!
        XCTAssertTrue(urlBuilder.canHandleURL(validURL))
        // Handle invalid URL
        let invalidURL = URL(string: "http://spotify.com")!
        XCTAssertFalse(urlBuilder.canHandleURL(invalidURL))
    }
    
    func testAuthenticationURL() {
        let urlBuilder = URLBuilder(clientID: "id",
                                    clientSecret: "secret",
                                    redirectURL: URL(string: "spotify://")!,
                                    showDialog: false)
        let webAuthenticationURL = urlBuilder.authenticationURL(type: .web, scopes: [])
        XCTAssertNotNil(webAuthenticationURL)
        let appAuthenticationURL = urlBuilder.authenticationURL(type: .app, scopes: [.streaming])
        XCTAssertNotNil(appAuthenticationURL)
    }
    
    func testSessionValid() {
        let user = createMockUser()
        let validSession = Session(user: user,
                                   accessToken: "accessToken",
                                   refreshToken: "refreshToken",
                                   expirationDate: Date(timeIntervalSinceNow: 100))
        XCTAssertTrue(validSession.isValid())
        let invalidSession = Session(user: user,
                                     accessToken: "accessToken",
                                     refreshToken: "refreshToken",
                                     expirationDate: Date(timeIntervalSinceNow: -100))
        XCTAssertFalse(invalidSession.isValid())
    }
    
    func testUser() {
        let testUser = createMockUser()
        let session = Session(user: testUser,
                              accessToken: "accessToken",
                              refreshToken: "refreshToken",
                              expirationDate: Date())
        SpotifyLogin.shared.session = session
        XCTAssertEqual(SpotifyLogin.shared.displayName, testUser.displayName)
    }
    
    func testGetToken() {
        let emptySessionExpectation = expectation(description: "token expectation")
        SpotifyLogin.shared.session = nil
        SpotifyLogin.shared.getAccessToken { (token, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(token)
            emptySessionExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        
        let unconfiguredSessionExpectation = expectation(description: "token expectation")
        let testToken = "fakeToken"
        let testUser = createMockUser()
        
        let tokenSession = Session(user: testUser,
                                   accessToken: testToken,
                                   refreshToken: "refreshToken",
                                   expirationDate: Date.distantFuture)
        SpotifyLogin.shared.session = tokenSession
        SpotifyLogin.shared.getAccessToken { (_, error) in
            XCTAssertNotNil(error)
            unconfiguredSessionExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
        
        let validSessionExpectation = expectation(description: "configuration expectation")
        SpotifyLogin.shared.configure(clientID: "clientID",
                                      clientSecret: "clientSecret",
                                      redirectURL: URL(string: "spotify.com")!)
        SpotifyLogin.shared.getAccessToken { (token, error) in
            XCTAssertNil(error)
            XCTAssertEqual(token, testToken)
            validSessionExpectation.fulfill()
        }
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testLogout() {
        let testUser = createMockUser()
        let testSession = Session(user: testUser,
                                  accessToken: "testToken",
                                  refreshToken: "refreshToken",
                                  expirationDate: Date.distantFuture)
        SpotifyLogin.shared.session = testSession
        SpotifyLogin.shared.logout()
        XCTAssertNil(SpotifyLogin.shared.session)
    }
    
    // MARK: Helper methods
    
    func createMockUser(country: String = "US", displayName: String = "FakeUser", filterEnabled: Bool = true, profileUrl: String = "https://open.spotify.com/user/fakeuser", numberOfFollowers: Int = 20, endpointUrl: String = "https://api.spotify.com/v1/users/fakeuser", id: String = "12345") -> User {
        return User(country: country, displayName: displayName, filterEnabled: filterEnabled, profileUrl: profileUrl, numberOfFollowers: numberOfFollowers, endpointUrl: endpointUrl, id: id)
    }
    
}
