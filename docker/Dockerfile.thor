FROM nvcr.io/nvidia/l4t-jetpack:6.0
RUN apt-get update && apt-get install -y ros-humble-ros-base python3-vcstool ros-humble-rmw-cyclonedds-cpp build-essential
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp ROS_DOMAIN_ID=7
WORKDIR /ws
COPY shadowhound.repos /ws/
RUN mkdir -p src && vcs import src < shadowhound.repos || true
RUN . /opt/ros/humble/setup.sh && colcon build --merge-install || true
COPY launch /ws/launch
COPY configs /ws/configs
ENTRYPOINT ["/bin/bash","-lc","source /ws/install/setup.bash && ros2 launch shadowhound_bringup shadowhound_bringup.launch.py profile:=thor_ethernet backend:=local llm_endpoint:=http://127.0.0.1:8000"]
