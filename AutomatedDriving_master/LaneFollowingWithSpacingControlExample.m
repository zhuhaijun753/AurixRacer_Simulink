%% Lane Following Control with Sensor Fusion and Lane Detection
% This example shows how to simulate and generate code for an automotive
% lane-following controller.
%
% In this example, you will:
%
% # Review a control algorithm that combines sensor fusion, lane detection,
% and a lane following controller from the Model Predictive Control
% Toolbox(TM).
% # Test the control system in a closed-loop Simulink(R) model using
% synthetic data generated by the Automated Driving Toolbox(TM).
% # Configure the code generation settings for software-in-the-loop
% simulation and automatically generate code for the control algorithm.
 
% Copyright 2018 The MathWorks, Inc.
 
%% Introduction
% A lane following system is a control system that keeps the vehicle
% traveling within a marked lane of a highway, while maintaining a
% user-set velocity or safe distance from the preceding vehicle. A lane
% following system includes combined longitudinal and lateral control of
% the ego vehicle:
%
% * Longitudinal control - Maintain a driver-set velocity and keep a safe
% distance from the preceding car in the lane by adjusting the acceleration
% of the ego vehicle.
% * Lateral control - Keep the ego vehicle travelling along the centerline of
% its lane by adjusting the steering of the ego vehicle
%
% The combined lane following control system achieves the individual goals
% for longitudinal and lateral control. Further, the lane following control
% system can adjust the priority of the two goals when they cannot be met
% simultaneously.
%
% For an example of longitudinal control using adaptive cruise control
% (ACC) with sensor fusion, see
% <docid:mpc_ug#mw_2025d6a5-c63c-4468-b4a2-e15164d4ccbd>. For an example of
% lateral control using a lane keeping assist (LKA) system with lane
% detection, see <docid:mpc_ug#mw_58bd8d15-b052-495d-afe9-77b7bf20fac4>.
% The ACC example assumes ideal lane detection, and the LKA example does
% not consider surrounding vehicles.
%
% In this example, both lane detection and surrounding cars are considered.
% The lane following system synthesizes data from vision and radar
% detections, estimates the lane center and lead car distance, and
% calculates the longitudinal acceleration and steering angle of the ego
% vehicle.

%%
% Add example file folder to MATLAB(R) path.
% 
%   addpath(fullfile(matlabroot,'examples','mpc','main'));
% 
addpath(fullfile(matlabroot,'examples','mpc','main'));

%% Open Test Bench Model
% Open the Simulink test bench model.
%
%   open_system('LaneFollowingTestBenchExample')
%
open_system('LaneFollowingTestBenchExample')
 
%%
% The model contains four main components:
% 
% # Lane Following Controller - Controls both the longitudinal
% acceleration and front steering angle of the ego vehicle
% # Vehicle and Environment - Models the motion of the ego vehicle and
% models the environment
% # Collision Detection - Stops the simulation when a collision of the ego
% vehicle and lead vehicle is detected
% # MIO Track - Enables MIO track for display in Bird's Eye Scope.
%
% Opening this model also runs the |helperLFSetUp| script, which
% initializes the data used by the model by loading constants needed by the
% Simulink model, such as the vehicle model parameters, controller design
% parameters, road scenario, and surrounding cars.
%
% Plot the road and the path that the ego vehicle will follow using:
%
%   plot(scenario)
%
plot(scenario)
 
%%
% To plot the results of the simulation and depict the ego vehicle
% surroundings and tracked objects, use the
% <docid:driving_ref#mw_59742eb7-dce8-4938-9c2e-44d34c7b8891>. The
% Bird's-Eye Scope is a model-level visualization tool in Simulink that you
% can using a menu provided on the Simulink model toolbar. After opening
% the scope, set up the signals by clicking *Find Signals*.
%
% To get a mid-simulation view, simulate the model for |10| seconds.
%
%   sim('LaneFollowingTestBenchExample','StopTime','10')
%
% After simulating the model for 10 seconds, open the Bird's-Eye Scope.
% 
% <<../mpcLFBES.png>>
% 
 
%%
% The bird's-eye scope shows the results of the sensor fusion. It shows how
% the radar and vision sensors detect the vehicles within their coverage
% areas. It also shows the tracks maintained by the Multi-Object Tracker
% block. The yellow track shows the most important object (MIO), which is
% the closest track in front of the ego vehicle in its lane. The ideal lane
% markings are also shown along with the synthetically detected left and
% right lane boundaries (shown in red).
 
