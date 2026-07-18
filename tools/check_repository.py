from pathlib import Path
import sys
import xml.etree.ElementTree as ET
import zipfile

REQUIRED = (
    "README.md",
    "model/npc_tl_psfb_cdr_final.slx",
    "scripts/run_all.m",
    "docs/design-report.pdf",
)
TEXT_SUFFIXES = {
    ".md", ".m", ".py", ".csv", ".cff", ".txt",
    ".json", ".yaml", ".yml", ".xml", ".prj",
}
_BACKSLASH = chr(92)
FORBIDDEN_TEXT = {
    "C:" + _BACKSLASH + "Users" + _BACKSLASH: "absolute path",
    "D:" + _BACKSLASH: "absolute path",
    "WeChat" + " " + "Files": "messaging path",
}
FORBIDDEN_PARTS = {"slprj", "__pycache__", ".pytest_cache"}
FORBIDDEN_SUFFIXES = {".slxc", ".asv", ".autosave", ".mat"}
PUBLIC_SLX_AUTHORS = {"", "Open Technical Project"}
SLX_AUTHOR_FIELDS = {"creator", "lastModifiedBy"}


def _scan_text(name: str, text: str) -> list[str]:
    text = text.replace("\\\\", "\\")
    return [f"{name}: contains {label}" for pattern, label in FORBIDDEN_TEXT.items()
            if pattern in text]


def _scan_slx_core_properties(name: str, text: str) -> list[str]:
    try:
        root = ET.fromstring(text)
    except ET.ParseError:
        return [f"{name}: invalid SLX core metadata"]

    errors: list[str] = []
    for element in root.iter():
        field = element.tag.rsplit("}", 1)[-1]
        value = (element.text or "").strip()
        if field in SLX_AUTHOR_FIELDS and value not in PUBLIC_SLX_AUTHORS:
            errors.append(f"{name}: contains non-public SLX author metadata ({field})")
    return errors


def audit(root: Path, require_layout: bool = True) -> list[str]:
    errors: list[str] = []
    if require_layout:
        errors.extend(f"missing required file: {name}" for name in REQUIRED
                      if not (root / name).is_file())
    for path in root.rglob("*"):
        if (not path.is_file() or ".git" in path.parts
                or "docs/superpowers" in path.as_posix()
                or ".superpowers" in path.parts):
            continue
        rel = path.relative_to(root).as_posix()
        if FORBIDDEN_PARTS.intersection(path.parts) or path.suffix.lower() in FORBIDDEN_SUFFIXES:
            errors.append(f"{rel}: generated or oversized artifact is not public")
            continue
        if path.suffix.lower() in TEXT_SUFFIXES:
            errors.extend(_scan_text(rel, path.read_text(encoding="utf-8", errors="ignore")))
        if path.suffix.lower() == ".slx":
            try:
                with zipfile.ZipFile(path) as archive:
                    for member in archive.namelist():
                        if member.endswith((".xml", ".rels", ".txt")):
                            text = archive.read(member).decode("utf-8", errors="ignore")
                            errors.extend(_scan_text(f"{rel}:{member}", text))
                            if member.replace("\\", "/").lower() == "metadata/coreproperties.xml":
                                errors.extend(_scan_slx_core_properties(
                                    f"{rel}:{member}", text
                                ))
            except (OSError, zipfile.BadZipFile):
                errors.append(f"{rel}: invalid SLX archive")
    return errors


if __name__ == "__main__":
    violations = audit(Path(__file__).resolve().parents[1])
    print("\n".join(violations) if violations else "Repository audit passed.")
    sys.exit(bool(violations))
