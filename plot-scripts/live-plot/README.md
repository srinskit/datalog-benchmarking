# Live Plot Setup

This script generates plots from log files with LaTeX formatting.

## Installation

**Python dependencies:**
```bash
pip3 install -r requirements.txt
```

**LaTeX:**
- **Ubuntu:** `sudo apt-get install texlive-latex-base texlive-latex-extra texlive-fonts-recommended`
- **macOS:** `brew install --cask mactex` or download from [MacTeX](https://www.tug.org/mactex/)

## Usage
```bash
python3 live-plot.py <log_files>
```

### Examples

**Plot all log files:**
```bash
python3 live-plot.py *.log
```

**Plot only Bipartite benchmark:**
```bash
python3 live-plot.py Bipartite*.log
```

**Plot specific benchmarks:**
```bash
python3 live-plot.py Galen*.log DOOP*.log
```

**Plot single benchmark comparison:**
```bash
python3 live-plot.py Bipartite_netflix_4_*.log
```
