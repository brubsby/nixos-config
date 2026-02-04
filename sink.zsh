sink() {
  local sync_git=true
  local args=()
  
  for arg in "$@"; do
    if [[ "$arg" == "--no-git" ]]; then
      sync_git=false
    else
      args+=("$arg")
    fi
  done
  
  # Reset positional parameters to the filtered list
  set -- "${args[@]}"

  local host="$1"
  # Get absolute path of local_dir, default to current directory
  local local_dir="${2:-.}"
  local_dir=$(realpath "$local_dir")
  
  # Default remote_dir to the same absolute path
  local remote_dir="${3:-$local_dir}"

  if [[ -z "$host" ]]; then
    echo "Usage: sink [--no-git] <host> [local_dir] [remote_dir]"
    return 1
  fi

  if [[ ! -d "$local_dir/.git" ]]; then
    echo -n "Directory '$local_dir' is not a git repository. Sync anyway? (y/N) "
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Aborted."
      return 1
    fi
  fi

  echo "Syncing $local_dir -> $host:$remote_dir..."
  
  local exclude_opts=(
    --exclude='node_modules'
    --exclude='target'
    --exclude='build'
    --exclude='dist'
    --exclude='__pycache__'
    --exclude='.venv'
  )

  if [[ "$sync_git" == "false" ]]; then
    exclude_opts+=(--exclude='.git')
  fi

  # Ensure trailing slash on source to sync contents, not the directory itself
  rsync -avz --mkpath "${exclude_opts[@]}" "$local_dir/" "$host:$remote_dir"
}