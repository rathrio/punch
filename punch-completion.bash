function _punch_completion()
{
  local cur prev
  # Clear COMPREPLY.
  COMPREPLY=()

  # Get argument.
  cur="${COMP_WORDS[COMP_CWORD]}"

  # prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Complete long commands, like --brf, when tabbing after a '-'.
  if [[ ${cur} == -* ]] ; then
    COMPREPLY=( $(compgen -W "$(punch --options)" -- ${cur}) )
    return 0
  fi

  # Complete cards otherwise.
  COMPREPLY=( $(compgen -W "$(punch --cards)" -- ${cur}) )
  return 0
}
complete -F _punch_completion punch
