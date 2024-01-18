 function [sigvm_node1, sigvm_node2] = calculatespaceframeVM(m, nodes, i, j, u)
%Calculate von-Mises stresses of spaceframe element given nodes i and j
%and displacements
    %[u(6*(i-1)+1:6*(i-1)+6);u(6*(j-1)+1:6*(j-1)+6)] takes first 6
    %displacements from node i and 7-12
    f = SpaceFrameElementForces(m.E, m.G, m.A, m.Iyy, m.Izz, m.J, nodes(i, 1), nodes(i, 2), nodes(i, 3),...
        nodes(j, 1), nodes(j, 2), nodes(j, 3), [u(6*(i-1)+1:6*(i-1)+6);u(6*(j-1)+1:6*(j-1)+6)]);
    I = m.Iyy;
    X = nodes(j, 1)-nodes(i, 1);
    Y = nodes(j, 2)-nodes(i, 2);
    Z = nodes(j, 3)-nodes(i, 3);
    L = sqrt(X^2 + Y^2 + Z^2); %3D Pythagoras
    % Element stress at node 1
    
    %% CODE MODIFIED FROM LEARN
    sigAx = -f(1)/m.A; % Element axial stresses
    My = f(3)*0 - f(5);
    sigMy = My * m.D/2/I;  % Element bending stresses
    
    Mz = f(2)*0 - f(6);
    sigMz = Mz*m.D/2/I;  % Element bending stresses
    tau = -f(4)*m.D/2/m.J; % Element shear stress
    sigmax1 = sigAx + sqrt(sigMy^2 + sigMz^2);
    sigmax2 = sigAx - sqrt(sigMy^2 + sigMz^2);
    sigvm_node1 = sqrt(max([sigmax1 sigmax2].^2) + 3*tau^2);

    % Element stress at node 2
    sigAx = -f(1)/m.A; % Element axial stresses
    My = f(3)*L - f(5);
    sigMy = My*m.D/2/I; % Element bending stresses
    Mz = f(2)*L - f(6);
    sigMz = Mz*m.D/2/I; % Element bending stresses
    tau = -f(4)*m.D/2/m.J; % Element shear stress
    sigmax1 = sigAx + sqrt(sigMy^2 + sigMz^2);
    sigmax2 = sigAx - sqrt(sigMy^2 + sigMz^2);
    sigvm_node2 = sqrt(max([sigmax1 sigmax2].^2) + 3*tau^2);
    
    %Very (very) crude approximation of buckling
    %Since crude, multiply by a safetyfactor of 1.75
    %A's cancel to give forces
    %Here, buckling length is approximated to be 2
    if(abs(f(7))*1.75 > pi^2*m.E*m.Iyy/(2*2)^2)
        warning('Element Buckling!'); 
    end
    if(max(sigvm_node1, sigvm_node2) > m.yieldstress)
        warning('Element Von-Mises Stress Above Mirror Yield Stress!'); 
    end
end