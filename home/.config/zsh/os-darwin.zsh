# macOS — pbcopy/pbpaste already exist; initialize Homebrew before mise.
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

# Drop stale interpreter-specific paths left behind by package upgrades, then
# provide the macOS certificate bundle as the baseline. The local overlay may
# replace it with a valid certifi/corporate-CA bundle.
[[ -n "$SSL_CERT_FILE" && ! -f "$SSL_CERT_FILE" ]] && unset SSL_CERT_FILE
[[ -z "$SSL_CERT_FILE" && -f /etc/ssl/cert.pem ]] && export SSL_CERT_FILE=/etc/ssl/cert.pem
