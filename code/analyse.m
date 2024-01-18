function [sigVM, wq] = analyse(mirrornodes, mirrorproperties, nodes, u, display, flag, h)
    %Performs FEM analysis given m, nodes, connections, constrants, forces
    %   Detailed explanation goes here
    if(~exist('h', 'var'))
       h = 0.1; 
    end
    w = [];
    %DISPLACEMENT
    for i=1:1:max(mirrornodes)
         w = [w;u(6*(i-1) + 3)];
    end
    if(flag == 0)
        wq = w;
        sigVM = NaN;
    end
    if(flag == 1)
        x = nodes(mirrornodes,1); % x coordinates of mirror base nodes
        y = nodes(mirrornodes,2); % y coordinates of mirror base nodes
        %% interpolate onto a regular grid
        [xq,yq] = meshgrid(-2:h:2, -2:h:2); % define a regular grid
        wq = griddata(x,y,w,xq,yq,'v4'); % smooth interpolation onto regular grid
        
        [gradX gradY] = gradient(wq,h); % numerical gradients dw/dx and dw/dy
        [curvXX curvXY] = gradient(gradX,h); % numerical gradients d2w/dx^2 and d2w/dxdy
        [curvYX curvYY] = gradient(gradY,h); % numerical gradients d2w/dxdy and d2w/dy^2

        %% stresses on top surface
        sigX = -mirrorproperties.E/(1 - mirrorproperties.nu^2)*mirrorproperties.t/2*(curvXX + mirrorproperties.nu.*curvYY);
        % gradient and curvature % x bending stress
        sigY = -mirrorproperties.E/(1 - mirrorproperties.nu^2)*mirrorproperties.t/2*(mirrorproperties.nu.*curvXX + curvYY); % y bending stress
        tauXY = -mirrorproperties.E/(1 - mirrorproperties.nu^2)*mirrorproperties.t/2*(1 - mirrorproperties.nu).*curvXY; % xy shear stress
        sigVM = sqrt(1/2*((sigX - sigY).^2 + (sigY - 0).^2 + (0 - sigX).^2) ...
            + 3*(tauXY.^2 + 0 + 0)); % von Mises stress
        meanVMstress = 0;
        %Number of gridcells (used to calculate mean)
        cells = 0;
        %Ensure Max Deformation is within mirror radius
        mirrorradius = 2;
        for yloop=1:length(wq)
            for xloop=1:length(wq)
                %If the xq or yq value is outside the radius of the mirror
                %(Equation of a circle)
                if((xq(xloop, yloop)^2+yq(xloop, yloop)^2) > mirrorradius^2)
                    %Set w displacement to NaN and Matlab will not display
                    %coordinates (other extreme values can give dodgy results)
                    %Thereby forming a circular mirror
                    wq(xloop, yloop) = 0;
                    sigVM(xloop, yloop) = 0;
                else %else if within the circle
                    meanVMstress = meanVMstress + sigVM(xloop, yloop);
                    cells = cells + 1;
                end
            end 
        end
        meanVMstress = meanVMstress/cells;
        disp(['Mean Mirror von-Mises Stress: ' num2str(meanVMstress/10^6) 'MPa'])
        
        if(meanVMstress >= mirrorproperties.yieldstress)
          warning('Mean Mirror Von-Mises Stress Above Mirror Yield Strength!'); 
        end
        if(display == 1)
            %% PLOTTING (MODIFIED FROM LEARN)
            figure;
            subplot(1,2,1)
            mesh(xq,yq,wq)
            hold on
            plot3(x,y,w,'o')
            axis equal
            title('Surface visualisation from scattered points')
            xlabel('x coord (m)')
            ylabel('y coord (m)')
            zlabel('vertical displacement (m)')

            subplot(1,2,2)
            contourf(xq,yq,sigVM/1e6,100,'LineColor','none')
            axis equal
            hold on
            c = colorbar;
            title('von Mises stress on top surface')
            xlabel('x coord (m)')
            ylabel('y coord (m)')
            ylabel(c,'stress (MPa)')
        end
    end
end