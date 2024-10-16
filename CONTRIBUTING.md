# Contributing to Asis-coder

First off, thank you for considering contributing to Asis-coder! It's people like you that make Asis-coder such a great tool.

## Where do I go from here?

If you've noticed a bug or have a feature request, make sure to check our [Issues](https://github.com/johnolven/asis-coder/issues) page to see if someone else in the community has already created a ticket. If not, go ahead and [make one](https://github.com/johnolven/smart-cli/issues/new)!

## Fork & create a branch

If this is something you think you can fix, then [fork Asis-coder](https://help.github.com/articles/fork-a-repo) and create a branch with a descriptive name.

A good branch name would be (where issue #325 is the ticket you're working on):

```sh
git checkout -b 325-add-japanese-localization
```

## Get the test suite running

Make sure you're using the latest version of Bash (4.0 or higher). Then, run the test suite to ensure everything is working correctly:

```sh
./run_tests.sh
```

## Implement your fix or feature

At this point, you're ready to make your changes! Feel free to ask for help; everyone is a beginner at first.

## Get the style right

Your patch should follow the same conventions & pass the same code quality checks as the rest of the project. Run `shellcheck` on your code to catch common style issues:

```sh
shellcheck smart-cli.sh
```

## Make a Pull Request

At this point, you should switch back to your master branch and make sure it's up to date with Smart CLI's master branch:

```sh
git remote add upstream git@github.com:johnolven/smart-cli.git
git checkout master
git pull upstream master
```

Then update your feature branch from your local copy of master, and push it!

```sh
git checkout 325-add-japanese-localization
git rebase master
git push --set-upstream origin 325-add-japanese-localization
```

Finally, go to GitHub and [make a Pull Request](https://help.github.com/articles/creating-a-pull-request) :D

## Keeping your Pull Request updated

If a maintainer asks you to "rebase" your PR, they're saying that a lot of code has changed, and that you need to update your branch so it's easier to merge.

To learn more about rebasing in Git, there are a lot of [good](https://git-scm.com/book/en/v2/Git-Branching-Rebasing) [resources](https://www.atlassian.com/git/tutorials/merging-vs-rebasing) but here's the suggested workflow:

```sh
git checkout 325-add-japanese-localization
git pull --rebase upstream master
git push --force-with-lease 325-add-japanese-localization
```

## Merging a PR (maintainers only)

A PR can only be merged into master by a maintainer if:

* It is passing CI.
* It has been approved by at least two maintainers. If it was a maintainer who opened the PR, only one extra approval is needed.
* It has no requested changes.
* It is up to date with current master.

Any maintainer is allowed to merge a PR if all of these conditions are met.
