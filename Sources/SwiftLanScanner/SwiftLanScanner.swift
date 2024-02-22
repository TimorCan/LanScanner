//
//  SwiftLanScanner.swift
//  
//
//  Created by Dung Vu on 12/08/2023.
//

import Foundation
import LanScanner
import Combine
import Network

// MARK: -- Wrapper Code
public class SwiftLanScanner: NSObject {
    private static let shared = SwiftLanScanner()
    private lazy var _scanner = MMLANScanner(delegate: self)
    private lazy var monitor: NWPathMonitor = .init()
    private var _isScanning: Bool {
        _scanner?.isScanning ?? false
    }
    @Published private var _listDevice: [MMDevice] = []
    @Published private var _progress: Float = 0
    
    // MARK: -- API Information
    private struct API {
        static let key = "01h7m2b59pfxhmgbts56kv013y01h7m2btsc3dv6kqz0sw0qqkdpmhsfvk7sjpwy"
        static let baseURL = "https://api.maclookup.app/v2/macs/"
        
        struct Parameters {
            var macAddress: String
            func makeRequest() throws -> URLRequest {
                var components = URLComponents(string: API.baseURL + macAddress)
                components?.queryItems = [.init(name: "apiKey", value: API.key)]
                guard let url = components?.url else {
                    throw NSError(domain: NSURLErrorDomain, code: -1)
                }
                let req = URLRequest(url: url)
                return req
            }
        }
    }
    
    // MARK: -- Proceduce Log Information
    private struct Log {
        static func output(at f:String = #function, line: Int = #line, detail: Any...) {
            print("""
                  -----------------------
                  Log \(f) line: \(line):
                  Detail: \(detail)
                  -----------------------
                  """)
        }
    }
    
    /// Hide init avoid custom
    private override init() {
        super.init()
    }
    
    private func _start() {
        _listDevice = []
        _progress = 0
        monitor.pathUpdateHandler = { p in
            defer { self.monitor.cancel() }
            guard p.usesInterfaceType(.wifi) || p.usesInterfaceType(.wiredEthernet) else {
                Log.output(detail: "Not Connected: \(p)")
                return
            }
            self._scanner?.start()
        }
        monitor.start(queue: .global())
    }
    
    private func _stop() {
        self._scanner?.stop()
    }
    
    // MARK: -- Public Function
    /// State scan
    public static var isScanning: Bool {
        return shared._isScanning
    }
    
    /// Get progess scan
    public static var progress: AnyPublisher<Float, Never> {
        return shared.$_progress.eraseToAnyPublisher()
    }
    
    /// Get list device received
    public static var listDevice: AnyPublisher<[MMDevice], Never> {
        return shared.$_listDevice.eraseToAnyPublisher()
    }
    
    /// Start scan
    public static func start() {
        // Clear device
        shared._start()
    }
    
    
    /// Stop scan
    public static func stop() {
        shared._stop()
    }
    
    // MARK: - LookupAPIResponse
   public struct LookupAPIResponse: Codable {
        public let success, found: Bool?
        public let macPrefix, company, address, country: String?
        public let blockStart, blockEnd: String?
        public let blockSize: Int?
        public let blockType, updated: String?
        public let isRand, isPrivate: Bool?
        public let error: String?
        public let errorCode: Int?
        public let moreInfo: String?
    }
    
    // MARK: -- Request Information from API
    /// Request Information manufacture from macaddress of device
    /// - Parameter macaddress: String
    /// - Returns: Model has information include : url ,  relative ..
    public static func requestInformation(macaddress: String) async throws -> LookupAPIResponse {
        let p = API.Parameters(macAddress: macaddress)
        let response = try await URLSession.shared.data(for: try p.makeRequest())
        return try JSONDecoder().decode(LookupAPIResponse.self, from: response.0)
    }
}

// MARK: -- Delegate
extension SwiftLanScanner: MMLANScannerDelegate {
    public func lanScanDidFindNewDevice(_ device: MMDevice!) {
        guard let d = device else { return }
        
        var findIp = false
        
        for item in _listDevice{
            if item.ipAddress == d.ipAddress{
                findIp = false
            }
        }
           
        if !findIp {
            _listDevice.append(d)
        }
        
        
    }
    
    public func lanScanDidFinishScanning(with status: MMLanScannerStatus) {
        Log.output(detail: status)
    }
    
    public func lanScanDidFailedToScan() {
        Log.output(detail: "Fail Scan")
    }
    
    public func lanScanProgressPinged(_ pingedHosts: Float, from overallHosts: Int) {
        guard overallHosts > 0 else { return }
        _progress = pingedHosts / Float(overallHosts)
    }
}

