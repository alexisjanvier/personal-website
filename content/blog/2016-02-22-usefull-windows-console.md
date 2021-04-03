+++
title="Is it snobbery to want a real console on Windows?"
slug="is-it-snobbery-to-want-a-real-console-on-windows"
date = 2016-02-22
description="Sometimes you have to code on Windows: this can be because of a personal challenge, or because you lost a bet, or because you don't have a choice. And it can be a bit painful when you are used to a powerful terminal. But some good solutions exist, as we'll see."
draft = false
in_search_index = true
[taxonomies]
categories = ["informatique"]
tags = ["console"]
[extra]
marmelab="https://marmelab.com/blog/2016/02/22/a-usefull-windows-console.html"
+++

I had to code on Windows because a client’s development environment could not be anything other than Windows 7 running in a VM (with admin’s rights, luckily), behind a non-cooperative firewall. The job consisted of a PHP Silex backend and a JavaScript frontend.

## Why did I have to find an alternative to Windows installers?

First, I installed Atom, by habit, even if I had never used it for PHP development.
Apart from a small initial worry (installing Atom requires .Net framework 4.5 which may be too big for my VM disk space), the official installer worked fine.
If you are behind a firewall, just remember to add or edit the file `.atom/.apmrc` if you want to add some plugins (atom-beautify, linter, linter-php,…).

``` sh
# $HOME/.atom/.apmrc

http-proxy = "http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT"
https-proxy = "http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT"
proxy = "http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT"
```

Next I switched to the PHP environment. The VM was delivered with Xampp. After adding PHP in the user path, I had access to PHP from the terminal, sorry, the **command prompt**.

![Add Php to your path](/images/blog/win_console_php_path.png)

That’s why I was self-confident when I tried the **Composer** Windows installer. Maybe too confident.

![Composer windows installer](/images/blog/win_console_error_composer_exe.png)

So, I tried to launch the installation from the command prompt, but without success.

![Composer install from cli](/images/blog/win_console_error_composer_cmd.png)

I decided to postpone **Composer**  to start the **Git** installation. Following my initial idea, I began with the official Github Tools. Although the installation worked fine, it was impossible to connect the Github servers. This was undoubtedly due to the Firewall.

In short, the morning began rather badly, and good jokes about Windows came back to my mind quickly.

## Babun

However, I seemed to remember a possible solution to my problem, a sort of nice Windows console promise that I had bookmarked somewhere… Thanks to [Raindrop](https://raindrop.io), I found this project: [Babun](http://babun.github.io/).

This is the official description:

> Would you like to use a Linux-like console on a Windows host without a lot of fuzz? Try out a babun!

Once the installation was completed without problems, I launched the `babun check` command, which reminded me that I was behind a firewall.

![Babun check fail](/images/blog/win_console_babun_check.png)

After a quick proxy configuration in the file `~/.babunrc`, everything seemed to work.

```
export http_proxy=http://LOGIN:PASSWORD@PROXY_URL:PROXY_PORT
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
export no_proxy=localhost
```

![Babun check success](/images/blog/win_console_babun_check_proxy.png)

So I continued with the PHP installation helped by Babun's package manager **Pact** (and by adding a file `~/.wgetrc` for registering the proxy path to the `wget` command, used sometimes by Pact), then Composer. Everything installed fine without any error.

Thanks to [Tomek Bujok](https://twitter.com/tombujok), I now have a functional PHP environment and a beautiful console already customised (git, zsh, oh-my-zsh…). I even recovered some .dotfiles (that you must convert in ISO 8859-1), added **tmux**, and it almost felt like being on my Mac.

 ![make under tmux](/images/blog/win_console_tmux_make.png)

## Yes, but

It was finally time to start coding: I typed `composer require silex`, and … ***ka-bun***.

 ![ka-bun](/images/blog/win_console_badabun.png)

I won't give any details on research carried out on what this tricky error was, but the conclusion was that the Cygwin version used by babun, the 32-bit version, was incompatible with the 64-bit Symantec Endpoint Protection installed on Windows...
It was not a problem, I just had to switch to the Cygwin in 64-bit. Except that this version is not, and will never be supported by Babun.

So, the only logical solution was to switch to a “standalone” [Cygwin](https://www.cygwin.com/) 64-bit version and forget Babun.
I did this, and in a short time I had a functional PHP environment, with composer, git, zsh, and tmux.

Babun is actually just an overlay of utilities and configurations over Cygwin. No, Cygwin does not have a package manager (you'll have to restart the windows installer if you forgot some packages), and must be customised by hand (export proxy, git configuration, zsh by default, …) but it does the job very well.

![Cygwin](/images/blog/win_console_cygwin.png)

## Conclusion

Nothing revolutionary in this blog post: Cygwin is already an old project. But it is certainly a tool to know, on a daily basis or not. Babun is a good project, which speeds up a beautiful console installation… as long as the cygwin 32-bit version is not a problem.

What is the connection between all this and snobbery?  Well, it turns out that this was a question (it was more an affirmation in fact) I was asked during my quest for a functional console.
The obvious answer was that without Cygwin, I could not install Composer. So, yes, I could have installed Silex with its dependencies by hand. But we are in 2016, and I'm not sure that my hourly rate is low enough to engage in such a waste of time. And more importantly, I have better things to do.

But I would like to close this post by giving a much better answer, read at the end of chapter **Orthogonality** from the book **The Pragmatic Programmer** written by **Andrew Hunt** and **David Thomas** :

   > Challenges : " Consider the difference between large GUI-oriented tools typically found on Windows systems and small but combinable command line utilities used at shell prompts. Which set is more orthogonal, and why? Which set is easier to combine with other tools to meet new challenges ? "
