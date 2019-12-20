classdef ManagerTimestamp < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Extent
        Coordinate = [0 0];
        
        HasTimestamp
    end %properties
    properties (Hidden,Dependent)
        Unit
        FontSize
        Position
        Color
        
        UserIncrement
        Increment
        
        SuffixFactor
        SuffixPrec
        Points2px
    end %properties
    properties (Hidden,Transient)
        hTimestamp = nan;
        hContextmenu
        hDragFrame
        hDragFrameFcn
        hListener
    end %properties
    
    methods
        %constructor
        function this = ManagerTimestamp(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
        end %fun
        function construct_timestamp(this)
            %initialize timestamp
            this.hTimestamp = text(...
                this.Coordinate(1),...
                this.Coordinate(2),...
                sprintf([this.SuffixPrec '%s'],...
                max(get_image_frames_covered(...
                this.Parent,this.Parent.Frame))*...
                this.Parent.Frame2msec*this.SuffixFactor,this.Unit),...
                'Color', this.Color,...
                'Fontsize', this.FontSize,...
                'VerticalAlignment','Bottom',...
                'HorizontalAlignment','center',...
                'Hittest','off',...
                'Parent',this.Parent.hImageAx);
            
            update_timestamp(this)
        end %fun
        
        function initialize_timestamp(this,src)
            switch get(src,'Checked')
                case 'off'
                    set(src,'Checked','on')
                    
                    this.HasTimestamp = 1;
                    construct_timestamp(this)
                case 'on'
                    set(src,'Checked','off')
                    
                    this.HasTimestamp = 0;
                    delete(this.hTimestamp)
            end %switch
        end %fun
        
        function unit = get.Unit(this)
            unit = this.SrcContainer.Unit;
        end %fun
        function fontsize = get.FontSize(this)
            fontsize = this.SrcContainer.FontSize;
        end %fun
        function color = get.Color(this)
            color = this.SrcContainer.Color;
        end %fun
        function position = get.Position(this)
            position = this.SrcContainer.Position;
        end %fun
        
        function userincrement = get.UserIncrement(this)
            userincrement = this.SrcContainer.UserIncrement;
        end %fun
        function increment = get.Increment(this)
            increment = this.SrcContainer.Increment;
        end %fun
        
        function suffixfactor = get.SuffixFactor(this)
            switch this.Unit
                case 'µs'
                    suffixfactor = 1e3;
                case 'ms'
                    suffixfactor = 1;
                case 's'
                    suffixfactor = 1e-3;
                case 'min'
                    suffixfactor = 1/60e3;
                case 'frame'
                    suffixfactor = 1/this.Parent.Frame2msec;
            end %switch
        end %fun
        function suffixprec = get.SuffixPrec(this)
            switch this.Unit
                case 'µs'
                    suffixprec = '%3.0f';
                case 'ms'
                    suffixprec = '%3.0f';
                case 's'
                    suffixprec = '%0.3f';
                case 'min'
                    suffixprec = '%0.3f';
                case 'frame'
                    suffixprec = '%1.0f';
            end %switch
        end %fun
        function points2px = get.Points2px(this)
            set(this.Parent.hImageAx,'Units','points')
            pntSize = get(this.Parent.hImageAx,'position');
            set(this.Parent.hImageAx,'Units','pixels')
            points2px = pntSize(4)/this.Parent.FieldOfView(6);
        end %fun
        
        function set_increment(this,src)
            switch get(src,'Checked')
                case 'off'
                    set(src,'Checked','on')
                    this.SrcContainer.UserIncrement = 1;
                    
                    answer = inputdlg(...
                        'Set desired Increment:',...
                        '',1,{num2str(this.Increment)});
                    if ~isempty(answer)
                        this.SrcContainer.Increment = ...
                            str2double(cell2mat(answer));
                    end %if
                case 'on'
                    set(src,'Checked','off')
                    this.SrcContainer.UserIncrement = 0;
            end %switch
            
            if ishandle(this.hTimestamp)
                update_timestamp(this)
            end %if
        end %fun
        function change_units(this,src)
            this.SrcContainer.Unit = get(src,'Label');
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hTimestamp)
                update_timestamp(this)
            end %if
        end %fun
        function change_timestampsize(this,src)
            this.SrcContainer.FontSize = str2double(get(src,'Label'));
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hTimestamp)
                update_timestamp(this)
            end %if
        end %fun
        function change_position(this,src)
            this.SrcContainer.Position = get(src,'Label');
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hTimestamp)
                set_timestamp_position(this)
            end %if
        end %fun
        function change_color(this)
            this.SrcContainer.Color = num2str(uisetcolor(this.Color));
            
            if ishandle(this.hTimestamp)
                set(this.hTimestamp,'Color',this.Color)
            end %if
        end %fun
        
        function update_timestamp(this)
            if this.UserIncrement
                timestamp =  sprintf([this.SuffixPrec '%s'],...
                    this.Parent.Frame*this.Increment,this.Unit);
            else
                timestamp =  sprintf([this.SuffixPrec '%s'],...
                    max(get_image_frames_covered(...
                    this.Parent,this.Parent.Frame))*...
                    this.Parent.Frame2msec*this.SuffixFactor,this.Unit);
            end %if
            
            set(this.hTimestamp,...
                'String',timestamp,...
                'FontSize', this.FontSize)
            
            calculate_timestamp_extent(this)
            
            if strcmp(this.Position,'Free')
            else
                set_timestamp_position(this)
            end %if
        end %fun
        function calculate_timestamp_extent(this)
            if this.UserIncrement
                timestamp =  sprintf([this.SuffixPrec '%s'],...
                    this.Parent.Frame*this.Increment,this.Unit);
            else
                timestamp =  sprintf([this.SuffixPrec '%s'],...
                    max(get_image_frames_covered(...
                    this.Parent,this.Parent.Frame))*...
                    this.Parent.Frame2msec*this.SuffixFactor,this.Unit);
            end %if
            
            h = text(0,0,...
                timestamp,...
                'FontSize', this.FontSize,...
                'VerticalAlignment','Bottom',...
                'HorizontalAlignment','center',...
                'Parent',this.Parent.hImageAx);
            extent = get(h,'Extent');
            this.Extent = extent(3:4);
            
            delete(h)
        end %fun
        
        function set_timestamp_position(this)
            %define distance to image border
            dist2borderX = 7.5/this.Points2px;
            dist2borderY = 2.5/this.Points2px;
            
            switch this.SrcContainer.Position
                case 'North-East'
                    set(this.hTimestamp, ...
                        'Position', [0.5+this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                        dist2borderX-this.Extent(1)/2 ...
                        0.5+dist2borderY+this.Extent(2)])
                case 'North-West'
                    set(this.hTimestamp, ...
                        'Position', [0.5+dist2borderX+this.Extent(1)/2 ...
                        0.5+dist2borderY+this.Extent(2)])
                case 'South-East'
                    set(this.hTimestamp, ...
                        'Position', [0.5+this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                        dist2borderX-this.Extent(1)/2 ...
                        0.5+this.Parent.FieldOfView(6)*this.Parent.ActExp-dist2borderY])
                case 'South-West'
                    set(this.hTimestamp, ...
                        'Position', [0.5+dist2borderX+this.Extent(1)/2 ...
                        0.5+this.Parent.FieldOfView(6)*this.Parent.ActExp-dist2borderY])
            end %switch
            
            %save timestamp coordinates
            this.Coordinate = get(this.hTimestamp,'Position');
        end %fun
        function create_dragable_frame(this,src)
            if ishandle(this.hTimestamp)
                this.SrcContainer.Position = get(src,'Label');
                
                %update contextmenu
                set(allchild(get(src, 'Parent')), 'Checked', 'off')
                
                timestampPos = get(this.hTimestamp,'Position');
                framePos(1) = timestampPos(1)-this.Extent(1)/2;
                framePos(3) = this.Extent(1);
                framePos(2) = timestampPos(2)-this.Extent(2);
                framePos(4) = this.Extent(2);
                
                this.hDragFrame = imrect(this.Parent.hImageAx,framePos);
                %deactivate resize functionality
                hList = get(this.hDragFrame,'Children');
                set(hList(1:12),'Marker','none','LineStyle','none','ButtonDownFcn',[])
                
                fcn = makeConstrainToRectFcn('imrect',...
                    [0 ceil(this.Parent.FieldOfView(5)*this.Parent.ActExp)]+0.5, ...
                    [0 ceil(this.Parent.FieldOfView(6)*this.Parent.ActExp)]+0.5);
                setPositionConstraintFcn(this.hDragFrame,fcn);
                this.hDragFrameFcn = addNewPositionCallback(this.hDragFrame,...
                    @this.update_timestamp_position);
                
                set(this.Parent.hImageFig,'WindowButtonUpFcn',...
                    @(src,evnt)remove_dragable_frame(this))
            end %if
        end %fun
        function update_timestamp_position(this,position)
            xFrameCenter = position(1)+position(3)/2;
            set(this.hTimestamp,...
                'Position',[xFrameCenter position(2)+this.Extent(2)])
        end %fun
        function remove_dragable_frame(this)
            %save timestamp coordinates
            this.Coordinate = get(this.hTimestamp,'Position');
            
            %destroy dragable frame
            removeNewPositionCallback(this.hDragFrame,this.hDragFrameFcn)
            delete(this.hDragFrame)
            set(this.Parent.hImageFig,'WindowButtonUpFcn',[])
            set(this.Parent.hImageFig, 'Pointer', 'arrow');
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
            
            cpObj.HasTimestamp = 0;
            cpObj.hTimestamp = nan;
            
            if strcmp(cpObj.Position,'Free')
                cpObj.SrcContainer.Position = 'South-West';
            end %if
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerTimestamp;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef