//
//  LoggingSystem+LoggingSystemRepository.swift
//  FelinePine
//
//  Created by Leo Dion.
//  Copyright © 2024 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import FelinePine
import Foundation
public import Logging

// swiftlint:disable strict_fileprivate
private class LoggingSystemRepository: @unchecked Sendable {
  fileprivate static let shared = LoggingSystemRepository()

  private let lock = NSRecursiveLock()
  private var items = [String: Any]()

  private init(items: [String: Any] = [String: Any]()) {
    self.items = items
  }

  fileprivate func loggingSystem<LoggingSystemType: FelinePine.LoggingSystem>(
      for system: LoggingSystemType.Type,
      using value: @autoclosure () -> [LoggingSystemType.Category: Logging.Logger]
  ) -> [LoggingSystemType.Category: Logging.Logger] {
      let anyItem = lock.withLock {
        items[system.identifier]
      }
    if let item = anyItem as? [LoggingSystemType.Category: Logging.Logger] {
        return item
      } else {
        assert(anyItem == nil)
        return lock.withLock {
          let value = value()
          items[system.identifier] = value
          return value
        }
      }
    }
}

// swiftlint:enable strict_fileprivate

extension FelinePine.LoggingSystem {
  // swiftlint:disable:next missing_docs
  public static var identifier: String {
    String(reflecting: Self.self)
  }

  /// By default, this is `Bundle.main.bundleIdentifier`.
  public static var subsystem: String {
      identifier
  }
}


extension FelinePine.LoggingSystem where Category: CaseIterable {
  private static var loggers: [Category: Logging.Logger] {
      LoggingSystemRepository.shared.loggingSystem(
        for: Self.self,
        using: defaultLoggers()
      )
    }

    /// If ``Category`` implements `CaseIterable`, ``LoggingSystem`` can automatically
    /// iterate over the cases and automatically create the ``Logger`` objects needed.
  public static func loggingLogger(forCategory category: Category) -> Logging.Logger {
      guard let logger = loggers[category] else {
        preconditionFailure("missing logger")
      }
      return logger
    }

  private static func defaultLoggers() -> [Category: Logging.Logger] {
      .init(
        uniqueKeysWithValues: Category.allCases.map {
          ($0, Logger(subsystem: Self.subsystem, category: $0))
        }
      )
    }
  }
