import Foundation
import AppKit
import UniformTypeIdentifiers

// Author = "Inventions4All - github:TWeb79"

/// Helper for selecting folders via NSOpenPanel
struct FilePickerHelper {
    /// Open a folder selection panel
    /// - Parameter title: The title for the panel
    /// - Returns: The selected folder URL, or nil if cancelled
    static func selectFolder(title: String = "Select Folder") -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            return panel.url
        }
        
        return nil
    }
    
    /// Open a folder selection panel with validation
    /// - Parameters:
    ///   - title: The title for the panel
    ///   - mustExist: Whether the folder must already exist
    /// - Returns: The selected folder URL, or nil if cancelled
    static func selectFolder(title: String = "Select Folder", mustExist: Bool = true) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = !mustExist
        panel.prompt = "Select"
        
        if panel.runModal() == .OK {
            return panel.url
        }
        
        return nil
    }
    
    /// Validate that a path exists and is a directory
    /// - Parameter path: The path to validate
    /// - Returns: True if the path is a valid directory
    static func isValidDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /// Get the display name for a path
    /// - Parameter path: The path
    /// - Returns: The display name (last path component)
    static func displayName(for path: String) -> String {
        return URL(fileURLWithPath: path).lastPathComponent
    }
    
    /// Get the relative path from source to destination
    /// - Parameters:
    ///   - source: The source path
    ///   - destination: The destination path
    /// - Returns: The relative path
    static func relativePath(from source: String, to destination: String) -> String? {
        let sourceURL = URL(fileURLWithPath: source)
        let destinationURL = URL(fileURLWithPath: destination)
        
        guard let relativePath = sourceURL.pathComponents.last else { return nil }
        return relativePath
    }
    
    /// Check if rsync is available
    /// - Parameter path: Optional custom path to rsync
    /// - Returns: True if rsync is available at the given path
    static func isRsyncAvailable(at path: String = "/usr/bin/rsync") -> Bool {
        return FileManager.default.isExecutableFile(atPath: path)
    }
    
    /// Find rsync binary path
    /// - Returns: The path to rsync if found
    static func findRsyncPath() -> String {
        // Check default location first
        let defaultPath = "/usr/bin/rsync"
        if isRsyncAvailable(at: defaultPath) {
            return defaultPath
        }
        
        // Check Homebrew location
        let homebrewPath = "/opt/homebrew/bin/rsync"
        if isRsyncAvailable(at: homebrewPath) {
            return homebrewPath
        }
        
        // Check if it's in PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["rsync"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if isRsyncAvailable(at: output) {
                    return output
                }
            }
        } catch {
            // Ignore errors
        }
        
        // Return default path even if not found
        return defaultPath
    }
}