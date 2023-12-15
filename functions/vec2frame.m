function XYZ=vec2frame(a,b,axisNames,debug)
    if size(a,1)<size(a,2)
        a=a';
    end

    if size(b,1)<size(b,2)
        b=b';
    end
    
    ax1=a/norm(a);
    ax2=b-(b'*ax1)*ax1;
    ax2=ax2/norm(ax2);
    ax3=cross(ax1,ax2);
    ax3=ax3/norm(ax3);
    
    inputAxes=axisIndex(axisNames);
    axisIdx=[1 2 3];
    axisIdx(inputAxes)=[];
    
    XYZ(:,inputAxes(1))=ax1;
    XYZ(:,inputAxes(2))=ax2;
    XYZ(:,axisIdx)=ax3;
    
 
    if ~exist('debug','var')
        debug=0;
    end
    
    if debug
        figure;  hold on;
        quiver3(0,0,0,a(1),a(2),a(3));
        quiver3(0,0,0,b(1),b(2),b(3));
        quiver3(0,0,0,XYZ(1,1),XYZ(2,1),XYZ(3,1),'k'); text(XYZ(1,1),XYZ(2,1),XYZ(3,1),'x');
        quiver3(0,0,0,XYZ(1,2),XYZ(2,2),XYZ(3,2),'k'); text(XYZ(1,2),XYZ(2,2),XYZ(3,2),'y');
        quiver3(0,0,0,XYZ(1,3),XYZ(2,3),XYZ(3,3),'k'); text(XYZ(1,3),XYZ(2,3),XYZ(3,3),'z');
        view(3); axis equal; grid on; 
        keyboard;
    end
end

function out=axisIndex(axisNames)

    for i=length(axisNames):-1:1
        switch lower(axisNames{i})
            case 'x'
                out(i)=1;
            case 'y'
                out(i)=2;
            case 'z'
                out(i)=3;
            otherwise
                disp('input must be a character among x, y, z');
        end
    end
end