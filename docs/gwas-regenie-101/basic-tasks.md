---
layout: page
title: "Mastering the basic tasks"
parent: Beginners Guide
nav_order: 3
---

## Mastering the basic tasks
As mentioned in the beginning, I am working on a Windows computer, so I cannot run the pipeline locally. However, my institute has a Linux server on which Nextflow is installed. So the first steps for you are to 1) gain access to a server, a Linux computer that you can access remotely or a cluster and 2) ask the administrator to [install Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) on it (Version ≥ 22.10.04).

### Accessing a remote server

To access the server, you only need two programs: 1) a SSH client (I am using Windows PowerShell, it is usually pre-installed on Windows computers) to navigate within the server and to execute commands and 2) a so-called multi-platform FTP client (I am using FileZilla) to transfer files from your computer to the server and vice versa. To access the server with PowerShell you only have to type in `ssh USERNAME@SERVER`. After pressing enter you only have to type in your password, press enter again, and you are connected to the server. The same applies to the FTP client: Just put in server, username, password and port as they were given to you by the administrator.

### Getting accommodated with Linux/the command line

So with PowerShell you can now navigate within the server using `bash shell` commands. The system is organized as a tree-like file system with a root branching into different folders (Unix file system). There are a lot of great video tutorials and basic courses available for free, but to run the pipeline just reading the paragraph below will be enough.

Entering `pwd` will print the present working directory, `ls` will list the files and directories in the present working directory and `cd` will change your working directory. Just try them out, you cannot break anything :). If you don't put anything after `cd`, it will move you to your home directory (the working directory when you enter the server via PowerShell).

If you want to navigate to another folder, you can put an absolute or relative path after `cd`. For example: If `pwd` tells you that you are in `/home/myHome` and via `ls` you found out that in *myHome* there is the folder *Project1*, you can navigate there either by entering `cd Project1` (relative path) or `cd /home/myHome/Project1` (absolute path).

If you now want to navigate back to your *myHome* folder instead of using the absolute path you can also type in `cd ..` since this command always moves into the parent folder of your current location. One last command: Lets say you are in *myHome* and you want to create a new folder called *GWAS*. For this just enter `mkdir GWAS`.

If you now use `ls`, you should see the folder and you should be able to navigate there with `cd GWAS`.
