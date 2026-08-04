#!/bin/bash

# Hook input is JSON from stdin
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name')
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only run for git commit commands
if [[ "$tool_name" != "Bash" ]] || [[ ! "$command" =~ git[[:space:]]+(commit|cherry-pick|merge|rebase) ]]; then
    exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 1

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  eval "$(rbenv init - bash)"
fi

echo "Running pre-commit checks..." >&2

# Regenerate RBS from scratch so that files orphaned by deleted lib/ sources are dropped too
if ! bundle exec rake rbs:regenerate >&2; then
    echo "Error: RBS generation failed" >&2
    exit 2
fi

# True when $command stages the whole of sig/ itself, which the check below cannot see because
# this hook runs first. Staging only part of sig/ does not count - the rest still drops out.
stages_sig() {
    local segment tokens token stages_everything pathspec_given

    while IFS= read -r segment; do
        segment=${segment//[\"\']/}
        read -ra tokens <<<"${segment#*add}"
        stages_everything=0
        pathspec_given=0

        for token in "${tokens[@]}"; do
            case "$token" in
                --) ;;
                -*A*|--all) stages_everything=1 ;;
                -*) ;;
                .|./|sig|sig/|./sig|./sig/) return 0 ;;
                *) pathspec_given=1 ;;
            esac
        done

        # -A alone stages every path; given a pathspec it stages that path only
        [ "$stages_everything" = 1 ] && [ "$pathspec_given" = 0 ] && return 0
    done < <(grep -oE '(^|[;&|(])[[:space:]]*git[[:space:]]+add[^;&|(]*' <<<"$command")

    return 1
}

# Stop rather than let the RBS just regenerated above drop out of the commit unnoticed
if [[ "$command" =~ git[[:space:]]+commit([[:space:]]|$) ]] && ! stages_sig; then
    unstaged_sig=$(git status --porcelain --untracked-files=all -- sig/ | awk 'substr($0, 2, 1) != " "')

    if [ -n "$unstaged_sig" ]; then
        echo "Error: sig/ has changes that are not staged:" >&2
        echo "$unstaged_sig" >&2
        echo "Run 'git add sig/' and commit again." >&2
        exit 2
    fi
fi

if ! bundle exec rake >&2; then
    echo "Error: rake checks failed" >&2
    exit 2
fi

echo "All checks passed!" >&2
exit 0
