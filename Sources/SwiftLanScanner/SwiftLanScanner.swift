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
    public static var isScanning: Bool {
        return shared._isScanning
    }
    
    public static var listDevice: AnyPublisher<[MMDevice], Never> {
        return shared.$_listDevice.eraseToAnyPublisher()
    }
    
    public static func start() {
        // Clear device
        shared._start()
    }
    
    public static func stop() {
        shared._stop()
    }
}

// MARK: -- Delegate
extension SwiftLanScanner: MMLANScannerDelegate {
    public func lanScanDidFindNewDevice(_ device: MMDevice!) {
        guard let d = device, !_listDevice.contains(d) else { return }
        _listDevice.append(d)
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

