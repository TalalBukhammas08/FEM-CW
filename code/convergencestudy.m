function [] = convergencestudy(materialarray, mirrornodes, nodes, connections, constraints, forces, stepsize, steps)
%Perform convergence study
%   Iterate through different subdivisions and calculate parameters. Then,
%   calculate the percentage error (point 1 percentage error is from point
%   1->2 etc., so last point doesn't have a percentage error)
    %Doesn't have to start from 1, but okay for this project (can setup as function input).
    subdivisionfactor = 1;
    meanws = [];
    varws = [];
    sigVMs = [];
    varsigVMs = [];
    meanelementssigVM = [];
    varelementssigVM = [];
    
    %Plus one cause can only calculate percentage change until from
    %penultimate to last.
    for subdivisionfactor=1:stepsize:steps+1
        for i=1:length(materialarray)
            materialarray(i).subdivisionfactor = subdivisionfactor;
        end
        [newnodes, newconnections] = subdivide(nodes, connections, materialarray);
        u = calculatedisplacements(materialarray, newnodes, newconnections, constraints, forces, -9.81*4.5);
        [sigVM, wq] = analyse(mirrornodes, 0, nodes, u, 0, 0);
        meanws = [meanws;mean(wq)];
        varws = [varws;var(wq)];
        sigVMs = [sigVMs;mean(sigVM)];
        varsigVMs = [varsigVMs;var(sigVM)];
        
        sigvmelements = 0;
        %Loop through all nodes
        for c=1:size(connections, 1)
            %i refers to first connecting node number and j is the second
            i = connections(c, 1);
            j = connections(c, 2);
            
            %Calculate both max VM stresses
            [sigvm_node1, sigvm_node2] = calculatespaceframeVM(materialarray(connections(c, 3)), nodes, i, j, u);
            %Choose the largest of the two nodes
            sigvmelements = [sigvmelements;max(sigvm_node1, sigvm_node2)];
        end
        meanelementssigVM = [meanelementssigVM;mean(sigvmelements)];
        varelementssigVM = [varelementssigVM;var(sigvmelements)];
        subdivisionfactor = subdivisionfactor + stepsize;
    end
    
    %% PLOT
    figure;
    hold on;
    X = 1:stepsize:subdivisionfactor-1;
    perrormeanws = [];
    perrorvarws = [];
    perrorsigVMs = [];
    perrorvarsigVMs = [];
    perrormeanelementssigVM = [];
    perrorvarelementssigVM = [];
    
    %-1 because last point doesnt have a percentage change
    for i=1:length(X)-1
        perrormeanws = [perrormeanws;(meanws(i+1)-meanws(i))/meanws(i)];
        perrorvarws = [perrorvarws;(varws(i+1)-varws(i))/varws(i)];
        perrorsigVMs = [perrorsigVMs;(sigVMs(i+1)-sigVMs(i))/sigVMs(i)];
        perrorvarsigVMs = [perrorvarsigVMs;(varsigVMs(i+1)-varsigVMs(i))/varsigVMs(i)];
        perrormeanelementssigVM = [perrormeanelementssigVM;(meanelementssigVM(i+1)-meanelementssigVM(i))/meanelementssigVM(i)];
        perrorvarelementssigVM = [perrorvarelementssigVM;(varelementssigVM(i+1)-varelementssigVM(i))/varelementssigVM(i)];
        
    end
    plot(X(1:length(X)-1), abs(perrormeanws) * 100);
    plot(X(1:length(X)-1), abs(perrorvarws) * 100);
    plot(X(1:length(X)-1), abs(perrorsigVMs) * 100);
    plot(X(1:length(X)-1), abs(perrorvarsigVMs) * 100);
    plot(X(1:length(X)-1), abs(perrormeanelementssigVM) * 100);
    plot(X(1:length(X)-1), abs(perrorvarelementssigVM) * 100);
    
    grid minor;
    title('Subdivision Factor vs Magnitude of Percentage Change')
    xlabel('Subdivision Factor');
    ylabel('Magnitude of Percentage Change (%)');
    legend('Mean of Mirror Nodal Displacement', 'Variance of Mirror Nodal Displacement',...
        'Mean of Mirror VM Stresses', 'Variance in Mirror VM Stresses',  'Mean of Element VM Stresses',...
        'Percentage Change in Variance of Element VM Stresses');
    ax = gca;
    ax.YAxis.Exponent = 0;
    hold off;
end
