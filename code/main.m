%% NOTE: SOME CODE IN THE ADDITIONAL FUNCTIONS ARE SPECIFIC TO THIS PROBLEM,
%% BUT CAN BE SIMPLY GENERALISED GIVEN MORE TIME
%% PRELIMINARY
%First, clear everything for convenience
clear all;
clc;
%Include FEM libraries
addpath('M-Files');
%Load nodes given from Learn
load('nodes.mat');

%% PROBLEM DEFINITION
%(NOTE MOMENTS AND THETAS ARE NOT INCLUDED AS THEY ARE NOT USED, ALTHOUGH THEY COULD BE INCLUDED SIMILARLY)

%Nodal Constraints Representation
%(Node Number, x, y, z DOFs)
%0 is unconstrained, 1 is constrained
%In this case, nodes 26->31 x,y,z will be constrained
constraints = [];
%Vertical acceleration of 4.5g (as stated in the brief), can be set as a
%vector (x, y, z), but not done for this project
accelerationz = -9.81 * 4.5;

%Define the mirror node range (can have seperate matrix to allow for
%non-arithmetic node sequences, but okay for this project
mirrornodes = 1:25;

%Which forces applied to which nodes
%(NOT FORCE VECTOR, BUT WILL BE USED TO ASSEMBLE THE FORCE VECTOR)
%(Node Number, Fx, Fy, Fz)
%In this case, nodes 1->25 Fx=Fy=0, Fz = -4.5*9.81*260
forces = [];
%Loop through the mirror nodes and apply the corresponding forces
for i=1:max(mirrornodes)
    %Dynamic allocation is not too slow here.
    %Set z force to be 240 x accelerationz
    forces = [forces;i, 0, 0, accelerationz * 240];
end
%Loop through all the other nodes and constrain in x, y, z
for i=max(mirrornodes)+1:size(nodes, 1)
    %Dynamic allocation is not too slow here either.
    constraints = [constraints;i, 1, 1, 1];
end
%Can add extra node quite simply here, i.e.: nodes = [nodes;[0, 0, 1]];,
%but this is not done for this project


%Element Connections Representation
%(Connecting Node Number 1, Connecting Node Number 2, material number from material array (see later))
%Note: Direction does not matter, Nodes 1->2 is equivalent to Nodes 2->1


%Top (Not Directly Connected to Base)
connections = [2, 8, 2;
               8, 16, 2;
               16, 10, 2;
               10, 18, 2;
               18, 25, 2;
               25, 5, 2;
               5, 23, 2;
               23, 16, 2;
               5, 11, 2;
               11, 19, 2;
               11, 17, 2;
               17, 24, 2;
               24, 4, 2;
               4, 22, 2;
               22, 15, 2;
               15, 9, 2;
               9, 17, 2;
               9, 3, 2;
               3, 23, 2;
               15, 7, 2;
               7, 13, 2;
               7, 1, 2;
               1, 21, 2;
               21, 3, 2;
               21, 14, 2;
               14, 8, 2;
               14, 6, 2;
               6, 12, 2;
               12, 20, 2;
               20, 1, 2;
               ];    

%Supports (Connected Directly to Base Nodes)
connections = [connections;
               13, 31, 1;
               4, 26, 1;
               19, 27, 1;
               18, 28, 1;
               2, 29, 1;
               12, 30, 1;
               26, 9, 3;
               28, 23, 3;
               30, 21, 3
                ];
%Top, additional elements after improvement            
connections = [connections;
               2, 10, 2;
               25, 19, 2;
               19, 24, 2;
               22, 13, 2;
               13, 20, 2;
               6, 2, 2];

%Display nodal coordinates, this simplified entering points into Patran for
%testing
% disp('Nodal Coordinates: ');
% for i=1:length(nodes)
%    disp([num2str(i) ': [' num2str(nodes(i, 1)) ' ' num2str(nodes(i, 2)) ' ' num2str(nodes(i, 3)) ']']); 
% end
%% MATERIAL PROPERTIES
%Define a material from the class material(.m). This allows different
%elements to have different properties (including subdivisions). I didn't actually use it for this
%problem, but it was nice to have to give a greater DOF.
%I have shown how to use separate materials, but they have the same
%properties. If you change one of then, it should be updated accoringly
%when you run this script.

%Create a material object m1. This simplifies passing materials through
%functions.
m1 = material;

%Parameters here are material properties
%Titanium Alloy - Ti5Al2.5Sn Grade 6 https://www.azom.com/properties.aspx?ArticleID=1641
m1.E = 112.5e9; %Pa
m1.D = 0.12; %m
m1.nu = 0.33;
m1.G = m1.E/2/(1 + m1.nu);  %Pa
m1.T = 0.005; %Thickness as 0.005m (5mm)

m1.A = pi/4 * (m1.D^2 - (m1.D-2*m1.T)^2); %m^2
m1.Iyy = pi/64 * (m1.D^4 - (m1.D-2*m1.T)^4); %m^4
m1.Izz = m1.Iyy; %m^4

m1.J = 2*m1.Iyy;

m1.rho = 4.507*1000; %kg/m^3

%Globally subdivide each connection into subdivision number of elements
%subdivision factor of 1 = no division, 2 = 2 new elements per initial
%element
%10 is a good number where the solution has converged to a
%reasonable degree of accuracy.
m1.subdivisionfactor = 10;
m1.yieldstress = 862e6; %Pa

m2 = m1;
m3 = m1;

m2.D = 0.135; %m
m2.G = m2.E/2/(1 + m2.nu); %Pa
m2.T = 0.005; %Thickness as 0.005m (5mm)

m2.A = pi/4 * (m2.D^2 - (m2.D-2*m2.T)^2); %m^2
m2.Iyy = pi/64 * (m2.D^4 - (m2.D-2*m2.T)^4); % %m^4
m2.Izz = m2.Iyy; %m^4

m2.J = 2*m2.Iyy; %m^4

m3.D = 0.1; %m
m3.G = m3.E/2/(1 + m3.nu); %Pa
m3.T = 0.005; %Thickness as 5mm

m3.A = pi/4 * (m3.D^2 - (m3.D-2*m3.T)^2); %m^2
m3.Iyy = pi/64 * (m3.D^4 - (m3.D-2*m3.T)^4); %m^4
m3.Izz = m3.Iyy;  %m^4

m3.J = 2*m3.Iyy;  %m^4

%Create a mirror object and define it's properties (this just stores the
%mirror properties to easily pass to functions)
mirrorproperties = mirror;
mirrorproperties.t = 150e-3; % thickness = 150 mm
mirrorproperties.E = 303e9; % Young's modulus
mirrorproperties.nu = 0.07; % Poisson's ratio
%Yield stress is divided by a safety factor of 2
mirrorproperties.yieldstress = 240e6 / 2;
mirrorproperties.radius = 2; %m
%Maximum allowable structural mass
maxmass = 600; %kg

