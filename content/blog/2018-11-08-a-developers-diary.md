+++
title="A Developer's Diary: Building A Notes Taking App in Shell"
slug="a-developers-diary-building-a-notes-taking-app-in-shell"
date = 2018-11-08
description="I'm used to recording all the little things I learn from day to day as a developer. Since I didn't find the right note-taking tool to integrate in my daily routine, I coded it. Read on to see what I learned in the process."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["console"]
[extra]
marmelab="https://marmelab.com/blog/2018/11/08/a-developers-diary.html"
+++

Something I really like about being a developer is that you learn all the time: a pattern, a lib, an obscure configuration trick... In the heat of the action, you're glad, but a few days later, you often forget. It is at these time that you think it would have been a good idea to take notes.

I've already tried some notepads: [jrnl](http://jrnl.sh/), but I've never been able to remember the commands, [boostnote](https://boostnote.io/) that I don't use when I code because it's an extra window, or [gist](https://gist.github.com/) but I can't keep it organized...

And this summer, I received this link ["did.txt file"](https://theptrk.com/2018/07/11/did-txt-file/) file in my [changelog](https://changelog.com/) newsletter.

## did.txt

Here is how [Patrick](https://theptrk.com/about/) introduces his blog post:

> Goal: create an insanely simple “did” file accessible by terminal

And that's right, it's very simple (it's just adding an alias in your `.bash_profile` or `.zshrc`) and bloody effective :

```bash
alias did="vim +'normal Go' +'r!date' ~/did.txt"
```

A `did` command opens a file into the terminal - so you don't leave your working environment - with the current date. All you have to do is write down this little thing you've just learned.

![did : the original](/images/blog/dev-diary/did_init.gif)

And I really liked the idea of having a new tool built only with what is already present on the system. But in fact, it's a little too simple. For example, here is what happens if you use did twice on the same day:

![Maybe too simple](/images/blog/dev-diary/did_init_pbl.gif)

Two problems made me think that I would not integrate this command as it stands in my daily routine:

- **All notes are in a single file**, and because did is a daily note-taking tool, this file may become too long to be usable. The point of taking notes is to be able to read them again!
- **The file is in `.txt` format**, which severely limits the possibilities of formatting, such as code extracts.

This post documents how I customized this good idea to my needs. I tried to keep the same simplicity as the original did and continuing to use only what was already available in the terminal.

## One logbook per week

I work in a two-week time box (sprint), so cutting the single file into several weekly logbooks was obvious.

I'll not go into the implementation's details, but show you the (almost) final result. The `--help` option, `man` and Google were my friends to get this result.

```bash
export DID_PATH=~/.did

function did(){
    export LC_ALL=C
    if [ ! -f ${DID_PATH}/$(date +%Y-%V).txt ]; then
        echo "Week $(date +"%V (%B %Y)") \n\n$(date +"%A %Y-%m-%d")" > ${DID_PATH}/$(date +%Y-%V).txt
    fi
    FILE_EDITION_DATE="$(stat -c "%y" ${DID_PATH}/$(date +%Y-%V).txt)"
    NOW="$(date +"%Y-%m-%d")"
    if [ ${FILE_EDITION_DATE:0:10} != ${NOW} ]; then
        echo "\n$(date +"%A %Y-%m-%d")\n" >> ${DID_PATH}/$(date +%Y-%V).txt
    fi
    unset LC_ALL
    vim +'normal Go' ${DID_PATH}/$(date +%Y-%V).txt
}
```

Here are the points that seem important to me.

- **A function rather than an alias**: with the introduction of a logic `if the log exists, then, else`, it was necessary to replace the simple alias by a shell function. `if [ ! -f ${DID_PATH}/$(date +%Y-%V).txt ]; then`

- **The `date` command**: it's the command I've tested the most. Here it's simply used to format the current date. For example `date +%Y-%V`.

- **The `stat` command**: it allows to retrieve a lot of information about a file, such as the date of the last modification `stat -c "%y" ${DID_PATH}/$(date +%Y-%V).txt`. This is what allowed me to know if the file had already been edited in the day or not, to decide whether or not to add this date when the logbook file is open.

- **The terminal locale**: the `date` command is sensitive to the terminal locale. So I had months and days in French. Yep, my system is in french! To be able to keep my notes in English, it was necessary to change the terminal locale during the execution of the command with `LC_ALL=C`.

- **The environment variable `DID_PATH`**: this variable is very logical. It simplifies script writing and allows to easily change the storage folder. But it has a great side effect: by using [direnv](https://direnv.net/), it will allow you to create a logbook per project!

![the new did](/images/blog/dev-diary/did.gif)

This new command gets the job done since now it creates one file per week instead of a single file. But this improvement would also be a good example for David Kadavy's article ["Complexity is creepy: It’s never just one more thing”](https://medium.com/@kadavy/complexity-is-creepy-its-never-just-one-more-thing-79a6a89192db).

Indeed, my *one more thing* brings its share of questions:

- With the original `did`, I always opened the same file. But now `did` opens the current week's logbook. **How will I view my notes from last week?**
- If I want to open a past logbook, **how will I know which ones exist**?
- With the original `did`, I could do a search with `vim` inside my single file. But now, **how am I going to find a note through all logbooks?**

## View a specific logbook : didv (view)

```bash
function didv(){
    if [ $1 ]
    then
         cat ${DID_PATH}/${1}.txt
    else
        if [ ! -f ${DID_PATH}/$(date +%Y-%V).txt ]; then
            LC_ALL=C echo "# Week $(date +"%V (%B %Y)") \n\n## $(date +"%A %Y-%m-%d")" > ${DID_PATH}/$(date +%Y-%V).txt
        fi
        cat ${DID_PATH}/$(date +%Y-%V).txt
    fi
}
```

This function is simpler than `did`'s, but it introduces the use of command arguments: `if [ $1 ]`. `didv` opens the current log and `didv 2018-32` the log for week 32.    
`cat` is in charge of displaying the file.

![Display logbooks with didv](/images/blog/dev-diary/didv_txt.gif)

## List weekly logbooks: didl (list)

I thought that setting up the list of logs would be the fastest feature to set up. I pragmatically tested the `ls` and `tree` commands :

![list logs with ls and tree](/images/blog/dev-diary/ls_tree.gif)

But two things bothered me:

- I didn't want to display the file extension (for example I want `2018-32` instead of `2018-32.txt`),
- I wanted to display the month corresponding to the week number to make the list more readable.

[Display the month as from the week number](https://en.wikipedia.org/wiki/ISO_week_date#Calculating_the_week_number_of_a_given_date) with `date` has been the most complicated part of that `did` improvement day!

```bash
function week2Month(){
    export LC_ALL=C
    year=$(echo $1 | cut -f1 -d-)
    week=$(echo $1 | cut -f2 -d-)
    local dayofweek=1 # 1 for monday
    date -d "$year-01-01 +$(( $week * 7 + 1 - $(date -d "$year-01-04" +%w ) - 3 )) days -2 days + $dayofweek days" +"%B %Y"
    unset LC_ALL
}

function didl(){
    for file in `ls ${DID_PATH}/*.txt | sort -Vr`; do
        filenameRaw="$(basename ${file})"
        filename="${filenameRaw%.*}"
        echo "${filename} ($(week2Month ${filename}))"
    done
}
```

![didl](/images/blog/dev-diary/didl.gif)

## Search the weekly logbooks: dids (search)

And here we are at the last feature to implement: search the logs. It's `grep` that is involved.

```bash
function dids(){
    export LC_ALL=C
    if [ $1 ]
    then
        for file in `ls ${DID_PATH}/*.txt | sort -Vr`; do
            NB_OCCURENCE="$(grep -c @${1} ${file})"
            if [ ${NB_OCCURENCE} != "0" ]
            then
                filenameRaw="$(basename ${file})"
                filename="${filenameRaw%.*}"
                echo -e "\n\e[32m=> ${filename} ($(week2Month ${filename}), ${NB_OCCURENCE} results) \e[0m" && grep -n -B 1 ${1} ${file}
            fi
        done
    else
         echo "You must add a something to search..."
    fi
    export LC_ALL=C
}
```

To be able to tag notes and limit the search to these tags, I decided to use a tag's prefix `@`, allowing to do `NB_OCCURENCE="$(grep -c @${1} ${file})"`. The second use of `grep` no longer uses this prefix, allowing to display all the lines corresponding to the searched word.

![dids](/images/blog/dev-diary/dids_tag.gif)

## Formatting notes

I was close to the goal! I no longer had one, but 4 commands:

- `did` to open the current logbook on the current date;
- `didv` to view a logbook including the former ones,
- `didl` to list all available logbooks in a readable way,
- `dids` to do a search in all the logs.

Only one point was still pending:

> The file is in.txt format, which severely limits the possibilities of formatting, such as code extracts.

A markup language is perfectly adapted for that: [**markdown**](https://www.markdownguide.org/).

![Markdown everywhere](/images/blog/dev-diary/markdown.jpg)

No luck, there's no basic tool in the terminal to process and display a `.md` file. However, I had set myself a rule:

> *"..., and continuing to use only what was already available in the terminal."*

It doesn't matter, I'm a punk. 

So I found some projects that met the need :

- [Pandoc et Lynx](https://tosbourn.com/view-markdown-files-terminal/)
- [mdv](https://github.com/axiros/terminal_markdown_viewer)
- [vmd](https://github.com/cpascoe95/vmd)

I preferred the `vmd` rendering. All that remained was to modify all the `.txt` to `.md`, add some `#` and replace `cat` by `vmd` in the `didv` function.

![didv in markdown](/images/blog/dev-diary/didv_markdown.gif)

## The final scripts

`gist:alexisjanvier/bfe71d18f68434e29c08637e4d837c74`

## Conclusion

I don't know if my scripts can be useful to you. If so, I would be happy to. Otherwise, I would also be happy anyway.

Because it's not the script that's important here. What I would like to have shared in this post is the pleasure of building your own little tool from what is available on your system. It's really very fun! During that day spent modifying the original did.txt, I learned a lot, tested a lot and came up with a result that was exactly what I needed. No more, no less.   
It was a bit of a **low-dev**. I'm very sensitive to [**low-tech**](https://www.arte.tv/fr/videos/RC-016865/les-escales-de-l-innovation/RC-014864/nomade-des-mers-les-tutos/) these days.

So I hope this reading has given you some ideas. As far as I'm concerned, I think I'm going to quickly add a `didp` command.

Did you guess it? `p` for publishing! Now that I have log books in markdown, it shouldn't be very complicated to publish them on a server, and then add a search engine like [Algolia](https://www.algolia.com/products/search) to index them.
