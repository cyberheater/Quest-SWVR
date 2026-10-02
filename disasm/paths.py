"""Project paths.  A missing input is reported by path; nothing searches for it."""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))
SRC_DIR = os.path.join(ROOT, "star-wars-main")
ROMS_DIR = os.path.join(ROOT, "roms")
BUILD = os.path.join(HERE, "build")

def need(path, what):
    if not os.path.exists(path):
        sys.exit("!! missing %s: %s" % (what, path))
    return path

def src(name):
    return need(os.path.join(SRC_DIR, name), "source archive file")

def build(name):
    os.makedirs(BUILD, exist_ok=True)
    return os.path.join(BUILD, name)
