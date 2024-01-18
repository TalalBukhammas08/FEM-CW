function [] = plotstructuredeflection(materialarray,  mirrornodes, nodes, connections, u, factor, displaymirror, mirrorproperties, h)
%plotstructure Plots the structure displacements and VM-stresses
%   Takes in connection matrix

    %For variable number of inputs:
    if(~exist('h', 'var'))
       h = 0.1; 
    end
    if(~exist('mirrorproperties', 'var'))
       mirrorproperties = 0;
    end
    f = figure;
    hold on;
    daspect([1;1;1]);
    axis([-3 3 -3 3 -1 3]);
    len = size(connections, 1);
    %x, y, z axes arrows
    arrow3([0 0 0], [1 0 0],'r', 1, 1, -1, 1, 0.4);
    text(1.2, 0, 0, 'x', 'FontSize', 16, 'Color', 'red');
    arrow3([0 0 0], [0 1 0],'g', 1, 1, -1, 1, 0.4);
    text(0, 1.2, 0, 'y', 'FontSize', 16, 'Color', 'green');
    arrow3([0 0 0], [0 0 1],'b', 1, 1, -1, 1, 0.4);
    text(0, 0, 1.2, 'z', 'FontSize', 16, 'Color', 'blue');
    
    %% CALCULATE MIN AND MAX VM STRESSES (FOR PLOTTING COLOURS)
    %Use MATLAB's winter colourmap
    cmap = winter(256);
    %Initialise minstress and maxstress to be very large and very small so it
    %doesnt cause conflicts
    minstress = 10^14;
    maxstress = 0;
    wq = 0;
    %If displaymirror is set to 1, do the neccessary calculations
    if(displaymirror == 1)
        %Set title (with mirror)
        t = ['Deformation at scale factor ', num2str(factor), ' with Mirror von-Mises Stresses Coloured (Not Scaled)'];
        title(t);
        %This part can definitely be more optimised
        %Calculate the mirror deflection matrix
        [sigVM, wq] = analyse(mirrornodes, mirrorproperties, nodes, u, 0, 1, h);
        %Define the grid
        [xq,yq] = meshgrid(-2:h:2, -2:h:2); % define a regular grid
        
        %Loop through the deflection matrix to set it to be a circle
        for yloop=1:length(wq)
            for xloop=1:length(wq)
            %If the xq or yq value is outside the radius of the mirror
            %(Equation of a circle)
                if((xq(xloop, yloop)^2+yq(xloop, yloop)^2) >= mirrorproperties.radius^2)
                    %Set w displacement to NaN and MATLAB will not display
                    %coordinates (other extreme values can give dodgy results)
                    %Thereby forming a circular mirror, which is nice for visual
                    %aid.
                    wq(xloop, yloop) = NaN;
                end
            end 
        end
    else
        %Set title (without mirror)
        t = ['Deformation at scale factor ', num2str(factor),' with Element von-Mises Stresses Coloured (Not Scaled)'];
        title(t);
    end
    
    %Loop through all elements and calculate the max and min VM (to
    %standardise colourbar)
    for c=1:1:len
        i = connections(c, 1);
        j = connections(c, 2);
        m = materialarray(connections(c, 3));
        [sigvm_node1, sigvm_node2] = calculatespaceframeVM(m, nodes, i, j, u);
        minstress = min(minstress, min(sigvm_node1, sigvm_node2));
        maxstress = max(maxstress, max(sigvm_node1, sigvm_node2));
    end
    maxstress
    if(displaymirror == 1)
        %Use Matlab's predefined Jet colourmap
        cmap2 = jet(256);
        
        %Shift the mirror up to it's position (nodes 1->25)
        %Since this is only for visual demonstration, all nodes are displaced
        %by a constant amount (although nodes are at different heights).
        wq = wq*factor+mean(nodes(mirrornodes, 3));
        
        mrror = surf(xq,yq,wq,sigVM/10^6,'FaceAlpha',0.75);
        set(mrror, 'EdgeAlpha',0)
        colormap(cmap2);
        c = colorbar;
        caxis([min(min(sigVM))/10^6 max(max(sigVM))/10^6]);
        ylabel(c,'Max Local Mirror von-Mises Stress (MPa)');
    end
    %% CALCULATE POSITIONS OF DISPLACED NODES
    displacementvector = [];
    for c=1:1:length(u)/6 %(divide by DOF to loop through all displacements)
        %Set the displacements to be multiplied by the scale factor (for
        %visual aid)
       displacementvector = [displacementvector;u((c-1)*6+1)*factor, u((c-1)*6+2)*factor, u((c-1)*6+3)*factor]; 
    end
    %The new position of the node is the initial position + the
    %displacement
    displacednodes = nodes + displacementvector;
    
    %Loop through connections matrix
    for c=1:1:len
        %i and j are node numbers from the element matrix
        i = connections(c, 1);
        j = connections(c, 2);
        
        %set m to be the material corresponding to the element
        m = materialarray(connections(c, 3));
        
        %Generate coordinates of cylinder from node i to node j
        [Xvector,Yvector,Zvector] = transformcylinder(m, displacednodes, i, j);
        %Index to standardise colourbar
        index = 255/(maxstress - minstress);
        [sigvm_node1, sigvm_node2] = calculatespaceframeVM(m, nodes, i, j, u);
        cc1 = lerp((index * (sigvm_node1-minstress) + 1), cmap);
        cc2 = lerp((index * (sigvm_node2-minstress) + 1), cmap);

        %Assign RGB colours to matrix (pointcolors is a 3-dimensional matrix
        %where 3rd dimension refers to RGB channels).
        pointcolors = ones(size(Xvector)) * cc1(1);
        pointcolors(:, :, 2) = ones(size(Xvector)) * cc1(2);
        pointcolors(:, :, 3) = ones(size(Xvector)) * cc1(3);

        pointcolors(2, :, 1) = ones(1, size(Xvector, 2)) * cc2(1);
        pointcolors(2, :, 2) = ones(1, size(Xvector, 2)) * cc2(2);
        pointcolors(2, :, 3) = ones(1, size(Xvector, 2)) * cc2(3);

        %Produce 3d surface plot
        %Mesh for no fill, surf for shading
        surf(Xvector, Yvector, Zvector, pointcolors);
    end
    if(displaymirror == 0)
        %If we don't display the mirror, set the color-axis to be the VM
        %stresses of the elements
        caxis([minstress maxstress]);
        colormap(cmap);
        c = colorbar;
        ylabel(c,'Max Element von-Mises Stress (MPa)');
    end
    hold off;
end

