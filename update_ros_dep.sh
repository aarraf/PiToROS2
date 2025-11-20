#!/bin/sh
echo 'Updating ROS2 Package Dependencies:' 
sudo rosdep update && sudo rosdep install --rosdistro=jazzy --from-paths src --ignore-src -y

# and add this at the end
exec "$@"