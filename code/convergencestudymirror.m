function [] = convergencestudymirror(materialarray, mirrorproperties, mirrornodes, nodes, connections, constraints, forces, subdivisionfactor, initialh, finalh, steps)
%Runs convergence study of the mirror (VM stresses)
    meansigVMs = [];
    
    for i=1:length(materialarray)
        materialarray(i).subdivisionfactor = subdivisionfactor;
    end
    %First, subdivide, then calculate displacements. Keep these constant as
    %doing the convergence study
    [newnodes, newconnections] = subdivide(nodes, connections, materialarray);
    u = calculatedisplacements(materialarray, newnodes, newconnections, constraints, forces, -9.81 * 4.5);
    
    for h=initialh:(finalh-initialh)/steps:finalh
        sigVM = analyse(mirrornodes, mirrorproperties, nodes, u, 0, 1, h);
        meansigVMs = [meansigVMs;mean(mean(sigVM))];
    end
    
    %% PLOT
    figure;
    hold on;
    X = initialh:(finalh-initialh)/steps:finalh;
    X = 1./X';
    perrormeansigVMs = [];

    %Calculate percentage change
    for i=1:length(X)-1
        perrormeansigVMs = [perrormeansigVMs;(meansigVMs(i+1)-meansigVMs(i))/meansigVMs(i)];
    end
    %Plot the magnitude of the percentage change
    plot(X(1:length(X)-1), abs(perrormeansigVMs) * 100);
    
    grid minor;
    title('Grid Spacing vs Magnitude of Percentage Change')
    xlabel('1/(Grid Spacing) (1/h)');
    ylabel('Magnitude of Percentage Change (%)');
    legend( 'Mean of Mirror VM Stresses');
    ax = gca;
    ax.YAxis.Exponent = 0;
    hold off;
end
