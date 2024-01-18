function [] = plotstructure(materialarray, mirrornodes, nodes, connections)
%plotstructure Plots the structure based on nodes and connections
%   Takes in connection matrix
    figure;
    hold on;
    daspect([1;1;1]);
    axis([-3 3 -3 3 -1 3]);
    legendentries = [];
    %Loop through connections matrix
    for c=1:1:size(connections, 1)
        i = connections(c, 1);
        j = connections(c, 2);
        m = materialarray(connections(c, 3));
        %m.D = m.D/3;
   %If there is a connection
      %Plot
      
      [Xvector,Yvector,Zvector] = transformcylinder(m, nodes, i, j);

      %Blue
      pointcolors = ones(size(Xvector)) * 207/255;
      pointcolors(:, :, 2) = ones(size(Xvector)) * 240/255;
      pointcolors(:, :, 3) = ones(size(Xvector)) * 252/255;
      mesh(Xvector, Yvector, Zvector, pointcolors);
    end
    %x, y, z axes arrows (need arrow3 library)
    arrow3([0 0 0], [1 0 0],'r', 1, 1, -1, 1, 0.4);
    text(1.2, 0, 0, 'x', 'FontSize', 16, 'Color', 'red');
    arrow3([0 0 0], [0 1 0],'g', 1, 1, -1, 1, 0.4);
    text(0, 1.2, 0, 'y', 'FontSize', 16, 'Color', 'green');
    arrow3([0 0 0], [0 0 1],'b', 1, 1, -1, 1, 0.4);
    text(0, 0, 1.2, 'z', 'FontSize', 16, 'Color', 'blue');
    
    %Plot nodes as green dots over everything else
    for i=length(nodes):-1:1
        if(i <= 25)
            plot3(nodes(i, 1), nodes(i, 2), nodes(i, 3), 'ok');
            text(nodes(i, 1), nodes(i, 2), nodes(i, 3)+0.25, int2str(i), 'FontSize', 12, 'Color', 'black');
        else
            plot3(nodes(i, 1), nodes(i, 2), nodes(i, 3), 'or');
            text(nodes(i, 1), nodes(i, 2), nodes(i, 3)-0.25, int2str(i), 'FontSize', 12, 'Color', 'red');
        end
        [X,Y,Z] = sphere();
        X = X/12;
        Y = Y/12;
        Z = Z/12;
        %Colour mirror nodes black, and all other nodes red
        if(i <= max(mirrornodes))
            %Black
            pointcolors = ones(size(X)) * 0;
            pointcolors(:, :, 2) = ones(size(X)) * 0;
            pointcolors(:, :, 3) = ones(size(X)) * 0;
        else
            %Red
            pointcolors = ones(size(X)) * 1;
            pointcolors(:, :, 2) = ones(size(X)) * 0;
            pointcolors(:, :, 3) = ones(size(X)) * 0;
        end
        X = X + nodes(i, 1);
        Y = Y + nodes(i, 2);
        Z = Z + nodes(i, 3);

        mesh(X, Y, Z, pointcolors);
    end
    for c=1:size(connections, 1)
        i = connections(c, 1);
        j = connections(c, 2);
        nodesum = (nodes(i, :) + nodes(j, :))/2;
        if(c <= 30)
            nodesum(1) = nodesum(1) - 0.1;
            nodesum(3) = nodesum(3) + 0.1;
        elseif(c >= 31 && c < 40)
            nodesum(1) = nodesum(1) + 0.1;
            nodesum(3) = nodesum(3) - 0.1;
        else
            nodesum(3) = nodesum(3) + 0.1;
        end
        %text(nodesum(1), nodesum(2), nodesum(3), num2str(c), 'FontSize', 6, 'Color', 'black');

        %arrow3([nodesum(1)+0.1, nodesum(2), nodesum(3)], [nodesum(1), nodesum(2), nodesum(3)],...
        %        'k', 1, 1, -1, 1, 0.4);
    end
    %Legend has to be here to prevent other stuff displaying on legend
    %legend(strcat('Element ', num2str(legendentries)));
    hold off;
end
