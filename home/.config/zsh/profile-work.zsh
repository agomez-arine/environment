# Sourced only if ~/.config/environment/profile-work exists
export AWS_PROFILE=arine-dev
export ARINE_REPO="$HOME/arine-code"
[[ -d "$ARINE_REPO" ]] && alias ad='cd $ARINE_REPO'
