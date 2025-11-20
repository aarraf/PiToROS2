# ROS2 based Sensor Readout on Raspberry Pi

## Description 

The aim of the project is to publish and subscribe messages between a [ROS2 Jazzy](https://docs.ros.org/en/jazzy/index.html) (local machine) and a remote node (Raspberry Pi Zero 2). The local machine and Pi may be in different networks. Thus, SSH port forwarding is used to maps the port to the same network. On the Pi the [roslibpy](https://roslibpy.readthedocs.io/en/latest/readme.html) Python library is used to communicate with ROS2 since it does not require a ROS2 installation on the Pi. But it requires a ros-bridge-server on the local machine.

## Setup and Usage

1. Docker setup on local machine with Dockerfile & docker-compose 
    - The setup follows the tutorial [Setup-ROS-2-with-VSCode-and-Docker-Container](https://docs.ros.org/en/jazzy/How-To-Guides/Setup-ROS-2-with-VSCode-and-Docker-Container.html) but without using a display. The "postCreateCommand" command automatically install the required dependencies of the ROS2 packages.
    - Install the [ros-bridge-server](http://wiki.ros.org/rosbridge_suite) which runs default on port "9090". Thus map the port to localhost in docker-compose file
    - (optional) To [Persist bash history](https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history) 

2. Connect from the local machine to the Pi with the following SSH config:
    ```
    Host myPi
        HostName XXX
        User Pi
        Port 22
        IdentityFile ~/.ssh/XXX
        IdentitiesOnly yes
        LocalForward 8086 localhost:8086
        RemoteForward 9090 localhost:9090
    ```
    
    Important is to use "RemoteForward" to make the ros-bridge-server (Port 9090) available at the Pi. The "LocalForward" of port 8086 makes an InfluxDB database with all Pi`s sensor data available at the local machine. 

    If you use VS Code for SSH make sure that all extensions (Python, etc.) are deactivated on the Pi. Otherwise the Pi crashes due to heavy load.

3. Starting the ROS2 nodes on the local machine
    
    - For the first startup build all ROS packages with
        ```
        colcon build
        ```
    - Start all ROS2 nodes with

        ```
        docker compose up -d
        ```
    - Attach terminal to the running container with 
        ```
        docker attach container_name
        ```
        This way the entrypoint (/ros_entrypoint.sh) is automatically executed. If you have to create a *new* terminal you must always first execute  
        ```
        docker exec -it container_name bash 
        source /opt/ros/jazzy/setup.bash
        ```
        to source the environment and enable to ros2 command.


4. Test the setup by starting a ros-bridge server, a simple listener and a talker (Pi) using docker compose or execute to following steps manually
    - Start the ros-bridge-server
        ```
        ros2 launch rosbridge_server rosbridge_websocket_launch.xml
        ```
    - Start the listener to log the messages on the terminal
        ```
        ros2 run py_pubsub listener
        ```
    - Start the talker on the Pi


## Working with ROS2 Python packages

- Follow the instructions: [Writing-A-Simple-Py-Publisher-And-Subscriber](https://docs.ros.org/en/jazzy/Tutorials/Beginner-Client-Libraries/Writing-A-Simple-Py-Publisher-And-Subscriber.html)

- Create a ROS2 package *py_pubsub* in the standard directory ```./src``` to automatically creates the required folder structure. 
    ```
    ros2 pkg create --build-type ament_python --license Apache-2.0 py_pubsub
    ```
- Add all the dependencies of the package to the file ```./src/py_pubsub/package.xml```
- Add the entrypoints (talker and listener) in the setup file ```./src/py_pubsub/setup.py```
- Install the required dependencies of the ROS2 packages
    ```
    sudo rosdep update && sudo rosdep install --rosdistro=jazzy --from-paths src --ignore-src -y
    ```
- Build the package
    ```
    colcon build --packages-select py_pubsub
    ```
- Execute a package in a new terminal with
    ```
    source /opt/ros/jazzy/setup.bash
    source install/setup.bash
    ros2 run py_pubsub talker
    ```



## Python development of ROS2 packages 

Can be done with the [VSCode devcontainer](https://code.visualstudio.com/docs/devcontainers/containers) extension and proper settings in ```.devcontainer/devcontainer.json``` file. To enable the Python Code-Checking features, provide the paths to the installed Python environment, side-packages and ROS2 packages.


## Create custom ROS2 messages
- Follows the tutorial [Creating custom msg and srv files](https://docs.ros.org/en/jazzy/Tutorials/Beginner-Client-Libraries/Custom-ROS2-Interfaces.html)
- Create a package
    ```
    ros2 pkg create sensor_msgs --build-type ament_cmake
    ```

- Add a ```src/sensor_msgs/msg``` directory in the package and add a create the custom message file, e.g., ```src/sensor_msgs/msg/ENS160.msg```

- Modify the ```CMakeList.txt``` with the following com
    ```
    find_package(rosidl_default_generators REQUIRED)
    rosidl_generate_interfaces(${PROJECT_NAME}
        "msg/ENS160.msg"
        "msg/ENS210.msg"
        "msg/WH2600.msg"
    )
    ```
- Modify the ```package.xml``` with
    ```
    <build_depend>rosidl_default_generators</build_depend>
    <exec_depend>rosidl_default_runtime</exec_depend>
    <member_of_group>rosidl_interface_packages</member_of_group>
    ```

- Build the package with
    ```
    colcon build
    source install/setup.bash
    ```