# compose_collection
alias dcu='docker compose up -d'
alias dcb='docker compose build'
alias dcd='docker compose down'
alias dcl='docker compose logs'
alias dps='docker compose ps'
alias dce='docker compose exec'
alias dnet='docker network ls'
alias dclf='docker compose logs -f'
alias dneti='docker network inspect'
alias swarmkill='docker kill $(docker ps -q)'

# function_collection
function compose_ip() {
  container=$1
  docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container
}

function compose_shell() {
  container=$1
  shell_command=${2:-/bin/sh}  # Default to /bin/sh if no second argument is provided
  docker exec -it $(docker ps -qf "name=$container") $shell_command
}

function compose_inspect() {
  container=$1
  docker inspect $(docker ps -qf "name=$container")
}


