parameters="add your parameters here"
authid=`echo $parameters | grep -Eo 'auth_id=[0-9]*;' | grep -Eo '[0-9]*'`

function networkrequest() { # $1 = url
    url="$1"
    antics=`python3 bruhfei.py "$url" "$authid"`
    sign=`echo $antics | cut -f1 -d\|`
    currenttime=`echo $antics | cut -f2 -d\|`
    parameters=`echo $parameters | sed "s/-H 'sign: [0-9a-f]*:[0-9a-f]*:[0-9a-f]*:[0-9a-f]*'/-H 'sign: $sign'/g;s/-H 'time: [0-9]*'/-H 'time: $currenttime'/g"`
    eval "curl '$url' $parameters"
}

function list() { # $1 = artist id
    IFS=$'\n'
    cat /dev/null > result114514.txt
    cat /dev/null > debug114514.txt
    original=`networkrequest "https://.com/api2/v2/users/$1/posts/medias?limit=10&order=publish_date_desc&skip_users=all&format=infinite"`
    while [ `echo "$original" | grep -Fc '{"list":[],"hasMore":false}'` -eq 0 ]
    do
        num=0
        for singlepost in `echo "$original" | sed 's/{"list":\[//g;s/].*?$//g;s/],"hasMore".*$//g;s/},{"responseType"/}\n{"responseType"/g'`
        do
            # extract post id to mkdir and do other things
            echo "$singlepost" >> result114514.txt
            lastposttime=`echo "$singlepost" | grep -Eo '"postedAtPrecise":"[0-9]+.[0-9]+"' | sed 's/"$//g;s/^.*"//g'`
            let num++
            echo "post $num detected, last post time: $lastposttime"
        done
        original=`networkrequest "https://.com/api2/v2/users/$1/posts/medias?limit=10&order=publish_date_desc&skip_users=all&beforePublishTime=$lastposttime&counters=0&format=infinite"`
        echo "$original" >> debug114514.txt
    done
}

function dump() { # $1 = artist id
    IFS=$'\n'
    original=`networkrequest "https://.com/api2/v2/users/$1/posts/medias?limit=10&order=publish_date_desc&skip_users=all&format=infinite"`
    while [ `echo "$original" | grep -Fc '{"list":[],"hasMore":false}'` -eq 0 ]
    do
        num=0
        for singlepost in `echo "$original" | sed 's/{"list":\[//g;s/].*?$//g;s/],"hasMore".*$//g;s/},{"responseType"/}\n{"responseType"/g'`
        do
            id=`echo "$singlepost" | sed 's/,/\n/g' | grep '"id":' | head -1 | grep -Eo "[0-9]*"` # extract post id to mkdir and do other things
            # prepare for next post probably (convinced
            lastposttime=`echo "$singlepost" | grep -Eo '"postedAtPrecise":"[0-9]+.[0-9]+"' | sed 's/"$//g;s/^.*"//g'`
            let num++
            echo "post $num detected, id = $id, last post time: $lastposttime"
            echo "$lastposttime" > currentprogress
            
            # actual processing
            mkdir "$id"
            cd "$id"
            echo "$singlepost" > "$id.metadata.json"
            # insert process and download code here
            for media in `echo "$singlepost" | grep -Po '"media":\[.*?\]' | sed 's/},{/\n/g'`
            do
                echo "$media" | sed 's/,/\n/g' | grep source | sed 's/\\\//\//g;s/"/\n/g'  | grep http | sort | uniq >> list
            done
            aria2c -k 1M -x 128 -s 128 -j 64 -R -c --auto-file-renaming=false -i list
            rm list -f
            cd ..
            rar a -df -ep1 -htb -m0 -ma5 -rr5 -ts -tsp -ol "$id.rar" "$id"
            ~/singlefilediscordhosting.sh "$id.rar"
            rm "$id.rar" -f
        done
        original=`networkrequest "https://.com/api2/v2/users/$1/posts/medias?limit=10&order=publish_date_desc&skip_users=all&beforePublishTime=$lastposttime&counters=0&format=infinite"`
    done
}

dump "$1"
