//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// An `Error` for an IO operation.
public struct IOError: Swift.Error {
    
    /// The `errno` that was set for the operation.
    public let errnoCode: Int32

    // TODO: Fix me to lazy create
    /// The actual reason (in an human-readable form) for this `IOError`.
    public let reason: String
    
    /// Creates a new `IOError``
    ///
    /// - parameters:
    ///       - errorCode: the `errno` that was set for the operation.
    ///       - reason: the actual reason (in an human-readable form).
    public init(errnoCode: Int32, reason: String) {
        self.errnoCode = errnoCode
        self.reason = reason
    }
}

/// Creates a new IOError for a function call
///
/// - parameters:
///       - errorCode: the `errno` that was set for the operation.
///       - function: the function / syscall that caused the error.
/// - returns: error that was created.
func ioError(errnoCode: Int32, function: String) -> IOError {
    return IOError(errnoCode: errnoCode, reason: reasonForError(errnoCode: errno, function: function))
}

/// Returns a reason to use when constructing a `IOError`.
///
/// - parameters:
///       - errorCode: the `errno` that was set for the operation.
///       - function: the function / syscall that caused the error.
/// -returns: the constructed reason.
private func reasonForError(errnoCode: Int32, function: String) -> String {
    if let errorDescC = strerror(errnoCode) {
        let errorDescLen = strlen(errorDescC)
        return errorDescC.withMemoryRebound(to: UInt8.self, capacity: errorDescLen) { ptr in
            let errorDescPtr = UnsafeBufferPointer<UInt8>(start: ptr, count: errorDescLen)
            return "\(function) failed: \(String(decoding: errorDescPtr, as: UTF8.self)) (errno: \(errnoCode)) "
        }
    } else {
        return "\(function) failed: Broken strerror, unknown error: \(errnoCode)"
    }
}

extension IOError {
    public var localizedDescription: String {
        return self.reason
    }
}

/// An result for an IO operation that was done on a non-blocking resource.
public enum IOResult<T> {
    
    /// Signals that the IO operation could not be completed as otherwise we would need to block.
    case wouldBlock(T)
    
    /// Signals that the IO operation was completed.
    case processed(T)
}