%Material array where element 1 corresponds to m1, etc.
%This corresponds to the connections matrix from earlier.
materialarray = [m1, m2, m3];

%convergencestudy(materialarray, mirrornodes, nodes, connections, constraints, forces, 1, 15);
convergencestudymirror(materialarray, mirrorproperties, mirrornodes, nodes, connections, constraints, forces, 10, 0.5, 0.00105, 80)
%Plot the structure (w/o deflections etc.)
%Done before subdivisions to display nodes without subdivision nodes
plotstructure(materialarray, mirrornodes, nodes, connections);

%Subdivide the nodes, given the connections made (material array stores
%different subdivision factors so different elements can have different
%subdivision factors, though not really used for this project)
[nodes, connections] = subdivide(nodes, connections, materialarray);

%Generate displacement vectors and calculate total mass given input
%conditions
[u, totalmass] = calculatedisplacements(materialarray, nodes, connections, constraints, forces, accelerationz);
%If the calculated total mass is above the max allowable
if(totalmass > maxmass)
    %Display warning (makes it obvious that design fails criteria)
   warning('Structure Mass Above Maximum Allowable!'); 
end
%Display total mass
disp(['Total Mass: ' num2str(totalmass)]);
%Analyse the solution given the input conditions and the displacement
%vector calculated earler. first 1 (display(0 (false) or 1 (true))) refers to if you want
%to plot. flag(0 (false) or 1 (true))) refers to if you want to output
%mirror nodal displacements or mirror displacements from meshgrid. final
%parameter is gridspacing (h)
analyse(mirrornodes, mirrorproperties, nodes, u, 1, 1, 0.01);
%Plot the displacements amplified by 100, with the mirror. h set as 0.05
% (purely for visual (general trends remain for range of grid spacing))
plotstructuredeflection(materialarray, mirrornodes, nodes, connections, u, 100, 1, mirrorproperties, 0.05);
%Plot the displacements amplified by 100, without the mirror.
plotstructuredeflection(materialarray, mirrornodes, nodes, connections, u, 100, 0);
%Plot the unamplified displacements, without the mirror.
plotstructuredeflection(materialarray, mirrornodes, nodes, connections, u, 1, 0);
