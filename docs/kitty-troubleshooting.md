# Kitty Terminal - Troubleshooting Guide

**Date**: 2025-10-23
**Issue**: Kitty terminal emulator not launching
**Status**: ✅ RESOLVED

## Problem Description

Kitty terminal was failing to launch with the following errors:
```
[0.124] [glfw error 65540]: Invalid window size 0x0
[0.127] OSError: Failed to create GLFWwindow. This usually happens because of old/broken OpenGL drivers.
```

Additionally, a configuration warning was present:
```
[0.065] Ignoring unknown config key: window_padding_height
```

## Root Cause Analysis

### Primary Issue: Invalid Window Dimensions
The configuration file (`~/.config/kitty/kitty.conf`) had invalid window size settings:

**File**: `~/.config/kitty/kitty.conf:51-52`
```conf
initial_window_width  0
initial_window_height 0
```

Setting window dimensions to `0` caused GLFW to fail window creation, which in turn triggered the misleading OpenGL error. The OpenGL error was a **consequence** of the invalid window size, not an actual graphics driver problem.

### Secondary Issue: Unknown Configuration Key
**File**: `~/.config/kitty/kitty.conf:54`
```conf
window_padding_height 4
```

The config key `window_padding_height` does not exist in Kitty. The correct approach is to use `window_padding_width` which controls both horizontal and vertical padding.

## Solution

Updated the window layout configuration in `~/.config/kitty/kitty.conf`:

**Before**:
```conf
remember_window_size  no
initial_window_width  0
initial_window_height 0
window_padding_width 4
window_padding_height 4
```

**After**:
```conf
remember_window_size  yes
initial_window_width  1200
initial_window_height 800
window_padding_width 4
```

### Changes Made:
1. Set `initial_window_width` to `1200` (valid dimension)
2. Set `initial_window_height` to `800` (valid dimension)
3. Changed `remember_window_size` to `yes` (allows Kitty to remember user-resized dimensions)
4. Removed invalid `window_padding_height` key

## Verification

After applying the fix:
- Kitty launches successfully
- Window is created with proper dimensions
- No critical errors in output
- Minor informational warnings remain (systemd scope, bash HISTCONTROL) but do not affect functionality

## System Information

- **OS**: Linux 6.8.0-85-generic (Ubuntu)
- **Kitty Version**: 0.43.1
- **Graphics**: Intel TigerLake-LP GT2 [Iris Xe Graphics]
- **Installation**: `~/.local/kitty.app/`
- **Configuration**: `~/.config/kitty/kitty.conf`

## Key Takeaways

1. **Misleading Error Messages**: The OpenGL error was misleading - the actual issue was window sizing, not graphics drivers
2. **Configuration Validation**: Always verify configuration keys against official documentation
3. **Zero-Value Parameters**: Using `0` for window dimensions will cause window creation to fail
4. **Window Size Management**: Using `remember_window_size yes` provides better UX by remembering user preferences

## Related Documentation

- [Kitty Configuration Reference](https://sw.kovidgoyal.net/kitty/conf/)
- [Kitty Window Layout Settings](https://sw.kovidgoyal.net/kitty/conf/#window-layout)

## References

Configuration file location: `~/.config/kitty/kitty.conf:49-54`
