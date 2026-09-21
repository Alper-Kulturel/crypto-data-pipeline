#!/bin/bash
# health_check.sh — verifies the whole quant dev environment
# Run: bash health_check.sh

echo "==============================================="
echo "ENVIRONMENT HEALTH CHECK"
echo "==============================================="
echo ""

# 1. Homebrew
echo "1. Homebrew:"
if command -v brew &>/dev/null; then
  echo "   ✅ $(brew --version | head -n1)"
else
  echo "   ❌ Homebrew NOT found"
fi
echo ""

# 2. pyenv
echo "2. pyenv:"
if command -v pyenv &>/dev/null; then
  echo "   ✅ $(pyenv --version)"
  echo "   Python versions: $(pyenv versions --bare | tr '\n' ' ')"
else
  echo "   ❌ pyenv NOT found"
fi
echo ""

# 3. Python
echo "3. Python (current):"
if command -v python &>/dev/null; then
  echo "   ✅ $(python --version 2>&1)"
  echo "   Location: $(which python)"
else
  echo "   ❌ python NOT found"
fi
echo ""

# 4. pip
echo "4. pip:"
if command -v pip &>/dev/null; then
  echo "   ✅ $(pip --version)"
else
  echo "   ❌ pip NOT found"
fi
echo ""

# 5. Key libraries
echo "5. Key Python libraries:"
python -c "
libs = ['numpy', 'pandas', 'scipy', 'statsmodels', 'sqlalchemy',
        'duckdb', 'websockets', 'loguru', 'dotenv', 'pytest']
import importlib
for lib in libs:
    try:
        mod = importlib.import_module(lib)
        ver = getattr(mod, '__version__', 'unknown')
        print(f'   ✅ {lib} {ver}')
    except Exception as e:
        print(f'   ❌ {lib}: {e}')
" 2>/dev/null || echo "   ❌ Python import test failed"
echo ""

# 6. Git
echo "6. Git:"
if command -v git &>/dev/null; then
  echo "   ✅ $(git --version)"
  echo "   User: $(git config --global user.name) <$(git config --global user.email)>"
else
  echo "   ❌ git NOT found"
fi
echo ""

# 7. Git repo status
echo "7. Git repo status:"
if [ -d ".git" ]; then
  echo "   ✅ Inside a git repo"
  echo "   Branch: $(git branch --show-current)"
  echo "   Remote: $(git remote get-url origin 2>/dev/null || echo 'none')"
  echo "   Status: $(git status --short | wc -l | tr -d ' ') changed files"
else
  echo "   ❌ Not a git repo"
fi
echo ""

# 8. SSH to GitHub
echo "8. SSH to GitHub:"
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" && \
  echo "   ✅ Authenticated" || \
  echo "   ❌ SSH not working (or key missing on GitHub)"
echo ""

# 9. VS Code
echo "9. VS Code:"
if command -v code &>/dev/null; then
  echo "   ✅ $(code --version | head -n1)"
else
  echo "   ❌ code command NOT found"
fi
echo ""

# 10. Docker
echo "10. Docker:"
if command -v docker &>/dev/null; then
  echo "   ✅ Docker CLI: $(docker --version)"
  if docker info &>/dev/null; then
    echo "   ✅ Docker daemon: running"
  else
    echo "   ❌ Docker daemon NOT running (open Docker Desktop)"
  fi
else
  echo "   ❌ Docker NOT found"
fi
echo ""

# 11. Docker containers
echo "11. Docker containers:"
if docker ps &>/dev/null; then
  running=$(docker ps --format '{{.Names}}' 2>/dev/null)
  if [ -z "$running" ]; then
    echo "   ⚠️  No containers running"
  else
    echo "   Running containers:"
    docker ps --format '   ✅ {{.Names}} ({{.Image}}) — {{.Status}}'
  fi
else
  echo "   ❌ Cannot query Docker"
fi
echo ""

# 12. PostgreSQL (if quant-pg is running)
echo "12. PostgreSQL (via quant-pg):"
if docker ps --format '{{.Names}}' | grep -q "quant-pg"; then
  if docker exec quant-pg psql -U quant -d marketdata -c "SELECT 1;" &>/dev/null; then
    echo "   ✅ Can query PostgreSQL"
    count=$(docker exec quant-pg psql -U quant -d marketdata -tAc "SELECT COUNT(*) FROM trades;" 2>/dev/null || echo "no trades table")
    echo "   Trades in DB: $count"
  else
    echo "   ❌ Container running but psql query failed"
  fi
else
  echo "   ⚠️  quant-pg container not running"
fi
echo ""

# 13. Internet / Binance reachable
echo "13. Internet (Binance):"
curl -s -o /dev/null -w "%{http_code}" https://api.binance.com/api/v3/ping 2>/dev/null | \
  grep -q "200" && echo "   ✅ Binance API reachable" || \
  echo "   ❌ Cannot reach Binance"
echo ""

echo "==============================================="
echo "Health check complete."
echo "==============================================="