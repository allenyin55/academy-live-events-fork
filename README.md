# Creating Anyscale Platform Sessions for Live Academy Events

Dean Wampler, June 9, 2020

This README describes the process for setting up a live event.

The working assumption at this time is that you will create a single platform account, a single project, and one session _per attendee_. The `scripts` folder contains `zsh` scripts for this purpose.

> **WARNING:** The scripts are **not** `bash` compatible!

## End to End Testing

There is a `scripts/run-all.sh` script that can be used to run the entire setup sequence, in principle. See the section at the end of this README, _Using run-all.sh for End to End Testing_, for more details.

## Versioning This Repo

It's recommended to use the same version tags for this repo that are used for the Academy repo, so that you hopefully they are kept consistent.

## Setup Beforehand

In most of the command examples below, I'll assume your current working directory is the root directory of your local copy if the [`academy` repo](https://github.com/anyscale/academy). In some cases, I'll assume the [`academy-live-events` repo](https://github.com/anyscale/academy) is a sister directory, i.e.,:

```
/Users/me/work/academy
/Users/me/work/academy-live-events
```

### Download the Academy Repo

Download a version of the [Academy repo](https://github.com/anyscale/academy) that you want to teach. If you cloned the repo instead, I recommend copying it to another folder and deleting the `.git` directory, so it's not synched up to the sessions.

### Change to Your Working Directory

In what follows, you'll want to be in the project work directory from which the Academy will be synced, etc.

### Clean Up the Directory Tree

Remove all files you don't want in the sessions. In our very first live event, I accidentally left some files with attendee email addresses and other information in my work directory. We had to manually remove them from all the sessions at the last minute.

Run the script `tools/cleanup.sh` to see what temporary files exist, like checkpoints and caches, that you might want to delete. The following script will just delete them (be careful!!):

```shell
tools/cleanup.sh | while read x; do rm -rf $x; done
```

> **Note:** A feature is being added to the platform to provide a `.gitignore`-like functionality to prevent this problem.

### Copy the ray-project Folder

From the `academy-live-events` repo (i.e., where _this_ README lives), copy the `ray-project` folder here to the work (current) directory. I actually try to keep them in sync, but consider the `academy-live-events` to be _canonical_.

The following commands assume that the `academy-live-events` directory is a _sibling_ to your work directory. Edit to taste...


```shell
rm -rf ray-project
cp -r ../academy-live-events/ray-project ray-project
```

Edit the contents of `ray-project` to taste. In particular, consider the following:

1. Delete `ray-project/project-id` if any.
	* If you see a warning _This project has been registered by somebody else or has been deleted. Do you want to re-register it? [y/N]:_ when you run the the project create command below, it's because an old `project-id` file was found.
2. Pick a project name for the date or tutorial topic, e.g., `academy-2020-05-27`:
    * Change `cluster_name` in `cluster.yaml` to this name. **WARNING:** The current value is `anyscale-academy`, which is used in paths inside the `setup_commands`. You **must** find and change all occurrences consistently.
    * Change `name` in `project.yaml` to this name.
3. Adjust the instance type used, as necessary.
4. Change `max_workers` in `cluster.yaml` to be > 1, as necessary.
5. Make sure the `ray-projects/requirements.txt` file is equivalent to the `academy/requirements.txt` file. This ensures the proper `pip install ...` commands are run in the new cluster.

### Copy the scripts Folder

We don't really want the `scripts` to be pushed up to the head node, although it's mostly harmless. However, we need it in the work directory, so just copy the `academy-live-events/scripts` directory to the project work directory.

```shell
cp -r ../academy-live-events/scripts scripts
```

### Update the Anyscale Command

You **must** use the latest command, not necessarily because of any features it offers, but because it will warn you _incessantly_ that you need to update and those messages will mess up parsing the command output in the scripts used below.

```shell
pip install -U anyscale
```

## Create the Anyscale Platform Account

You may want to use a special account separate from your personal one, although I can't think of a good reason for doing this...

## Create the Project

Use the same name you used in the `cluster.yaml` and `project.yaml` files above:

```shell
anyscale init --requirements ray-project/requirements.txt
```

TODOs:

1. It appears that the `--requirements` argument is required, even though the file is in `ray-project`. Is this correct?
2. I'm now brute-force installing the conda environment I want; should I just skip my `requirements.txt` file?

This takes a while, as it makes a snapshot of up your local project directory!

> **TIP:** Note the UUID printed for the snapshot. This UUID is also shown in the https://anyscale.dev UI for your project.

When finished, open and navigate to your project. You'll probably find this useful to keep open:

```shell
open https://anyscale.dev
```

## Create the Sessions

At this time, we statically create a session for each registered attendee and mail access information to them individually. Eventually, we would like to do this more dynamically, so we don't have idle sessions for no-show people. Also, we create a few extra sessions in case an attendee has a serious problem with his/her session; we'll just provide a standby replacement.

Note that each session takes approximately 15-30 minutes to complete all the setup steps. As much as possible, we do things in parallel. For example, many of the scripts run commands in the background.

```shell
scripts/create-sessions.sh --snapshot id --name academy-user M N
```

The `--snapshot id` is optional, but it **significantly improves** the startup time, as it eliminates the creation of a snapshot of your local directory for **every, single session created.** Use the `id` printed when you created the project in the previous step.

The `--name academy-user` is optional. The value `academy-user` is actually the default value for a prefix used for every session name. (Note: this name is different from _project_ name used in the `anyscale init` command above). Hence, you can omit this option unless you want to use a different name. I'm showing it here and in subsequent commands for completeness. Each session will be given a name like `academy-user-001`.

The `M` is the minimum session number, defaulting to 1, and `N` is the maximum session number, also defaulting to 1. Both numbers are _inclusive_. If you only specify one of them, it is interpreted as the _maximum_ number with the minimum defaulting to 1. This script runs the following `anyscale` command N-M+1 times:

```shell
anyscale start --snapshot id --session-name academy-user-NNN
```

Where the default session name prefix `academy-user` is shown and `NNN` is a zero-padded number that makes the session name unique.

> **Note:** A lower-bound argument is supported so you can run this command as many times as necessary, starting where you "left off" from the last run.

By default, this command will creat a snapshot of your project _for every single session_ created, so expect to wait awhile. It's better to create one session, note the snapshot id, then run the script again, passing that value with the `--snapshot id` argument and the range `2 N`.

> **Tips:**
>
> 1. All the `scripts` have `--help` options.
> 2. The `ray-project/cluster.yaml` file has several post-install commands it runs.
> 3. It takes a _very long time_ for each session to initialize, about 8-10 minutes or sometimes longer.
> 4. Click the `logs` link for a session to see how it's doing.

TODO: Modify `create-sessions.sh` to capture the first snapshot already and pass it as an argument while creating the rest of the sessions.

## Fix the Sessions (Obsolete...)

Previously, it was necessary to perform this step, to do final changes to the session that could not be done by the `cluster.yaml` `setup_commands`. However, these issues are now resolved. This section is still here, in case a subsequent problem emerges. Note the next section _Check the Sessions_ should still be used to ensure the sessions are properly configured.

If the session checking shows problems, then run the following command:

```shell
scripts/fix-sessions.sh --name academy-user M N
```

Where again the `--name academy-user` is optional and the default value is shown.

> **Note:** There is also an optional `--project name` argument. By default, it uses the name for the project in `ray-project/cluster.yaml`. It must be the same name used above when creating the project. It's needed here for the `/usr/ubuntu/<project_name>` directory in the head node.

This script uses `anyscale ray exec-cmd` to run an Academy repo script `/usr/ubuntu/<project_name>/tools/fix-jupyter.sh` that will be on the head node by this point.

> **WARNING:** This script runs synchronously through each session, one at a time, to avoid stressing the Anyscale gateway.

## Check the Sessions (Optional)

A sanity check to make sure the Jupyter Lab extensions are properly installed and up to date. This script is very similar to `fix-sessions.sh` in structure and arguments. You should run this script even though `fix-sessions.sh` is no longer necessary:

```shell
scripts/check-sessions.sh M N
```

If successful, you'll see output like extension `@pyviz/jupyterlab_pyviz` is installed and activated (`OK` in green color) and the version will be 1.0.X.

If you see anything other than this, like a version number 0.5.X, something is still wrong.

> **Tip:** Since it appears that the session creation usually works, I now just run this script for a few, randomly-sampled sessions.

> **WARNING:** This script runs synchronously through each session, one at a time, to avoid stressing the Anyscale gateway.

## Retrieve Session Information

Since we don't give attendees platform accounts at this time, we instead give them URLs for Jupyter, the Ray Dashboard, and TensorBoard, plus the Jupyter token needed to access these pages. This is the only access they have. (It's weak; they can start a terminal in Jupyter and muck around that way...)

```shell
scripts/get-sessions.sh M N > sessions.csv
```

This will write the data as CSV content, so it's best to redirect to a file as shown.

Then, edit the file to remove any sessions you don't want to provide to students, e.g., the sessions you and your co-instructors will use!!

> **WARNING:** This script has to run synchronously through the sessions.

## Write Email Boilerplate

From the previous command's output, we generate email boilerplate to send to each individual attendee.

First, edit the template text in `scripts/write-session-data.sh` to be up-to-date, including:

1. _Thank you for registering for the live Anyscale Academy ..., Month Day, 2020, 10AM Pacific._
2. _https://www.eventbrite.com/e/anyscale-academy-instructor-led-introduction-to-ray-tickets-105019441978_ (Ask Sophia for the correct link).
3. _https://zoom.us/j/98719676934_ (Ask Sophia for the correct link).
4. _https://github.com/anyscale/academy_ and the line that follows it. (E.g., you want them to use a particular branch or release tag).
5. _Don't forget to visit our Events page, https://anyscale.com/events for future tutorial and "Ray Summit Connect" events this summer. Videos of past events can be found there, too._ (This text will change by the end of Summer 2020).

Then run the following script, assuming you saved the output of the previous command to `sessions.csv`:

```shell
scripts/write-session-data.sh < sessions.csv > emails.txt
```

All the email texts will be written to one file, `emails.txt`. Each email will start with an email address on a line, a suggested subject for the email on a line, and then the body of the text with the unique data for that person.

> **Note:** This script doesn't access the sessions.

## Email Attendees

Take one message per attendee from `emails.txt` and send it to each attendee. Be careful that you don't send the same text to more than one person.

## Final Notes

You should be ready to go. I always do a sanity check where I click a few of the links sent to users and verify they work.

If you do any bug fixes to the Academy code, such as the notebooks, push the changes to all the sessions with `scripts/push-to-sessions.sh`.

## The Day of the Event

1. Set up a custom slack channel in the Anyscale slack for that day's event, to be used for internal communications and coordination, like troubleshooting.
2. For your Anyscale colleagues who will help during the event:
    * Make them _project collaborators_ for the event's project.
    * Tell them about the special slack channel.
    * Add them as Zoom _panelists_, e.g., to help with Q&A.
    * Share with them a Google spreadsheet with the list of the extra session URLs, which they can hand out to people who need them during the event.
    * Tell them that when a session has been allocated, they should mark it in the spreadsheet!!

## After the Event

Tell the students you will leave the sessions running for some additional hours (2-4?), then shut them down. You can do that with this script:

```shell
scripts/terminate-sessions.sh M N
```


## Using run-all.sh for End to End Testing

There is a `scripts/run-all.sh` script that can be used to run the entire setup sequence, in principle. It is mostly intended as an end-to-end test script, as it may not be realistic in most cases to run it as is. Note there are several places where it pauses for tasks to finish; you have to enter information at the prompt to continue. Look for `PROMPT ==>` strings.

Here's how to use `run-all.sh`:

1. Clone this repo or better, download the tagged version corresponding to the `academy` repo you'll use.
    * Here are the [`academy` releases](https://github.com/anyscale/academy/releases).
    * Here are the [`academy-live-events` releases](https://github.com/anyscale/academy-live-events/releases).
2. Change to the cloned or unzipped directory.
3. Run `scripts/run-all.sh version`, where `version` is a tag or release for the `academy` repo (required argument). (Don't cd to `scripts` and run it from there!)

It will download the specified `academy` version zip file. Suppose `version = v2.0.0`, then the zip file will be `academy-2.0.0.zip` (yes, GitHub annoyingly drops the `v`) and it will be expanded into a directory `academy-2.0.0`, by `run-all.sh`, after which it wil change into that directory.

This `academy-2.0.0` working directory will be used to create the Anyscale project and sessions.

> **Tip:** To see what `run-all.sh` will do, try running it with `--no-exec`. It will echo all the commands, including the `scripts/*.sh` scripts it runs, without actually doing anything. This same argument works for all the `scripts/*.sh` scripts, too.


