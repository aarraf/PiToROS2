ARG ROS_DISTRO=jazzy


FROM ros:${ROS_DISTRO}-ros-base
ENV ROS_DISTRO=${ROS_DISTRO}

ARG USERNAME=ros2
ARG USER_UID=1000
ARG USER_GID=$USER_UID


# ********************************************************
# * USER                                 *
# ********************************************************
# Delete user if it exists in container (e.g Ubuntu Noble: ubuntu)
RUN if id -u $USER_UID ; then userdel `id -un $USER_UID` ; fi
# Create the user
RUN groupadd --gid $USER_GID ${USERNAME} \
    && useradd --uid $USER_UID --gid $USER_GID -m ${USERNAME} \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y python3-pip

RUN sudo apt install ros-${ROS_DISTRO}-rosbridge-server -y


# ********************************************************
# * Persist BASH history                                 *
# ********************************************************
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R ${USERNAME} /commandhistory \
    && echo "$SNIPPET" >> "/home/${USERNAME}/.bashrc"


# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER ${USERNAME}
WORKDIR /home/ros2_dev

