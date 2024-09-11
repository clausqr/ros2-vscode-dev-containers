# ROS 2 + VS Code + docker using Dev Containers

A ready to use template repository for setting up ROS 2 with VS Code and Docker using Dev Containers, allowing for easy development without the need to install ROS 2 or any other tools on the host machine, but using all your favorite tools and extensions (and also GUI apps inside container!)!

version: 0.1.0

Sources:
1. https://docs.ros.org/en/iron/How-To-Guides/Setup-ROS-2-with-VSCode-and-Docker-Container.html
2. https://containers.dev/guides
3. https://code.visualstudio.com/docs/devcontainers/containers

![https://code.visualstudio.com/docs/devcontainers/containers](img/dev-containers-vscode.png)

## Getting Started

### Alternative 1: Manual clone and fresh *start*

1. Clone this repository to your local machine and change the name to your desired project name

```bash
git clone git@github.com:clausqr/ros2-vscode-container-dev.git my_project_name
```

1. Break the link to this repo and get rid of the images of `readme.MD`

```bash
cd my_project_name
rm -rf .git && git init
rm readme.MD && touch readme.MD
rm img/*.png
```

### Alternative 2:

### Alternative 2: 

Alternatively, if you are using github, you can select "Use this template"

![github-template-button](img/github-template.png)

and select "Create new repository" and fill in the details and start working on your new repo.
Then after cloning your new repo you only need to get rid of this readme and its imgs:
```bash
git clone <your_new_repo_url> my_project_name
cd my_project_name
rm README.md && touch README.md
rm img/*.png
```

## Setting up Container Dev

1. Open the project folder in VS Code.
2. Install the Remote - Containers extension.
3. Customize `Dockerfile` according to your project needs
4. Run the `create_devcontainer.bash` script to tailor the template to your uid and gid, and also username and custom image name.
  
```bash
bash create_devcontainer.bash -h
Usage: create_devcontainer.bash [option...] {--username|-u} {--user-uid|-i} {--user-gid|-g} {--image-name|-n}

   -u, --username       Username to replace in the JSON template
   -i, --user-uid       User UID to replace in the JSON template
   -g, --user-gid       User GID to replace in the JSON template
   -n, --image-name     Image name to replace in the JSON template

If no command line arguments are provided, the values from setup.env will be used.
```

5. Build the container searching for "build container" in the command palette.
6. Alternatively, reopen the project in a container.
![reopen-in-container](img/reopen-in-container.png)
7. Inside the container, open a terminal and you will be in the `/ros2_ws` folder, which is mapped to the local `./ros2_ws` folder.
8. Start developing. A default `.gitignore` file is in place to ignore build artifacts and logs, which stay inside the container.
9. From there on you can develop for ROS2 without installing ROS2 or any other tool on the host:

```bash
user@host:/ros2_ws/src$ ros2
usage: ros2 [-h] [--use-python-default-buffering] Call `ros2 <command> -h` for more detailed usage. ...

ros2 is an extensible command-line tool for ROS 2.

options:
  -h, --help            show this help message and exit
  --use-python-default-buffering
                        Do not force line buffering in stdout and instead use the python default buffering, which might be affected by PYTHONUNBUFFERED/-u and depends on whatever stdout is
                        interactive or not

Commands:
  action     Various action related sub-commands
  bag        Various rosbag related sub-commands
  component  Various component related sub-commands
  daemon     Various daemon related sub-commands
  doctor     Check ROS setup and other potential issues
  interface  Show information about ROS interfaces
  launch     Run a launch file
  lifecycle  Various lifecycle related sub-commands
  multicast  Various multicast related sub-commands
  node       Various node related sub-commands
  param      Various param related sub-commands
  pkg        Various package related sub-commands
  run        Run a package specific executable
  security   Various security related sub-commands
  service    Various service related sub-commands
  topic      Various topic related sub-commands
  wtf        Use `wtf` as alias to `doctor`

  Call `ros2 <command> -h` for more detailed usage.
user@host:/ros2_ws/src$
```

## Alternative: build and run from terminal

Some convenience scripts are provided, they use a single `setup.env` file to configure the user and image names. 
If you are running multiple instances, you can run each with a custom `instance_name` command line argument.

### Available Scripts



#### 1. `build` - Build the Docker image

```bash
./rr build
```

Build a Docker image with the username, user ID, group ID, image name, and ROS distro specified in the setup.env file.

#### 2. `cleanup` - Clean up the `ros2_ws` artifacts

```bash
./rr cleanup
```

Clean up the ros2_ws artifacts, specifically the build, install, and log directories.

#### 3. `create_devcontainer` - Create a devcontainer.json file

```bash
./rr create_devcontainer
```

Create a devcontainer.json file from the devcontainer-template.json template by replacing placeholders with values from setup.env.

#### 4. `join` - Join a running in the container

```bash
./rr join [--name <container_name>]
```

Join a running container using the specified container name, username, user ID, and group ID from setup.env.

Options:

- `--name <container_name>`: Specify the container name to join. If not provided, the default container name from setup.env is used.

#### 5. `kill` - Kill the running container

Description: If the container is running, this script will kill it.
Usage:

```bash
./rr kill.bash [--name <container_name>]
```

Options:

- `--name <container_name>`: Specify the container name to kill. If not provided, the default container name from setup.env is used.

#### 6. `run` - Run a Docker container

Description:
Run a Docker container with configurations defined in setup.env. This script checks for necessary arguments and allows optional customization of the container name.
Usage:

```bash
./rr run [--name <container_name>]
```

Options:

- `--name <container_name>`: Specify a custom name for the Docker container. If not provided, a default name from setup.env is used.
- `--devaice <device>`: Specify a device to mount in the container. This option can be used multiple times to mount multiple devices.
- `--help`: Display usage information and exit.

Example: Run container with custom name and mount two devices, `/dev/ttyUSB17` (mapped to `/dev/ttyUSB0` inside the container) and `/dev/ttyACM0`:

```bash
./rr run --name my_container --device /dev/ttyUSB17:/dev/ttyUSB0 --device /dev/ttyACM0
```


#### 7. `stop` - Stop a running container.

Description:
Stop a running container with the specified name.
Usage:

```bash

```

Options:

- `--name <container_name>`: Specify the container name to stop. If not provided, the default container name from setup.env is used.

## To Do and WIP

- [x] Squash previous WIP items.
- [x] Offload config to separate `setup.env` file.
- [x] Allow multiple instances.
- [ ] Check/automate GPU handling.
- [ ] Check/automate/allow mounting devices (i.e. `/dev/ttyUSB0`).
- [ ] Integration with github codespaces (get rid of mounts for X11 and GPUs).