%%
% Simulate the model to the end of the scenario.
%
%   sim('LaneFollowingTestBenchExample')
%
sim('LaneFollowingTestBenchExample')
 
%%
% Plot the controller performance.
%
%   plotLFResults(logsout,time_gap,default_spacing)
%
plotLFResults(logsout,time_gap,default_spacing)
 
%%
% The first figure shows the following spacing control performance results.
%
% * The *Velocity plot* shows that the ego vehicle maintains velocity
% control from 0 to 11 seconds, switches to spacing control from 11
% to 16 seconds, then switches back to velocity control.
% * The *Distance between two cars* plot shows that the actual
% distance between lead vehicle and ego vehicle is always greater than the
% safe distance.
% * The *Acceleration* plot shows that the acceleration for ego vehicle is
% smooth.
% * The *Collision status* plot shows that no collision between lead
% vehicle and ego vehicle is detected, thus the ego vehicle runs in a safe
% mode.
%
% The second figure shows the following lateral control performance
% results.
%
% * The *Lateral deviation* plot shows that the distance to the lane
% centerline is within 0.2 m.
% * The *Relative yaw angle* plot shows that the yaw angle error with
% respect to lane centerline is within 0.03 rad (less than 2 degrees).
% * The *Steering angle* plot shows that the steering angle for ego vehicle is
% smooth.
%
 
%% Explore Lane Following Controller
% The Lane Following Controller subsystem contains three main parts: 1)
% Estimate Lane Center 2) Tracking and Sensor Fusion 3) MPC Controller
%
%   open_system('LaneFollowingTestBenchExample/Lane Following Controller')
%
open_system('LaneFollowingTestBenchExample/Lane Following Controller')
 
%%
% The Estimate Lane Center subsystem outputs the lane sensor data to the
% MPC controller. The previewed curvature provides the centerline of lane
% curvature ahead of the ego vehicle. In this example, the ego vehicle can
% look ahead for 3 seconds, which is the product of the prediction horizon
% and the controller sample time. The controller uses previewed information
% for calculating the ego vehicle steering angle, which improves the MPC
% controller performance. The lateral deviation measures the distance
% between the ego vehicle and the centerline of the lane. The relative yaw
% angle measures the yaw angle difference between the ego vehicle and the road.
% The ISO 8855 to SAE J670E block inside the subsystem converts the
% coordinates from Lane Detections, which use ISO 8855, to the MPC
% Controller which uses SAE J670E.
% 
% The Tracking and Sensor Fusion subsystem processes vision and radar
% detections coming from the Vehicle and Environment subsystem and
% generates a comprehensive situation picture of the environment around the
% ego vehicle. Also, it provides the lane following controller with an
% estimate of the closest vehicle in the lane in front of the ego vehicle.
% 
% The goals for the MPC Controller block are to:
%
% * Maintain the driver-set velocity and keep a safe distance from lead
% vehicle. This goal is achieved by controlling the longitudinal
% acceleration.
% * Keep the ego vehicle in the middle of the lane; that is reduce the
% lateral deviation $E_{lateral}$ and the relative yaw angle $E_{yaw}$, by
% controlling the steering angle.
% * Slow down the ego vehicle when road is curvy. To achieve this goal, the
% MPC controller has larger penalty weights on lateral deviation than on
% longitudinal speed. 
% 
% <<../mpcLFfig.png>>
% 
% The MPC controller is designed within the Path Following Control (PFC) System 
% block based on the entered mask paramters, and the
% designed MPC Controller is an adaptive MPC which updates the vehicle model
% at run time. The lane following controller calculates the longitudinal
% acceleration and steering angle for the ego vehicle based on the
% following inputs:
% 
% * Driver-set velocity
% * Ego vehicle longitudinal velocity
% * Previewed curvature (derived from Lane Detections)
% * Lateral deviation (derived from Lane Detections)
% * Relative yaw angle (derived from Lane Detections)
% * Relative distance between lead vehicle and ego vehicle (from the
% Tracking and Sensor Fusion system)
% * Relative velocity between lead vehicle and ego vehicle (from the
% Tracking and Sensor Fusion system)
%
% Considering the physical limitations of the ego vehicle, the steering
% angle is constrained to be within [-0.26,0.26] rad, and the longitudinal
% acceleration is constrained to be within [-3,2] m/s^2.
 
