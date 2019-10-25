//
//  MyCache.swift
//  MyCache
//
//  Created by yoseph.savianto on 2019/10/25.
//  Copyright © 2019 yoseph.savianto. All rights reserved.
//

import UIKit

public final class MyCache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let keyObserver = KeyObserver()

    public init() {
        wrapped.delegate = keyObserver
    }

    public func set(_ value: Value, forKey key: Key, entryLifeTime: TimeInterval = 12 * 60 * 60) {
        let date = Date().addingTimeInterval(entryLifeTime)
        let entry = Entry(key: key, value: value, expirationDate: date)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keyObserver.keys.insert(key)
    }

    public func get(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else { return nil }
        guard Date() < entry.expirationDate else {
            remove(forKey: key)
            return nil }
        return entry.value
    }

    public func remove(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }

    public func removeAll() {
        wrapped.removeAllObjects()
    }

    public func hasCache(forKey key: Key) -> Bool {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else { return false }
        if Date() < entry.expirationDate {
            remove(forKey: key)
            return false
        }
        return true
    }
}

private extension MyCache {
    final class WrappedKey: NSObject {
        let key: Key
        init(_ key: Key) {
            self.key = key
        }
        override var hash: Int { return key.hashValue }
        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }
            return value.key == key
        }
    }
}

private extension MyCache {
    final class Entry {
        let key: Key
        let value: Value
        let expirationDate: Date
        init(key: Key,value: Value, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

private extension MyCache {
    subscript(key: Key) -> Value? {
        get { return get(forKey: key) }
        set {
            guard let value = newValue else {
                remove(forKey: key)
                return
            }
            set(value, forKey: key)
        }
    }
}

private extension MyCache {
    final class KeyObserver: NSObject, NSCacheDelegate {
        var keys = Set<Key>()
        func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
            guard let entry = obj as? Entry else {
                return
            }
            keys.remove(entry.key)
        }
    }
}

extension MyCache {
    /*
     WARNING: better use core data or any persistance framework out there
     TO DO: Still in development for saving to disk
     */
    private func saveToDisk (data: Data, key: String, fileManager: FileManager = .default) throws {
        let folderUrls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        if var fileUrl = folderUrls.first {
            fileUrl.appendPathComponent(key + ".cache")
            try data.write(to: fileUrl, options: .atomic)
        }
    }
}
