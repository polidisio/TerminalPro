# CLAUDE.md - TerminalPro

## Project Overview

**Name:** TerminalPro  
**Type:** iOS App (SwiftUI)  
**Description:** SSH client for iOS with full Linux command support. Aims to be a complete Linux terminal on mobile with PTY allocation for interactive commands (vim, htop, nano, less, mc).  
**Owner:** @polidisio  

## Tech Stack

- **Language:** Swift 5.0+
- **Framework:** SwiftUI + AppKit
- **Min iOS:** 16.0
- **SSH Library:** TBD (options: SwiftSH, SwiftNIO SSH, libssh2, or native ssh -t)
- **Architecture:** MVVM
- **Storage:** UserDefaults + Keychain (servers, history)
- **Build System:** CocoaPods (Podfile) or XcodeGen

## Quick Start

```bash
# Open in Xcode
open TerminalPro.xcworkspace

# Build (Cmd+R)
```

## File Structure

```
TerminalPro/
├── App/
│   └── TerminalProApp.swift       # App entry point
├── Components/                     # UI components
├── Models/                        # Data models
├── Services/                      # SSH services
│   ├── CitadelSSHService.swift
│   ├── KeychainService.swift
│   ├── SFTPService.swift
│   ├── SSHService.swift
│   ├── SessionManager.swift
│   ├── ServerStorage.swift
│   └── MockSSHService.swift
├── Shared/
├── ViewModels/
├── Resources/
├── Podfile (CocoaPods)
├── TerminalPro.xcodeproj
├── TerminalPro.xcworkspace
└── CLAUDE.md
```

## SSH Library Options

| Library | Pros | Cons |
|---------|------|------|
| **SwiftSH** (Recommended) | Pure Swift, async/await | Newer, less mature |
| **SwiftNIO SSH** | Apple official | Very complex |
| **libssh2** | Full feature support | C library binding |
| **Native ssh -t** | Simple, all features work | Device only |

## Architecture

### Pattern: MVVM
- Server management via KeychainService
- Session persistence in UserDefaults
- PTY allocation for interactive shell

## Features

- Full PTY support for interactive commands
- Server management (Keychain storage)
- Session history
- SFTP support
- ANSI color codes

## Important Rules

### Always Do
- Test on real device (SSH -t flag does not work on simulator)
- Use Keychain for credential storage

### Never Do
- Hardcode server credentials
- Log sensitive data

## Resources

- Token optimization tips: shared/claude-optimization-tips.md (Obsidian Vault)

---

**Owner:** Jose Maudisio (@polidisio)  
**Last updated:** 2026-04-24
