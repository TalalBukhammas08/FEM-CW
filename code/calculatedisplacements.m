function [u, cumulativemass] = calculatedisplacements(materialarray, nodes, connections, constraints, forces, accelerationz)
%Performs FEM analysis given m, nodes, connections, constrants, forces
    %   Detailed explanation goes here
    cumulativemass = 0;
    
    %% ANALYSIS
    
    %Initialise Stifness matrix and force vector as zeros
    %DOF = 6, so 6 * nodes = DOF
    K = zeros(size(nodes, 1)*6);
    F = zeros(size(nodes, 1)*6, 1);

    %Loop through all connections
    for c=1:1:size(connections, 1)
        %i refers to first connecting node number and j is the second
        i = connections(c, 1);
        j = connections(c, 2);
        
        %Set the current material to the element material set in the 
        %connections matrix
        m = materialarray(connections(c, 3));
        
        %Projected lengths X, Y, Z
        X = nodes(j, 1)-nodes(i, 1);
        Y = nodes(j, 2)-nodes(i, 2);
        Z = nodes(j, 3)-nodes(i, 3);
        %Generate local stifness matrix and then assemble into global
        k = SpaceFrameElementStiffness(m.E, m.G, m.A, m.Iyy, m.Izz, m.J, nodes(i, 1), nodes(i, 2), nodes(i, 3), nodes(j, 1), nodes(j, 2), nodes(j, 3));
        K = SpaceFrameAssemble(K, k, i, j);
        l = sqrt(X^2 + Y^2 + Z^2); %3D Pythagoras
        
        %Distributed weight load (mass * acceleration / l, i.e. cross-sectional acceleration) 
        qz = accelerationz * m.A * m.rho;
        
        %Apply distibuted inertial load from the code on Learn
        %However, have to do this using global nodes
        %So, corresponding nodes are calculated using:
        %6 * (nodenumber - 1) + 1 is Fxnodenumber
        %6 * (nodenumber - 1) + 1 is Fynodenumber
        %etc.
        
        F((6*(i-1)+1:6*(i-1)+6)) = F((6*(i-1)+1:6*(i-1)+6)) + qz*[0;0;l/2;0;X^2/12;Y^2/12];
        F((6*(j-1)+1:6*(j-1)+6)) = F((6*(j-1)+1:6*(j-1)+6)) + qz*[0;0;l/2;0;-X^2/12;-Y^2/12];
        
        %Calculate the mass of the added element
        dm =  m.A * m.rho * l;
        %Add the mass of the added element to the mass counter
        cumulativemass = cumulativemass + dm;
    end
    
    %% BOUNDARY CONDITIONS
    %Assemble a vector of transformed constraints then remove
    %So don't need to consider shifting indices
    vec = [];
    for i=1:length(constraints)
        %First index is node, so 2->4 are x, y, z
        for j=2:4
            %If 1, 
            if(constraints(i, j) == 1)
                vec = [vec;(constraints(i, 1)-1)*6+j-1];
            end
        end
    end
    
    %Remove rows and columns from vec to enforce constraints
    %2 is a flag to say remove rows and columns
    K = removerowcolumn(K, vec, 2);
    
    %% EXTERNAL FORCES
    %Assemble a vector of transformed constraints then remove
    %So don't need to consider shifting indices
    for i=1:length(forces)
        for j=2:4
            F((forces(i, 1)-1)*6+j-1) = F((forces(i, 1)-1)*6+j-1) + forces(i, j);
        end
    end
    %Consistently apply boundary conditions
    F = removerowcolumn(F, vec, 0);
    
    %% DISPLACEMENT MATRIX
    %Calculate displacement vector from stifness matrix and force vector
    u = K\F;
    %Format vector (set constrained nodes displacement to zero)
    %To simplify rest. vec is vector from before
    u = insertzero(u, vec);
end