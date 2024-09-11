#!/bin/bash

        review_team_slugs=()
        review_team_names=()
        while IFS='' read -r line; do review_team_slugs+=("$line"); done < <(gh pr view "$PR_NUMBER" --repo "$GITHUB_REPOSITORY" --json reviewRequests --jq '.reviewRequests[] | select(.__typename == "Team") | .slug')
        for t in "${review_team_slugs[@]}"; do
            tname=$(echo "$t" | cut -d'/' -f2-)
            review_team_names+=("${tname}")
        done
        REVIEW_TEAM_NAMES=$(IFS=,; echo "${review_team_names[*]}")
        echo "Teams assigned as reviewers: ${REVIEW_TEAM_NAMES}"
        echo "REVIEW_TEAM_NAMES=${REVIEW_TEAM_NAMES}" >> "$GITHUB_OUTPUT"

        echo

        IFS=, read -r -a review_team_names <<< "$REVIEW_TEAM_NAMES"
        for t in "${review_team_names[@]}"; do
            if [[ "${t}" == "${ADD_REVIEW_TEAM}" ]]; then
                echo "Leaving \"$t\" as reviewer"
            else
                echo "Removing team \"$t\" as reviewer"
                # gh api -X DELETE -H "Accept: application/vnd.github.v3+json" "/repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/requested_reviewers" -f "reviewers[]=" -f "team_reviewers[]=${t}" > /dev/null
            fi
        done

        echo

        # GHA condition: ${{ !contains(vars.REVIEW_TEAM_NAMES, vars.ADD_REVIEW_TEAM) }}
        if [[ "${REVIEW_TEAM_NAMES}" != *"${ADD_REVIEW_TEAM}"* ]]; then
            echo "Adding team \"$ADD_REVIEW_TEAM\" as reviewer"
            # Add: gh api -X POST -H "Accept: application/vnd.github.v3+json" "/repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/requested_reviewers" -f "reviewers[]=" -f "team_reviewers[]=${ADD_REVIEW_TEAM}"
        fi
