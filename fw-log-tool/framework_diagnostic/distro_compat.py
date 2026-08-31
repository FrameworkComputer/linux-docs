"""
Framework device Linux distribution compatibility checking.
"""

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Optional


class SupportLevel(Enum):
    """Distribution support level."""
    OFFICIALLY_SUPPORTED = 'officially_supported'
    COMPATIBLE_COMMUNITY_SUPPORTED = 'community_supported'
    UNTESTED = 'untested'
    OUTDATED_NEEDS_UPDATE = 'outdated_needs_update'


@dataclass
class DistroInfo:
    """Linux distribution information."""
    id: str  # e.g., "fedora", "ubuntu"
    version: str  # e.g., "43", "24.04"
    pretty_name: str  # e.g., "Fedora Linux 43"


@dataclass
class CompatibilityResult:
    """Result of compatibility check."""
    support_level: SupportLevel
    model_name: str
    distro_info: DistroInfo
    recommendation: str = ""


# ===========================================================================
# COMPATIBILITY MATRICES
# ===========================================================================
#
# Source: https://frame.work/linux
#
# Format: model_name -> {distro_id: versions_list, ...}

# Framework Laptop 16 (AMD Ryzen AI 300) — kernel min 6.15
FRAMEWORK_LAPTOP_16_AI300 = {
    'model': 'Framework Laptop 16 (AMD Ryzen AI 300)',
    'kernel_min': '6.15',
    'kernel_rec': '6.15+',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 12 (13th Gen Intel Core) — kernel min 6.1
FRAMEWORK_LAPTOP_12 = {
    'model': 'Framework Laptop 12',
    'kernel_min': '6.1',
    'kernel_rec': '6.13+',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Desktop (AMD Ryzen AI Max 300) — kernel min 6.11
FRAMEWORK_DESKTOP = {
    'model': 'Framework Desktop',
    'kernel_min': '6.11',
    'kernel_rec': '6.15+',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 13 (AMD Ryzen AI 300) — kernel min 6.11
FRAMEWORK_LAPTOP_13_AI300 = {
    'model': 'Framework Laptop 13 (AMD Ryzen AI 300)',
    'kernel_min': '6.11',
    'kernel_rec': '6.15+',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 13 (Intel Core Ultra Series 1) — kernel min 6.8
FRAMEWORK_LAPTOP_13_INTEL_ULTRA = {
    'model': 'Framework Laptop 13 (Intel Core Ultra)',
    'kernel_min': '6.8',
    'kernel_rec': '6.12+',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 13 (AMD Ryzen 7040) — kernel min 6.6
FRAMEWORK_LAPTOP_13_AMD_7040 = {
    'model': 'Framework Laptop 13 (AMD Ryzen 7040)',
    'kernel_min': '6.6',
    'kernel_rec': '6.10+',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 16 (AMD Ryzen 7040) — kernel min 6.6
FRAMEWORK_LAPTOP_16 = {
    'model': 'Framework Laptop 16',
    'kernel_min': '6.6',
    'kernel_rec': '6.10+',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 13 (13th Gen Intel Core)
FRAMEWORK_LAPTOP_13_INTEL_13GEN = {
    'model': 'Framework Laptop 13 (13th Gen Intel)',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 13 (12th Gen Intel Core)
FRAMEWORK_LAPTOP_13_INTEL_12GEN = {
    'model': 'Framework Laptop 13 (12th Gen Intel)',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 13 (11th Gen Intel Core)
FRAMEWORK_LAPTOP_13_INTEL_11GEN = {
    'model': 'Framework Laptop 13 (11th Gen Intel)',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# --- New models ---

# Framework Laptop Pro (Intel Core Ultra 3 Series)
FRAMEWORK_LAPTOP_PRO_INTEL_ULTRA3 = {
    'model': 'Framework Laptop Pro (Intel Core Ultra 3 Series)',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop Pro (AMD Ryzen AI 300 Series)
FRAMEWORK_LAPTOP_PRO_AMD_AI300 = {
    'model': 'Framework Laptop Pro (AMD Ryzen AI 300 Series)',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}

# Framework Laptop 12 (Intel Core Ultra Series 3)
FRAMEWORK_LAPTOP_12_INTEL_ULTRA3 = {
    'model': 'Framework Laptop 12 (Intel Core Ultra Series 3)',
    'official': {'fedora': ['44+'], 'ubuntu': ['24.04+']},
}


def get_distro_info() -> Optional[DistroInfo]:
    """Read distribution information from /etc/os-release."""
    os_release = Path('/etc/os-release')
    
    if not os_release.exists():
        return None
    
    info = {}
    try:
        content = os_release.read_text()
        for line in content.split('\n'):
            if '=' in line:
                key, value = line.split('=', 1)
                info[key] = value.strip('"')
    except Exception:
        return None
    
    return DistroInfo(
        id=info.get('ID', 'unknown'),
        version=info.get('VERSION_ID', 'unknown'),
        pretty_name=info.get('PRETTY_NAME', 'Unknown Linux')
    )


def determine_framework_model(product_name: str, model_version: str, cpu_model: str = "") -> dict:
    """
    Determine which Framework model compatibility matrix to use.
    
    Args:
        product_name: From dmidecode system-product-name
        model_version: From dmidecode system-version
        cpu_model: CPU model string for disambiguation
    
    Returns:
        The appropriate compatibility matrix dict
    """
    combined = f"{product_name} {model_version}".lower()
    
    # Framework Laptop Pro (check before generic model matches).
    # Real DMI reports "Laptop 13 Pro"; the shorter "Laptop Pro" is also accepted.
    if 'laptop pro' in combined or 'laptop 13 pro' in combined:
        if 'ai 300' in cpu_model.lower() or 'ryzen ai' in combined:
            return FRAMEWORK_LAPTOP_PRO_AMD_AI300
        elif 'ultra' in cpu_model.lower() or 'core ultra' in combined:
            return FRAMEWORK_LAPTOP_PRO_INTEL_ULTRA3
    
    # Framework Laptop 12
    if 'laptop 12' in combined:
        if 'core ultra' in combined or 'ultra' in cpu_model.lower():
            return FRAMEWORK_LAPTOP_12_INTEL_ULTRA3
        return FRAMEWORK_LAPTOP_12
    
    # Framework Desktop
    if 'desktop' in combined:
        return FRAMEWORK_DESKTOP
    
    # Framework Laptop 16
    if 'laptop 16' in combined:
        if 'ai' in combined or 'ai 300' in cpu_model.lower():
            return FRAMEWORK_LAPTOP_16_AI300
        return FRAMEWORK_LAPTOP_16
    
    # Framework Laptop 13
    if 'laptop 13' in combined or 'framework' in combined:
        # Check CPU for disambiguation
        if 'ai 300' in cpu_model.lower() or 'ai' in combined:
            return FRAMEWORK_LAPTOP_13_AI300
        elif 'ultra' in cpu_model.lower() or 'core ultra' in combined:
            return FRAMEWORK_LAPTOP_13_INTEL_ULTRA
        elif '7040' in cpu_model or 'ryzen' in cpu_model.lower():
            return FRAMEWORK_LAPTOP_13_AMD_7040
        elif '13th gen' in combined or '-13' in cpu_model:
            return FRAMEWORK_LAPTOP_13_INTEL_13GEN
        elif '12th gen' in combined or '-12' in cpu_model:
            return FRAMEWORK_LAPTOP_13_INTEL_12GEN
        elif '11th gen' in combined or '-11' in cpu_model:
            return FRAMEWORK_LAPTOP_13_INTEL_11GEN
        elif 'core i' in cpu_model.lower():
            # Generic Intel — guess by CPU generation number if present
            return FRAMEWORK_LAPTOP_13_INTEL_13GEN
        
        # Default to the most recent/common
        return FRAMEWORK_LAPTOP_13_INTEL_13GEN
    
    # Unknown - return generic Laptop 13
    return FRAMEWORK_LAPTOP_13_INTEL_13GEN


def check_version_match(supported_versions: list[str], current_version: str) -> bool:
    """Check if current version matches any supported version.
    
    Supports:
      '*'     — any version (rolling releases)
      '24.04+' — 24.04 or newer (compares major.minor numerically)
      '43'    — exact match
    """
    if '*' in supported_versions:
        return True
    for sv in supported_versions:
        if sv.endswith('+'):
            # "24.04+" means >= 24.04
            try:
                min_parts = [int(x) for x in sv.rstrip('+').split('.')]
                cur_parts = [int(x) for x in current_version.split('.')]
                if cur_parts >= min_parts:
                    return True
            except (ValueError, AttributeError):
                continue
        elif sv == current_version:
            return True
    return False


def check_framework_distro_compatibility(
    product_name: str,
    model_version: str,
    cpu_model: str = ""
) -> Optional[CompatibilityResult]:
    """
    Check if the current distro is compatible with the Framework device.
    
    Args:
        product_name: From dmidecode system-product-name
        model_version: From dmidecode system-version
        cpu_model: CPU model for disambiguation
    
    Returns:
        CompatibilityResult or None if not a Framework device
    """
    # Check if this is a Framework device
    framework_indicators = ['Framework', 'Laptop Pro', 'Laptop 13', 'Laptop 16', 'Laptop 12', 'Desktop']
    if not any(ind in product_name for ind in framework_indicators):
        return None
    
    # Get current distro
    distro = get_distro_info()
    if distro is None:
        return None
    
    # Get the appropriate compatibility matrix
    compat_matrix = determine_framework_model(product_name, model_version, cpu_model)
    model_name = compat_matrix['model']
    
    # Global distro-support policy:
    #   Ubuntu/Fedora meeting the official floor -> officially supported
    #   Ubuntu/Fedora below the floor            -> outdated, needs update
    #   Everything else                          -> community supported
    if distro.id in ('ubuntu', 'fedora'):
        versions = compat_matrix.get('official', {}).get(distro.id, [])
        # Robust against missing/unparseable VERSION_ID (treat as community).
        try:
            parseable = bool([int(x) for x in distro.version.split('.')])
        except (ValueError, AttributeError):
            parseable = False
        
        if parseable and check_version_match(versions, distro.version):
            return CompatibilityResult(
                support_level=SupportLevel.OFFICIALLY_SUPPORTED,
                model_name=model_name,
                distro_info=distro
            )
        elif parseable:
            min_version = versions[0].rstrip('+') if versions else ""
            return CompatibilityResult(
                support_level=SupportLevel.OUTDATED_NEEDS_UPDATE,
                model_name=model_name,
                distro_info=distro,
                recommendation=(
                    f"Your {distro.id.title()} {distro.version} is older than the "
                    f"officially supported {distro.id.title()} {min_version}. "
                    f"Please update to the current release."
                )
            )
        # Unparseable version — fall through to community.
    
    # Every other distro (any id, any version) is community supported.
    return CompatibilityResult(
        support_level=SupportLevel.COMPATIBLE_COMMUNITY_SUPPORTED,
        model_name=model_name,
        distro_info=distro
    )


def format_compatibility_report(result: CompatibilityResult) -> list[str]:
    """Format compatibility result for the diagnostic report."""
    lines = []
    
    lines.append("Distribution Compatibility:")
    lines.append(f"  Device: {result.model_name}")
    lines.append(f"  Distribution: {result.distro_info.pretty_name}")
    
    if result.support_level == SupportLevel.OFFICIALLY_SUPPORTED:
        lines.append("  Status: ✅ Officially supported and tested")
    elif result.support_level == SupportLevel.COMPATIBLE_COMMUNITY_SUPPORTED:
        lines.append("  Status: 🔵 Community supported")
    elif result.support_level == SupportLevel.OUTDATED_NEEDS_UPDATE:
        lines.append("  Status: ⚠️  Update recommended")
        if result.recommendation:
            lines.append(f"  Note: {result.recommendation}")
    else:
        lines.append("  Status: ⚠️  Untested configuration")
        if result.recommendation:
            lines.append(f"  Note: {result.recommendation}")
    
    return lines

