function [newnodes, newconnections] = subdivide(nodes, connections, materialarray)
%Subdivides element into subdivisionfactor number of elements (1=no subdivision)
%   Takes in connections matrix
%Can use statically allocated matrices, but performance drop not noticeable
%for this problem
    newnodes = nodes;
    newconnections = [];
    for c=1:size(connections, 1)
        i = connections(c, 1);
        j = connections(c, 2);
        %Set i to prevnode
        prevnode = i;
        subdivisionfactor = materialarray(connections(c, 3)).subdivisionfactor;
        %Loop through subdivisions
        for s=1:subdivisionfactor-1
            %Linerarly interpolate node positions
            newnodes = [newnodes;(nodes(j, :)-nodes(i, :))*(1/subdivisionfactor)*s + nodes(i, :)];
            %The nodenumber of the new node
            lennewnodes = size(newnodes, 1);
            %Connect the previous node and the new node
            newconnections = [newconnections;[prevnode lennewnodes connections(c, 3)]];
            %Set the previous node to the current node (for next loop)
            prevnode = lennewnodes;
        end
        %Connect the prevnode to the final node in element
        newconnections = [newconnections;[prevnode j connections(c, 3)]];
    end
end

