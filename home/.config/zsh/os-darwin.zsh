# mac-only — pbcopy/pbpaste already exist; brew shellenv.
# Handle both Apple Silicon (/opt/homebrew) and Intel (/usr/local) prefixes.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
alias open-here='open .'

# Cross-platform clipboard: copy/paste map to pbcopy/pbpaste on macOS.
alias copy='pbcopy'
alias paste='pbpaste'

# Baseline SSL cert bundle so Python requests/urllib3 and Node TLS have a CA
# file even on a fresh machine. The local overlay (local/zshrc.local) may
# override this with a certifi/corporate-CA bundle if needed.
[[ -z "$SSL_CERT_FILE" && -f /etc/ssl/cert.pem ]] && export SSL_CERT_FILE=/etc/ssl/cert.pem