%% Explore Vehicle and Environment
% The Vehicle and Environment subsystem enables closed-loop simulation of
% the lane following controller.
%
%   open_system('LaneFollowingTestBenchExample/Vehicle and Environment')
%
open_system('LaneFollowingTestBenchExample/Vehicle and Environment')
 
%%
% The System Latency blocks model the latency in the system between
% model inputs and outputs. The latency can be caused by sensor delay or
% communication delay. In this example, the latency is approximated by one
% sample time $T_s = 0.1$ seconds.
% 
% The Vehicle Dynamics subsystem models the vehicle dynamics using a
% Bicycle Model - Force Input block from the Vehicle Dynamics Blockset(TM).
% The lower-level dynamics are modeled by a first-order linear system with
% a time constant of $\tau = 0.5$ seconds.
%
% The SAE J670E to ISO 8855 subsystem converts the coordinates from Vehicle
% Dynamics, which uses SAE J670E, to Scenario Reader, which uses ISO 8855.
%
% The <docid:driving_ref#mw_0abe0f52-f25a-4829-babb-d9bafe8fdbf3 Scenario
% Reader> block reads the actor poses data from the scenario file. The
% block converts the actor poses from the world coordinates of the scenario
% into ego vehicle coordinates. The actor poses are streamed on a bus
% generated by the block. The Scenario Reader block also generates the
% ideal left and right lane boundaries based on the position of the vehicle
% with respect to the scenario used in |helperLFSetUp|.
%
% The Vision Detection Generator block takes the ideal lane boundaries from
% the Scenario Reader block. The detection generator models the field of
% view of a monocular camera and determines the heading angle, curvature,
% curvature derivative, and valid length of each road boundary, accounting
% for any other obstacles. The Radar Detection block generates point
% detections from the ground-truth data present in the field-of-view of the
% radar based on the radar cross-section defined in the scenario.
 
%% Run Controller for Multiple Test Scenarios
% This example uses multiple test scenarios based on ISO standards and
% real-world scenarios. To verify the controller performance, you can test
% the controller for multiple scenarios and tune the controller parameters
% if the performance is not satisfactory. To do so:
%
% # Select the scenario by changing |scenarioId| in |helperLFSetUp|.
% # Configure the simulation parameters by running |helperLFSetUp|.
% # Simulate the model with the selected scenario.
% # Evaluate the controller performance using |plotLFResults|
% # Tune the controller parameters if the performance is not satisfactory.

 
%% 
% You can automate the verification and validation of the controller using
% Simulink Test(TM).
 
%% Generate Code for the Control Algorithm 
% The |LFRefMdl| model supports generating C code using Embedded Coder(R)
% software. To check if you have access to Embedded Coder, run:
%
%   hasEmbeddedCoderLicense = license('checkout','RTW_Embedded_Coder')

%%
% You can generate a C function for the model and explore the code
% generation report by running:
%
%   if hasEmbeddedCoderLicense
%     rtwbuild('LFRefMdl')
%   end
%
 
%%
% You can verify that the compiled C code behaves as expected using
% software-in-the-loop (SIL) simulation. To simulate the |LFRefMdl|
% referenced model in SIL mode, use:
%
%   if hasEmbeddedCoderLicense
%     set_param('LaneFollowingTestBenchExample/Lane Following Controller',...
%               'SimulationMode','Software-in-the-loop (SIL)')
%   end
%
 
%%
% When you run the |LaneFollowingTestBenchExample| model, code is
% generated, compiled, and executed for the |LFRefMdl| model, which enables
% you to test the behavior of the compiled code through simulation.
 
%% Conclusions
% This example shows how to implement an integrated lane following
% controller on a curved road with sensor fusion and lane detection, test
% it in Simulink using synthetic data generated using the Automated Driving
% Toolbox, componentize it, and automatically generate code for it.

%%
% Remove the example file folder from the MATLAB path.
% 
%   rmpath(fullfile(matlabroot,'examples','mpc','main'));
% 
rmpath(fullfile(matlabroot,'examples','mpc','main'));
close all 
bdclose all
