from setuptools import setup
package_name='shadowhound_mission_agent'
setup(
    name=package_name,
    version='0.0.1',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages',['resource/'+package_name]),
        ('share/'+package_name,['package.xml','launch/bringup.launch.py']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='You',
    maintainer_email='you@example.com',
    description='Mission/Conversation agent that calls skills and uses RobotIface.',
    license='MIT',
    entry_points={'console_scripts':[
        'mission_agent = shadowhound_mission_agent.mission_agent:main',
    ]},
)
