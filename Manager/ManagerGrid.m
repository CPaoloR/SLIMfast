classdef ManagerGrid < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden,Dependent)
        UseGrid
        GridMode
        GridLineColor
        GridLineWidth
        GridRectWidth
        GridRectHeight
        GridHexArea
    end %properties
    properties (Hidden,Transient)
        hGrid
        objTri
    end %properties
    
    methods
        %% constructor
        function this = ManagerGrid(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
            
            if nargin > 0
%             this.SrcContainer.GridLineColor = ...
%                 str2num(this.GridLineColor);
            this.SrcContainer.GridLineWidth = max(0.5,min(5,...
                round(this.GridLineWidth+0.5-eps)-0.5)); %[0.5:0.5:5]
            end %if
        end %fun
        
        %%
        function show_grid(this,src)
            if strcmp(get(src,'Checked'),'on')
                set(src,'Checked','off')
                this.SrcContainer.UseGrid = 0;
                
                delete(this.hGrid)
                this.hGrid = [];
            else
                set(allchild(get(src,'Parent')),'Checked','off')
                set(src,'Checked','on')
                
                this.SrcContainer.UseGrid = 1;
                
                if ~isempty(this.hGrid) &&...
                        all(ishandle(this.hGrid))
                    delete(this.hGrid)
                end %if
                
                this.SrcContainer.GridMode = get(src,'Label');
                
                actExp = this.Parent.ActExp;
                px2nm = this.Parent.Px2nm;
                switch this.GridMode
                    case 'Uniform Rectangular'
                        answer = inputdlg(...
                            {'Set desiered rectangular width [µm]','Set desiered rectangular height [µm]'},'',...
                            1,{num2str(this.GridRectWidth),num2str(this.GridRectHeight)});
                        if ~isempty(answer)
                            this.SrcContainer.GridRectWidth = str2double(answer{1});
                            if this.GridRectWidth > (this.Parent.FieldOfView(5)*...
                                    actExp)*px2nm/1000;
                                this.SrcContainer.GridRectWidth = ...
                                    (this.Parent.FieldOfView(5)*actExp)*px2nm/1000;
                            end %if
                            this.SrcContainer.GridRectHeight = str2double(answer{2});
                            if this.GridRectHeight > (this.Parent.FieldOfView(6)*...
                                    actExp)*px2nm/1000;
                                this.SrcContainer.GridRectHeight = ...
                                    (this.Parent.FieldOfView(6)*actExp)*px2nm/1000;
                            end %if
                            
                            diameterX = this.GridRectWidth*1000/px2nm*actExp;
                            diameterY = this.GridRectHeight*1000/px2nm*actExp;
                            dx = [diameterX/2; -diameterX/2; -diameterX/2; diameterX/2];
                            dy = [-diameterY/2; -diameterY/2; diameterY/2; diameterY/2];
                            
                            numX = this.Parent.FieldOfView(5)*actExp/diameterX;
                            if rem(numX,1) == 0
                                x = (diameterX:diameterX:numX*diameterX)+0.5;
                            else
                                extX = diameterX-(numX-floor(numX))*diameterX;
                                numX = floor(numX) + 1;
                                x = (diameterX:diameterX:numX*diameterX)+0.5;
                                x = x-extX/2;
                            end %if
                            numY = this.Parent.FieldOfView(6)*actExp/diameterY;
                            if rem(numY,1) == 0
                                y = (diameterY:diameterY:numY*diameterY)+0.5;
                            else
                                extY = (numY-floor(numY))*diameterY;
                                numY = floor(numY) + 1;
                                y = (diameterY:diameterY:numY*diameterY)+0.5;
                                y = y-(diameterY-extY)/2;
                            end %if
                            
                            [X Y] = meshgrid(x-diameterX/2,y-diameterY/2);
                            X = repmat(X(:),1,4).';
                            Y = repmat(Y(:),1,4).';
                            
                            pos = [X(:) Y(:)];
                            
                            vertices = [pos(:,1) pos(:,2)]+...
                                [repmat(dx,numX*numY,1) repmat(dy,numX*numY,1)];
                            faces = reshape(1:(numX*numY)*4,4,[]).';
                            
                            this.hGrid = patch(...
                                'Parent', this.Parent.hImageAx,...
                                'Faces',faces,...
                                'Vertices',vertices,...
                                'FaceColor','none',...
                                'EdgeColor',this.GridLineColor,...
                                'LineWidth', this.GridLineWidth,...
                                'Hittest','off');
                        end %if
                    case 'Uniform Hexagonal'
                        answer = inputdlg('Set desired Hexagone Area [µm^2]',...
                            '',1,{num2str(this.GridHexArea)});
                        if ~isempty(answer)
                            this.SrcContainer.GridHexArea = str2double(answer);
                            radius = sqrt(this.GridHexArea*2/3/sqrt(3))*...
                                1000/px2nm*actExp;
                            
                            dx(:,1) = cosd(0:60:300)*radius;
                            dy(:,1) = sind(0:60:300)*radius;
                            
                            numX = this.Parent.FieldOfView(5)*actExp/(1.5*dx(1));
                            if rem(numX,1) == 0
                                x = ((1.5*dx(1)):(1.5*dx(1)):numX*(1.5*dx(1)))+0.5;
                            else
                                extX = (1.5*dx(1))-(numX-floor(numX))*(1.5*dx(1));
                                numX = floor(numX) + 1;
                                x = ((1.5*dx(1)):(1.5*dx(1)):numX*(1.5*dx(1)))+0.5;
                                x = x-extX/2;
                            end %if
                            numY = this.Parent.FieldOfView(6)*actExp/(2*dy(2));
                            if rem(numY,1) == 0
                                y = ((2*dy(2)):(2*dy(2)):numY*(2*dy(2)))+0.5;
                            else
                                extY = (numY-floor(numY))*(2*dy(2));
                                numY = floor(numY) + 1;
                                y = ((2*dy(2)):(2*dy(2)):numY*(2*dy(2)))+0.5;
                                y = y-((2*dy(2))-extY)/2;
                            end %if
                            
                            [X Y] = meshgrid(x-0.75*dx(1),y-dy(2));
                            X = repmat(X(:),1,6).';
                            Y(:,2:2:end) = Y(:,2:2:end)+dy(2);
                            Y = repmat(Y(:),1,6).';
                            
                            pos = [X(:) Y(:)];
                            
                            vertices = [pos(:,1) pos(:,2)]+...
                                [repmat(dx,numX*numY,1) repmat(dy,numX*numY,1)];
                            faces = reshape(1:(numX*numY)*6,6,[]).';
                            
                            this.hGrid = patch(...
                                'Parent', this.Parent.hImageAx,...
                                'Faces',faces,...
                                'Vertices',vertices,...
                                'FaceColor','none',...
                                'EdgeColor',this.GridLineColor,...
                                'LineWidth', this.GridLineWidth,...
                                'Hittest','off');
                        end %if
                    case {'Delaunay Triangulation' 'Voronoi Cell'}
                        switch class(this.Parent)
                            case 'ClassRaw'
                                settings = struct(...
                                    'mask', circshift(this.Parent.Maskdata,[-1 -1]),...
                                    'height',this.Parent.objImageFile.ChannelHeight,....
                                    'width',this.Parent.objImageFile.ChannelWidth,...
                                    'winY',this.Parent.objLocSettings.WinY,...
                                    'winX',this.Parent.objLocSettings.WinX,...
                                    'radiusPSF',this.Parent.objLocSettings.RadiusPSF,...
                                    'errRate',this.Parent.objLocSettings.ErrRate);
                                
                                [~, listGuess, ~] = ...
                                    calculate_hypothesis_map(this.Parent.RawImagedata,settings);
                                x = listGuess(:,3)+1-(this.Parent.FieldOfView(1)-0.5);
                                y = listGuess(:,2)+1-(this.Parent.FieldOfView(2)-0.5);
                            case 'ClassLocalization'
                                good = ismembc(this.Parent.Data.Time,...
                                    get_image_frames_covered(this.Parent,this.Parent.Frame));
                                x = (this.Parent.Data.Position_X(good)*actExp-...
                                    (this.Parent.FieldOfView(1)*actExp-0.5));
                                y = (this.Parent.Data.Position_Y(good)*actExp-...
                                    (this.Parent.FieldOfView(2)*actExp-0.5));
                        end %switch
                        this.objTri = DelaunayTri(x,y);
                        
                        switch this.GridMode
                            case 'Delaunay Triangulation'
                                this.hGrid = triplot(this.objTri,...
                                    'Color',this.GridLineColor,...
                                    'LineWidth', this.GridLineWidth,...
                                    'Hittest','off');
                            case 'Voronoi Cell'
                                this.hGrid = voronoi(this.Parent.hImageAx,x,y);
                                set(this.hGrid,...
                                    'Color',this.GridLineColor,...
                                    'LineWidth', this.GridLineWidth,...
                                    'Hittest','off')
                        end %switch
                end %switch
                
                %put grid just above image
                uistack(this.hGrid,'bottom')
                uistack(this.hGrid,'up')
            end %if
        end %fun
        function update_grid(this)
            actExp = this.Parent.ActExp;
            px2nm = this.Parent.Px2nm;
            
            switch this.GridMode
                case 'Uniform Rectangular'
                    diameterX = this.GridRectWidth*1000/px2nm*actExp;
                    diameterY = this.GridRectHeight*1000/px2nm*actExp;
                    dx = [diameterX/2; -diameterX/2; -diameterX/2; diameterX/2];
                    dy = [-diameterY/2; -diameterY/2; diameterY/2; diameterY/2];
                    
                    numX = this.Parent.FieldOfView(5)*actExp/diameterX;
                    if rem(numX,1) == 0
                        x = (diameterX:diameterX:numX*diameterX)+0.5;
                    else
                        extX = diameterX-(numX-floor(numX))*diameterX;
                        numX = floor(numX) + 1;
                        x = (diameterX:diameterX:numX*diameterX)+0.5;
                        x = x-extX/2;
                    end %if
                    numY = this.Parent.FieldOfView(6)*actExp/diameterY;
                    if rem(numY,1) == 0
                        y = (diameterY:diameterY:numY*diameterY)+0.5;
                    else
                        extY = (numY-floor(numY))*diameterY;
                        numY = floor(numY) + 1;
                        y = (diameterY:diameterY:numY*diameterY)+0.5;
                        y = y-(diameterY-extY)/2;
                    end %if
                    
                    [X Y] = meshgrid(x-diameterX/2,y-diameterY/2);
                    X = repmat(X(:),1,4).';
                    Y = repmat(Y(:),1,4).';
                    
                    pos = [X(:) Y(:)];
                    
                    vertices = [pos(:,1) pos(:,2)]+...
                        [repmat(dx,numX*numY,1) repmat(dy,numX*numY,1)];
                    faces = reshape(1:(numX*numY)*4,4,[]).';
                    
                    if ~isempty(this.hGrid) &&...
                            all(ishandle(this.hGrid))
                        delete(this.hGrid)
                    end %if
                    this.hGrid = patch(...
                        'Parent', this.Parent.hImageAx,...
                        'Faces',faces,...
                        'Vertices',vertices,...
                        'FaceColor','none',...
                        'EdgeColor',this.GridLineColor,...
                        'LineWidth', this.GridLineWidth,...
                        'Hittest','off');
                case 'Uniform Hexagonal'
                    radius = sqrt(this.GridHexArea*2/3/sqrt(3))*1000/px2nm*actExp;
                    dx(:,1) = cosd(0:60:300)*radius;
                    dy(:,1) = sind(0:60:300)*radius;
                    
                    numX = this.Parent.FieldOfView(5)*actExp/(1.5*dx(1));
                    if rem(numX,1) == 0
                        x = ((1.5*dx(1)):(1.5*dx(1)):numX*(1.5*dx(1)))+0.5;
                    else
                        extX = (1.5*dx(1))-(numX-floor(numX))*(1.5*dx(1));
                        numX = floor(numX) + 1;
                        x = ((1.5*dx(1)):(1.5*dx(1)):numX*(1.5*dx(1)))+0.5;
                        x = x-extX/2;
                    end %if
                    numY = this.Parent.FieldOfView(6)*actExp/(2*dy(2));
                    if rem(numY,1) == 0
                        y = ((2*dy(2)):(2*dy(2)):numY*(2*dy(2)))+0.5;
                    else
                        extY = (numY-floor(numY))*(2*dy(2));
                        numY = floor(numY) + 1;
                        y = ((2*dy(2)):(2*dy(2)):numY*(2*dy(2)))+0.5;
                        y = y-((2*dy(2))-extY)/2;
                    end %if
                    
                    [X Y] = meshgrid(x-0.75*dx(1),y-dy(2));
                    X = repmat(X(:),1,6).';
                    Y(:,2:2:end) = Y(:,2:2:end)+dy(2);
                    Y = repmat(Y(:),1,6).';
                    
                    pos = [X(:) Y(:)];
                    
                    vertices = [pos(:,1) pos(:,2)]+...
                        [repmat(dx,numX*numY,1) repmat(dy,numX*numY,1)];
                    faces = reshape(1:(numX*numY)*6,6,[]).';
                    
                    if ~isempty(this.hGrid) &&...
                            all(ishandle(this.hGrid))
                        delete(this.hGrid)
                    end %if
                    this.hGrid = patch(...
                        'Parent', this.Parent.hImageAx,...
                        'Faces',faces,...
                        'Vertices',vertices,...
                        'FaceColor','none',...
                        'EdgeColor',this.GridLineColor,...
                        'LineWidth', this.GridLineWidth,...
                        'Hittest','off');
                case {'Delaunay Triangulation' 'Voronoi Cell'}
                    switch class(this.Parent)
                        case 'ClassRaw'
                            settings = struct(...
                                'mask', circshift(this.Parent.Maskdata,[-1 -1]),...
                                'height',this.Parent.objImageFile.ChannelHeight,....
                                'width',this.Parent.objImageFile.ChannelWidth,...
                                'winY',this.Parent.objLocSettings.WinY,...
                                'winX',this.Parent.objLocSettings.WinX,...
                                'radiusPSF',this.Parent.objLocSettings.RadiusPSF,...
                                'errRate',this.Parent.objLocSettings.ErrRate);
                            
                            [~, listGuess, ~] = ...
                                calculate_hypothesis_map(this.Parent.RawImagedata,settings);
                            x = listGuess(:,3)+1-(this.Parent.FieldOfView(1)-0.5);
                            y = listGuess(:,2)+1-(this.Parent.FieldOfView(2)-0.5);
                        case 'ClassLocalization'
                            good = ismembc(this.Parent.Data.Time,...
                                get_image_frames_covered(this.Parent,this.Parent.Frame));
                            x = (this.Parent.Data.Position_X(good)*...
                                actExp-(this.Parent.FieldOfView(1)*actExp-0.5));
                            y = (this.Parent.Data.Position_Y(good)*...
                                actExp-(this.Parent.FieldOfView(2)*actExp-0.5));
                    end %switch
                    this.objTri.X = [x y];
                    
                    if ~isempty(this.hGrid) &&...
                            all(ishandle(this.hGrid))
                        delete(this.hGrid)
                    end %if
                    
                    switch this.GridMode
                        case 'Delaunay Triangulation'
                            this.hGrid = triplot(this.objTri,...
                                'Color',this.GridLineColor,...
                                'LineWidth', this.GridLineWidth,...
                                'Hittest','off');
                        case 'Voronoi Cell'
                            this.hGrid = voronoi(this.Parent.hImageAx,x,y);
                            set(this.hGrid,...
                                'Color',this.GridLineColor,...
                                'LineWidth', this.GridLineWidth,...
                                'Hittest','off')
                    end %switch
            end %switch
            
            uistack(this.hGrid,'bottom')
            uistack(this.hGrid,'up')
        end %fun
        
        %% setter
        function set_grid_line_color(this)
            this.SrcContainer.GridLineColor = uisetcolor(this.GridLineColor);
            switch this.GridMode
                case {'Uniform Rectangular' 'Uniform Hexagonal'}
                    set(this.hGrid,'EdgeColor',this.GridLineColor)
                case {'Delaunay Triangulation' 'Voronoi Cell'}
                    set(this.hGrid,...
                        'Color',this.GridLineColor)
            end %switch
        end %fun
        function set_grid_line_width(this,src)
            set_contextmenu_state(src,1)
            
            this.SrcContainer.GridLineWidth = str2double(get(src,'Label'));
            set(this.hGrid,...
                'LineWidth',this.GridLineWidth)
        end %fun
        
        %% getter
        function usegrid = get.UseGrid(this)
            usegrid = this.SrcContainer.UseGrid;
        end %fun
        function gridmode = get.GridMode(this)
            gridmode = this.SrcContainer.GridMode;
        end %fun
        function gridrectwidth = get.GridRectWidth(this)
            gridrectwidth = this.SrcContainer.GridRectWidth;
        end %fun
        function gridrectheight = get.GridRectHeight(this)
            gridrectheight = this.SrcContainer.GridRectHeight;
        end %fun
        function gridhexarea = get.GridHexArea(this)
            gridhexarea = this.SrcContainer.GridHexArea;
        end %fun
        function gridlinecolor = get.GridLineColor(this)
            gridlinecolor = this.SrcContainer.GridLineColor;
        end %fun
        function gridlinewidth = get.GridLineWidth(this)
            gridlinewidth = this.SrcContainer.GridLineWidth;
        end %fun
        
        %%
        function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassManager(this);
        end %fun
        function close_object(this)
        end %fun
        function delete_object(this)
            delete_object@SuperclassManager(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@SuperclassManager(this);
            
            cpObj.hGrid = [];
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerGrid;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef