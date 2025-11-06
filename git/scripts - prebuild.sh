#!/bin/bash

# Create temporary directory for cloning
TEMP_DIR=$(mktemp -d)

# Base repository URL - adjust this to your Git server
BASE_REPO_URL="https://gitlab.xx.xx.xx/xx/"  # or your Git server URL

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <repo1>[=<branch1>] <repo2>[=<branch2>] ...

DESCRIPTION:
    Creates a merge request to trigger a rebuild for one or more repositories.
    If no branch is specified, uses the default branch (see --branch option).

OPTIONS:
    -h, --help              Show this help message and exit
    --branch=<branch>       Set default branch for all repos (default: 'develop')
    --automerge=<true|false> Enable/disable automerge (default: true)
                           Without this flag, automerge is skipped for 'stage' and 'production'

EXAMPLES:
    # Rebuild with default 'develop' branch
    $0 ms-tko ms-auth
    
    # Rebuild with specific branches
    $0 ms-tko=master ms-auth=dev ms-api=feature-branch
    
    # Use 'master' as default branch for multiple repos
    $0 --branch=master ms-tko ms-auth ms-api
    
    # Mix of default and specific branches
    $0 ms-tko ms-auth=master ms-api
    
    # Disable automerge
    $0 --automerge=false ms-tko ms-auth
    
    # Combine options
    $0 --branch=master --automerge=true ms-tko ms-auth

FORMAT:
    <repo>[=<branch>]
    
    - repo:   Repository name (required)
    - branch:  Target branch name (optional, uses --branch value or 'develop')

NOTES:
    - Requires 'glab' (GitLab CLI) to be installed and configured
    - Each repository will get a new branch with an empty commit
    - A merge request will be created from the new branch to the target branch
    - Automerge is skipped for 'stage' and 'production' unless --automerge=true is provided
EOF
    exit 1
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

# Default values
default_branch="develop"
automerge_enabled=true
automerge_flag_set=false

# Parse options
repos=()
for arg in "$@"; do
    case "$arg" in
        --branch=*)
            default_branch="${arg#*=}"
            ;;
        --automerge=true)
            automerge_enabled=true
            automerge_flag_set=true
            ;;
        --automerge=false)
            automerge_enabled=false
            automerge_flag_set=true
            ;;
        --*)
            echo "Error: Unknown option '$arg'"
            echo ""
            usage
            ;;
        *)
            repos+=("$arg")
            ;;
    esac
done

