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

%Which forces applied to which nodes
%(NOT FORCE VECTOR, BUT WILL BE USED TO ASSEMBLE THE FORCE VECTOR)
%(Node Number, Fx, Fy, Fz)
%In this case, nodes 1->25 Fx=Fy=0, Fz = -4.5*9.81*260
forces = [];
for i=1:25
    %Dynamic allocation is ok here.
    forces = [forces;i, 0, 0, -240 * 9.81 * 4.5];
end
for i=26:31
    %Dynamic allocation is ok here.
    constraints = [constraints;i, 1, 1, 1];
end
%Can add extra node quite simply here, i.e.: nodes = [nodes;[0, 0, 1]];

%Element Connections Representation
%(Connecting Node Number 1, Connecting Node Number 2, material number from material array (see later))
%Note: Direction does not matter, Nodes 1->2 is equivalent to Nodes 2->1
%Top Layer
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
%Supports to Top
connections = [connections;
               13, 31, 1;
               4, 26, 1;
               19, 27, 1;
               18, 28, 1;
               2, 29, 1;
               12, 30, 1;
               13, 31, 1;
               26, 3, 1;
               28, 3, 1;
               30, 3, 1
                ];
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
%Supports to Top
connections = [connections;
               13, 31, 1;
               4, 26, 1;
               19, 27, 1;
               18, 28, 1;
               2, 29, 1;
               12, 30, 1;
               13, 31, 1;
               26, 9, 1;
               28, 23, 1;
               30, 21, 1
                ];
%Display nodal coordinates, this simplified entering points into Patran
disp('Nodal Coordinates: ');
for i=1:length(nodes)
   disp([num2str(i) ': [' num2str(nodes(i, 1)) ' ' num2str(nodes(i, 2)) ' ' num2str(nodes(i, 3)) ']']); 
end
%% MATERIAL PROPERTIES
%Define a material from the class material(.m). This allows different
%elements to have different properties (including subdivisions). I didn't actually use it for this
%problem, but it was nice to have to give a greater DOF.
%I have shown how to use separate materials, but they have the same
%properties. If you change one of then, it should be updated accoringly
%when you run this script.

m1 = material;

%Parameters here are material properties
%https://www.azom.com/properties.aspx?ArticleID=1641
m1.E = 107e9; %Pa
m1.D = 0.15; %m
m1.nu = 0.32;
m1.G = m1.E/2/(1 + m1.nu);
m1.T = 0.05 * m1.D; %Thickness as 5% of diameter

m1.A = pi/4 * (m1.D^2 - (m1.D-2*m1.T)^2); %m^2
m1.Iyy = pi/64 * (m1.D^4 - (m1.D-2*m1.T)^4);
m1.Izz = m1.Iyy;

m1.J = 2*m1.Iyy;

m1.rho = 4.462*1000; %kg/m^3

%Globally subdivide each connection into subdivision number of elements
%subdivision factor of 1 = no division, 2 = 2 new elements per initial
%element
%10 is a good number where the solution has converged to a
%reasonable degree of accuracy.
m1.subdivisionfactor = 10;
m1.yieldstress = 345e6; %Pa

m2 = m1;

% m2.E = 107e9; %Pa
% m2.D = 0.15; %m
% m2.nu = 0.32;
% m2.G = m2.E/2/(1 + m2.nu);
% m2.T = 0.05 * m2.D; %Thickness as 10% of diameter
% 
% m2.A = pi/4 * (m2.D^2 - (m2.D-2*m2.T)^2); %m^2
% m2.Iyy = pi/64 * (m2.D^4 - (m2.D-2*m2.T)^4);
% m2.Izz = m2.Iyy;
% 
% m2.J = 2*m2.Iyy;
% 
% m2.rho = 4.462*1000; %kg/m^3




%Maximum allowable structural mass
maxmass = 600; %kg

%Material array where element 1 corresponds to m1, etc.
%This corresponds to the connections matrix from earlier.
materialarray = [m1, m2];

%convergencestudy(materialarray, nodes, connections, constraints, forces, 1, 15);

%Subdivide the nodes, given the connections made (material array stores
%different subdivision factors so different elements can have different
%subdivision factors)
[nodes, connections] = subdivide(nodes, connections, materialarray);
%Plot the structure (w/o deflections etc.)
plotstructure(materialarray, nodes, connections);
%Analyse the structure (generate displacement vectors etc.). Flag = 1
%Means output other information
[u, totalmass] = calculatedisplacements(materialarray, nodes, connections, constraints, forces);
%If the calculated total mass is above the max allowable
if(totalmass > maxmass)
    %Display warning
   warning('Structure Mass Above Maximum Allowable!'); 
end
%Display total mass
disp(['Total Mass: ' num2str(totalmass)]);
analyse(nodes, u, 1);
% %Plot the displacements amplified by 100
 plotstructuredeflection(materialarray, nodes, connections, u, 100);