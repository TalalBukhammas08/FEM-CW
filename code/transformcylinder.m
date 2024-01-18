function [Xvector,Yvector,Zvector] = transformcylinder(m, nodes,i, j)
%Generates a cylinder from node i to j
    
    %% CONVOLUTED CODE TO TRANSFORM MATLAB's DEFAULT CYLINDER [0, 0, 1]
    %% TO CORRESPOND TO NODE ELEMENTS
    %To summarise this function, find the angle between [0 1 0] (cylinder direction)
    %and desired direction, then the axis of rotation, then rotate
    %using quaternions (convenient cause gimbal lock etc.)
    
    %Calculate length as pythagorean distance in 3d
    l = sqrt((nodes(i, 1)-nodes(j, 1))^2 + (nodes(i, 2)-nodes(j, 2))^2 + (nodes(i, 3)-nodes(j, 3))^2);
    
    %Cylinder defined by radius (D/2) and 10 is n points (resolution)
    [XC, YC, ZC] = cylinder(m.D/2, 10); 

    ZC = ZC * l;
    ndim = size(XC, 1);
    Xvector = zeros(ndim, length(XC));
    Yvector = zeros(ndim, length(XC));
    Zvector = zeros(ndim, length(XC));
    
    % vector to align to (simply the vector difference between node i and
    % j)
    v = [(nodes(j, 1)-nodes(i, 1)), (nodes(j, 2)-nodes(i, 2)), (nodes(j, 3)-nodes(i, 3))]; 
    for b=1:1:length(XC)
        for a=1:1:ndim
            % example vectors
            uvector = [XC(a, b), YC(a, b), ZC(a, b)]; % vector to rotate

            %Edge case (where vectors are parallel)
            if(cross([0, 0, 1], v) == 0)
                b = length(XC) + 1;
                Xvector = XC + nodes(i, 1);
                Yvector = YC + nodes(i, 2);
                %Min because cross can't tell difference between [0, 0, 1]
                %and [0, 0, -1]
                Zvector = ZC + min(nodes(i, 3), nodes(j, 3));
                break;
            end
            v = v/norm(v);
            %angle between vectors (a.b = abcostheta)
            theta = acos(dot([0, 0, 1],v)/(norm(v)*norm([0, 0, 1])));

            %since quaternions repeat rotation twice, angle needs to be over 2
            theta = theta/2;
            %perpendicular vector
            r = cross([0, 0, 1], v);
            %normalise
            r = r/norm(r);

            %Quaternion rotation represented by q*p*q^-1

            %Real part of quaternion = 0, imaginar given by initial vector
            q1 = [0,uvector];
            %Rotation Quaternion
            q2 = [cos(theta),r*sin(theta)];
            %Perform Rotation (q*p*q^-1)
            q3 = quatmultiply(q2,q1);
            q3 = quatmultiply(q3,quatconj(q2));

            %extract the new vector components from the imaginary part of the
            %quaternion (discard real part). This now gives rotated cylinder coordinates
            u_transform = q3(2:4);
            u_transform = u_transform + [nodes(i, 1), nodes(i, 2), nodes(i, 3)];
            Xvector(a, b) = u_transform(1);
            Yvector(a, b) = u_transform(2);
            Zvector(a, b) = u_transform(3);
        end
    end
end