# Check if any repos provided
if [ ${#repos[@]} -eq 0 ]; then
    echo "Error: No repositories specified"
    echo ""
    usage
fi

# Process a single repository with one or more branches
# Clones the repo once, then sequentially processes each branch:
#   1. Create rebuild branch with empty commit
#   2. Push branch and create MR
#   3. Optionally enable automerge (with retry logic for pending pipelines)
process_repo() {
    local repo="$1"
    shift
    local branches=("$@")
    local prefix="[$repo]"

    if [ ${#branches[@]} -eq 0 ]; then
        echo "$prefix ✗ Error: No branches provided for repository"
        return 1
    fi

    # Create isolated workspace for this repo
    local repo_safe
    repo_safe=$(echo "$repo" | tr '/: ' '__-')
    local work_dir

    if ! work_dir=$(mktemp -d "$TEMP_DIR/${repo_safe}.XXXX"); then
        echo "$prefix ✗ Error: Failed to create temporary directory"
        return 1
    fi

    cd "$work_dir" || {
        echo "$prefix ✗ Error: Failed to enter temporary directory"
        return 1
    }

    # Clone repository (done once for all branches)
    local clone_url
    clone_url=$(echo "${BASE_REPO_URL}" | sed 's|/$||')/${repo}.git
    if ! git clone "$clone_url" >/dev/null 2>&1; then
        echo "$prefix ✗ Error: Failed to clone $repo"
        return 1
    fi

    cd "$repo" || {
        echo "$prefix ✗ Error: Repository directory missing after clone"
        return 1
    }

    # Prepare GitLab API paths for MR creation
    local group_path repo_path encoded_repo_path
    group_path=$(echo "$BASE_REPO_URL" | sed -E 's|https?://[^/]+/||' | sed 's|/$||' | sed 's|^/||')
    repo_path="${group_path}/${repo}"
    repo_path=$(echo "$repo_path" | sed 's|//|/|g')
    encoded_repo_path=$(echo "$repo_path" | sed 's|/|%2F|g')

    echo "$prefix Processing ${#branches[@]} branch(es)..."

    local repo_fail=0
    local branch_index=0

    # Process each branch sequentially within the same clone
    for branch in "${branches[@]}"; do
        branch_index=$((branch_index + 1))
        local branch_prefix="[$repo][$branch]"

        git fetch origin >/dev/null 2>&1 || true

        # Verify branch exists
        if ! git show-ref --verify --quiet refs/remotes/origin/"$branch"; then
            echo "$branch_prefix ✗ Error: Branch '$branch' does not exist in $repo"
            repo_fail=1
            continue
        fi

        # Checkout target branch
        if ! git checkout "$branch" >/dev/null 2>&1; then
            if ! git checkout -b "$branch" "origin/$branch" >/dev/null 2>&1; then
                echo "$branch_prefix ✗ Error: Failed to checkout branch '$branch' in $repo"
                repo_fail=1
                continue
            fi
        fi

        git pull origin "$branch" >/dev/null 2>&1 || true

        # Create rebuild branch with unique timestamp
        local timestamp rebuild_branch
        timestamp="$(date +%Y%m%d-%H%M%S)-$branch_index"
        rebuild_branch="rebuild/$branch-$timestamp"

        if ! git checkout -b "$rebuild_branch" >/dev/null 2>&1; then
            echo "$branch_prefix ✗ Error: Failed to create rebuild branch in $repo"
            repo_fail=1
            continue
        fi

        # Create empty commit to trigger rebuild
        if ! git commit --allow-empty -m "rebuild $branch" >/dev/null 2>&1; then
            echo "$branch_prefix ✗ Error: Failed to create empty commit in $repo"
            repo_fail=1
            continue
        fi

        if ! git push origin "$rebuild_branch" >/dev/null 2>&1; then
            echo "$branch_prefix ✗ Error: Failed to push rebuild branch to $repo"
            repo_fail=1
            continue
        fi

        echo "$branch_prefix Creating merge request..."

        # Determine automerge behavior based on branch and flags
        local use_automerge=false
        if [ "$automerge_enabled" = true ]; then
            if [[ "$branch" == "stage" ]] || [[ "$branch" == "production" ]]; then
                # Protected branches require explicit override
                if [ "$automerge_flag_set" = true ]; then
                    use_automerge=true
                fi
            else
                use_automerge=true
            fi
        fi

        # Create merge request
        local mr_output
        if mr_output=$(glab mr create \
            --repo "$repo_path" \
            --source-branch "$rebuild_branch" \
            --target-branch "$branch" \
            --title "Rebuild: $branch" \
            --description "Automated rebuild trigger for branch $branch" \
            --yes 2>&1); then
            
            # Enable automerge if requested
            if [ "$use_automerge" = true ]; then
                # Extract MR IID from output or API
                local mr_iid
                mr_iid=$(echo "$mr_output" | grep -oE 'merge_requests/[0-9]+' | head -1 | sed 's|merge_requests/||' || echo "")

                if [ -z "$mr_iid" ]; then
                    sleep 1
                    mr_iid=$(glab mr list --repo "$repo_path" --state opened --json iid -q ".[0].iid" --source-branch "$rebuild_branch" 2>/dev/null)
                fi

                if [ -n "$mr_iid" ] && [ "$mr_iid" != "null" ] && [ "$mr_iid" != "" ]; then
                    # Retry automerge enable (pipeline may not be ready immediately)
                    local max_automerge_attempts=12
                    local automerge_retry_delay=2
                    local attempt=1
                    local automerge_success=false

                    while [ $attempt -le $max_automerge_attempts ]; do
                        local automerge_output
                        if automerge_output=$(glab mr merge --repo "$repo_path" "$mr_iid" --auto-merge --remove-source-branch --yes 2>&1); then
                            automerge_success=true
                            break
                        fi

                        # If branch cannot be merged yet, wait and retry
                        if echo "$automerge_output" | grep -q "Branch cannot be merged"; then
                            local merge_status=""
                            if [ -n "$encoded_repo_path" ]; then
                                merge_status=$(glab api "/projects/$encoded_repo_path/merge_requests/$mr_iid" --jq '.detailed_merge_status' 2>/dev/null | tr -d '"')
                            fi

                            if [ $attempt -lt $max_automerge_attempts ]; then
                                sleep "$automerge_retry_delay"
                                attempt=$((attempt + 1))
                                continue
                            fi
                        else
                            echo "$branch_prefix   $automerge_output"
                            break
                        fi

                        echo "$branch_prefix   $automerge_output"
                        break
                    done

                    if [ "$automerge_success" != true ]; then
                        echo "$branch_prefix   ⚠ Could not automerge (may require additional permissions or pending pipeline)"
                        echo "$branch_prefix   ⚠ MR was created successfully without automerge"
                    fi
                else
                    echo "$branch_prefix   ⚠ Could not extract MR IID to enable automerge"
                    echo "$branch_prefix   ⚠ MR was created successfully without automerge"
                fi
            fi
        else
            echo "$branch_prefix ✗ Warning: Failed to create merge request, but branch was pushed"
            echo "$branch_prefix Error details:"
            echo "$mr_output" | sed "s/^/$branch_prefix   /"
            echo "$branch_prefix Troubleshooting:"
            echo "$branch_prefix   - Make sure 'glab' is authenticated: glab auth login"
            echo "$branch_prefix   - Verify glab is configured for this GitLab instance"
            echo "$branch_prefix   - Check if you have permissions to create MRs in this repo"
            echo "$branch_prefix   - Try running manually: cd $repo && glab mr create --source-branch $rebuild_branch --target-branch $branch"
            echo "$branch_prefix   - Or create the MR manually: ${BASE_REPO_URL}${repo}/-/merge_requests/new"
            repo_fail=1
            continue
        fi

        # Return to base branch for next iteration
        git checkout "$branch" >/dev/null 2>&1 || true
    done

    return $repo_fail
}

# Check if glab is available
if ! command -v glab &> /dev/null; then
    echo "Error: 'glab' command not found. Please install GitLab CLI."
    echo "Visit: https://gitlab.com/gitlab-org/cli"
    exit 1
fi

# Group branch requests per repository
# Format: repo1|branch1|branch2~~repo2|branch1 (use ~~ as repo separator, | as branch separator)
repo_list=""
unique_repos=()

for arg in "${repos[@]}"; do
    if [[ "$arg" == *"="* ]]; then
        IFS='=' read -r repo branch <<< "$arg"
    else
        repo="$arg"
        branch="$default_branch"
    fi

    if [ -z "$repo" ]; then
        echo "Error: Empty repo name"
        continue
    fi

    if [ -z "$branch" ]; then
        branch="$default_branch"
    fi

    # Check if repo already exists in unique_repos
    found=false
    for existing_repo in "${unique_repos[@]}"; do
        if [ "$existing_repo" = "$repo" ]; then
            found=true
            break
        fi
    done

    if [ "$found" = false ]; then
        # New repo
        if [ -n "$repo_list" ]; then
            repo_list+="~~"
        fi
        repo_list+="${repo}|${branch}"
        unique_repos+=("$repo")
    else
        # Add branch to existing repo
        repo_list+="|${branch}"
    fi
done

# Launch parallel jobs - one per unique repository
# Each job processes all branches for that repo sequentially
pids=()
pid_repos=()

IFS='~~' read -r -a repo_entries <<< "$repo_list"

for entry in "${repo_entries[@]}"; do
    IFS='|' read -r -a parts <<< "$entry"
    if [ ${#parts[@]} -ge 2 ]; then
        repo="${parts[0]}"
        branches=("${parts[@]:1}")
        process_repo "$repo" "${branches[@]}" &
        pids+=($!)
        pid_repos+=("$repo")
    fi
done

# Wait for all parallel jobs and collect results
overall_status=0
for idx in "${!pids[@]}"; do
    pid="${pids[$idx]}"
    repo="${pid_repos[$idx]}"
    if wait "$pid"; then
        echo "[$repo] ✓ Finished"
    else
        echo "[$repo] ⚠ Encountered errors"
        overall_status=1
    fi
done

# Cleanup temporary directory
rm -rf "$TEMP_DIR"

exit "$overall_status"
