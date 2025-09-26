import rclpy
from rclpy.node import Node
from std_msgs.msg import String
from shadowhound_utils.robot_iface import RobotIface

class ShadowHoundMissionAgent(Node):
    def __init__(self):
        super().__init__('shadowhound_mission_agent')
        self.profile = self.declare_parameter('profile','laptop_webrtc').get_parameter_value().string_value
        self.backend = self.declare_parameter('backend','cloud').get_parameter_value().string_value
        self.llm_endpoint = self.declare_parameter('llm_endpoint','http://127.0.0.1:8000').get_parameter_value().string_value

        self.get_logger().info(f"Mission Agent (profile={self.profile}, backend={self.backend})")
        self.create_subscription(String, '/shadowhound/instruction', self._on_instruction, 10)

        self.robot = RobotIface(node_name='robot_iface')
        self.say_pub = self.create_publisher(String, '/shadowhound/say', 10)

    def _on_instruction(self, msg: String):
        text = msg.data.lower().strip()
        if 'spin' in text or 'turn' in text:
            self.get_logger().info('Spinning in place (demo).')
            for _ in range(20):
                self.robot.cmd_vel(0.0, 0.0, 0.5)
                rclpy.spin_once(self, timeout_sec=0.05)
            self.robot.cmd_vel(0.0, 0.0, 0.0)
            self._say('Done.')
        else:
            self.get_logger().info(f'Instruction: {text}')
            self._say('Acknowledged.')

    def _say(self, text: str):
        self.say_pub.publish(String(data=text))

def main():
    rclpy.init()
    node = ShadowHoundMissionAgent()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
