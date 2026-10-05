#!/bin/zsh
# Builds two made-up repos (api-service, web-app) that show every kind of row,
# then starts git herd on them for a screenshot. Uses its own folders and
# settings under /tmp/git-herd-demo, so your real repos and picks are not used.
#
#   demo/make-demo.sh        build the demo and start git herd (q to quit)
#   demo/make-demo.sh -1     build the demo and print it once
set -e

herd=${0:A:h:h}/git-herd
demo=/tmp/git-herd-demo
mkdir -p $demo
demo=${demo:A}   # real path: /tmp is a symlink to /private/tmp on macOS
rm -rf $demo
mkdir -p $demo/code $demo/config/git-herd $demo/cache/git-herd/size
cd $demo

ago() { print "@$(( EPOCHSECONDS - $1 ))" }
zmodload zsh/datetime
commit() { GIT_AUTHOR_DATE=$(ago $2) GIT_COMMITTER_DATE=$(ago $2) git commit -q --allow-empty -m "$1" }
h=3600 d=86400
git() { command git -c user.name=Demo -c user.email=demo@example.com "$@" }

# api-service: a merged worktree, a worktree whose remote is gone with
# uncommitted files, a new branch, and main.
git init -q --bare -b main api.git
git clone -q api.git code/api-service 2>/dev/null
cd code/api-service
commit init $((9*d)); git push -q -u origin main 2>/dev/null; git remote set-head origin main
git switch -q -c feat/add-rate-limits; commit "rate limits" $((2*d))
git switch -q main; git merge -q --ff-only feat/add-rate-limits; commit release $h; git push -q 2>/dev/null
git switch -q -c fix/login-timeout main~1; commit "timeout fix" $((5*d))
git push -q -u origin fix/login-timeout 2>/dev/null; git switch -q main
git -C $demo/api.git branch -q -D fix/login-timeout; git fetch -q --prune
git branch feat/new-search
git worktree add -q ../api-service-rate-limits feat/add-rate-limits
git worktree add -q ../api-service-login-timeout fix/login-timeout
for f in a b c; do print x > ../api-service-login-timeout/$f.txt; done
cd $demo

# web-app: a branch with an approved PR, a stale branch, and main behind GitHub.
git init -q --bare -b main web.git
git clone -q web.git code/web-app 2>/dev/null
cd code/web-app
commit init $((60*d))
git switch -q -c spike/old-charts; commit "charts spike" $((42*d))
git switch -q main; commit ui $((3*h)); git push -q -u origin main 2>/dev/null; git remote set-head origin main
git switch -q -c feat/dark-mode; commit "dark mode" $((5*h)); git push -q -u origin feat/dark-mode 2>/dev/null
commit "dark mode 2" $((4*h)); commit "dark mode 3" $((3*h)); git switch -q main
git clone -q $demo/web.git $demo/teammate 2>/dev/null
for i in 1 2 3 4; do git -C $demo/teammate commit -q --allow-empty -m "teammate $i"; done
git -C $demo/teammate push -q 2>/dev/null; git fetch -q
cd $demo

# PR status and worktree sizes, as git herd's background refresh would save
# them. Dated in the future, so the demo never replaces them.
key() { print -r -- ${${1#/}//\//_} }
c=$demo/cache/git-herd
: >| $c/$(key $demo/code/api-service).prs; : >| $c/$(key $demo/code/api-service).prs.open
: >| $c/$(key $demo/code/web-app).prs
printf 'feat/dark-mode\t214\topen\tAPPROVED\tpass\thttps://github.com/example/web-app/pull/214\n' \
  >| $c/$(key $demo/code/web-app).prs.open
print 1468006 >| $c/size/$(key $demo/code/api-service-rate-limits)
print 2202009 >| $c/size/$(key $demo/code/api-service-login-timeout)
touch -t 203001010000 $c/*.prs* $c/size/*

print -l $demo/code/api-service $demo/code/web-app >| $demo/config/git-herd/repos

GIT_HERD_ROOTS=$demo/code XDG_CONFIG_HOME=$demo/config XDG_CACHE_HOME=$demo/cache \
  XDG_STATE_HOME=$demo/state GIT_HERD_NOTIFY=0 exec $herd "$@"
