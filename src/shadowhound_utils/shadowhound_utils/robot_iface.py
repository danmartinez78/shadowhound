import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
from sensor_msgs.msg import Imu, Image
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy
from typing import Optional

class RobotIface(Node):
    """
    Thin compatibility layer over the active GO2 driver (go2_ros2_sdk topics)
    so agents/skills don't depend on a specific backend.
    """

    def __init__(self, node_name: str = "robot_iface"):
        super().__init__(node_name)
        qos = QoSProfile(depth=10)
        qos.reliability = ReliabilityPolicy.BEST_EFFORT
        qos.history = HistoryPolicy.KEEP_LAST

        self.cmd_vel_pub = self.create_publisher(Twist, "/cmd_vel", qos)

        self._odom_msg = None
        self._imu_msg = None
        self._last_image = None

        self.create_subscription(Odometry, "/odom", self._on_odom, qos)
        self.create_subscription(Imu, "/imu/data", self._on_imu, qos)
        self.create_subscription(Image, "/camera/image_raw", self._on_image, qos)

    def _on_odom(self, msg: Odometry):
        self._odom_msg = msg

    def _on_imu(self, msg: Imu):
        self._imu_msg = msg

    def _on_image(self, msg: Image):
        self._last_image = msg

    def cmd_vel(self, vx: float, vy: float, wz: float):
        msg = Twist()
        msg.linear.x = float(vx)
        msg.linear.y = float(vy)
        msg.angular.z = float(wz)
        self.cmd_vel_pub.publish(msg)

    def odom(self) -> Optional[Odometry]:
        return self._odom_msg

    def imu(self) -> Optional[Imu]:
        return self._imu_msg

    def camera_image(self) -> Optional[Image]:
        return self._last_image
