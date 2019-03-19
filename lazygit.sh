# half-baked script meant to automate the horror that is using crap old git at work
# if repo exists: pulls remote -> if not up-to-date after pull, deletes and re-clones repo, checks out branch
# looks for repo in dir containing script, also logs there
# cleans up all existing logs if used with --cleanup
# currently verified: pull, clone, cleanup
gitlog="gitlog"
logfile="${gitlog}_$(date +"%m_%d_%Y").txt"
repo="<repo>"
repo_path="/<path>"
logpath=$repo_path$logfile
branch="master"
clone_ssh='git clone <repo address>'

delete_repo () {
cd $repo_path
rm -rf "${repo_path}${repo}/*" &>> $logpath
wait
if [ ! -d $repo ]
    then
    echo $(date +%H:%M) - $repo deleted
    echo '' >> $logpath
    verifydelete=true
else
    echo error deleting repository, aborting >> $logpath
    echo '' >> $logpath
    echo $(date +%H:%M) - error deleting repository, see $logpath
    echo '' >> $logpath
    verifydelete=false
fi
if [[ verifydelete = true ]]
    then
    echo clone repository? y/n
    read cloneconfirm
    if [[ $cloneconfirm = "y" ]]
        then
        unset cloneconfirm
        clone_repo
    fi
fi
}

clone_repo () {
echo $(date +%H:%M) - cloning repo | tee -a $logpath
echo '' >> $logpath
cd $repo_path
eval ${clone_ssh} >> $logpath 2>&1
if [ -d $repo ]
    then
    echo $(date +%H:%M) - $repo cloned | tee -a $logpath
    echo '' >> $logpath
    cd $repo
    git checkout $branch >> $logpath 2>&1
    currentbranch=$(git branch | grep \* | tail -c +3)
    if [[ $currentbranch = $branch ]]
        then
        echo $(date +%H:%M) - $branch checked out | tee -a $logpath
        echo '' >> $logpath
    else
        echo $(date +%H:%M) - $branch checkout unsuccessful. currently on branch $currentbranch | tee -a $logpath
        echo '' >> $logpath
    fi
else
    echo $(date +%H:%M) - error $repo not cloned | tee -a $logpath
    echo '' >> $logpath
fi
}

sync_repo () {
if [[ $gitstatus = *"ahead"* ]]
    then
    head=$(git log origin/R6/9.0/master | head -1 | tail -c +8)
    echo WARNING: | tee -a $logpath
    echo $gitstatus | tee -a $logpath
    echo ""
    echo "Reset HEAD to $head"
elif [[ $gitstatus = *"detached"* ]]
    then
    echo head is detached. attempting to check out specified branch. | tee -a $logpath
    echo '' >> $logpath
    git checkout $branch >> $logpath 2>&1
    echo '' >> $logpath
    gitstatus=$(git status | sed -n 2p)
    if [[ $gitstatus = *"up to date"* ]]
    then
        echo $(date +%H:%M) - checkout successful. repo is up-to-date. | tee -a $logpath
        echo '' >> $logpath
    else
        echo checkout failed. delete repo? y/n
        echo '' >> $logpath
        read deleteconfirm
        if [[ $deleteconfirm = y ]]
            then
            echo "deletion confirmed" >> $logpath
            echo '' >> $logpath
            delete_repo
        else
            echo $(date +%H:%M) - aborting | tee -a $logpath
            echo '' >> $logpath
        fi
    fi
fi
}

pull_repo () {
echo $(date +%H:%M) - pulling remote | tee -a $logpath
echo '' >> $logpath
cd $repo_path/$repo
git pull >> $logpath 2>&1
echo '' >> $logpath
gitstatus=$(git status | sed -n 2p)
echo $gitstatus >> $logpath
echo "" >> $logpath
if [[ $gitstatus = *"up to date"* ]]
    then
    echo $(date +%H:%M) - repo up-to-date | tee -a $logpath
    echo '' >> $logpath
    else
    echo $(date +%H:%M) - pull failed | tee -a $logpath
    echo '' >> $logpath
    if [[ $gitstatus = *"ahead"* ]] || [[ $gitstatus = *"detached"* ]]
        then 
        echo $(date +%H:%M) - WARNING, local out of sync | tee -a $logpath
        echo ''
        echo ****************************************
        echo $gitstatus
        echo ****************************************
        echo ''

    echo delete repo y/n
    read deleteconfirm
    echo repo deletion confirmed by user >> $logpath
    echo '' >> $logpath
    if [[ $deleteconfirm = y ]]
    then
        delete_repo
        if [[ $verifydelete = true ]]
            then
            clone_repo
        fi
        unset verifydelete

    fi
    unset deleteconfirm
    echo 
fi
fi
}

create_log () {
    echo "" >> $logpath
    echo "LOG FOR $(date +%H:%M) RUN" >> $logpath
    echo "" >> $logpath
}

if [[ $1 = "--remove" ]] || [[ $1 = "-r" ]]
    then
    create_log
    delete_repo
    echo "logged under $logpath"
elif [[ $1 = "--help" ]] || [[ $1 = "-h" ]]
    then
    echo "Usage: gitforlazy.sh [OPTION]"
    echo "Creates a specified repository, or if one exists, makes it up-to-date."
    echo ""
    echo "   -h, --help          shows this printout"
    echo "   -r, --remove        deletes the specified repository"
    echo "   -c, --cleanup       removes the existing logfiles"
    echo ""
else
    create_log
    cd $repo_path
    if [ -d $repo ]
        then
        pull_repo
    else
        echo $(date +%H:%M) - no local repo found, cloning remote | tee -a $logpath
        echo '' >> $logpath
        echo ''
        clone_repo
    fi
    echo "logged under $repo_path$logfile"
fi

if [[ $1 = "--cleanup" ]] || [[ $1 = "-c" ]]
    then
    echo $(date +%H:%M) - deleting logs
    echo '' >> $logpath
    rm $repo_path/$gitlog*
fi
