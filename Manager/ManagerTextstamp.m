classdef ManagerTextstamp < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Extent
        Coordinate = [0 0];
        
        HasTextstamp
    end %properties
    properties (Hidden,Dependent)
        String
        FontSize
        Position
        Color
        
        Points2px
    end %properties
    properties (Hidden,Transient)
        hTextstamp = nan;
        hContextmenu
        hDragFrame
        hDragFrameFcn
    end %properties
    
    methods
        %constructor
        function this = ManagerTextstamp(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
        end %fun
        function construct_textstamp(this)
            %initialize textstamp
            this.hTextstamp = text(...
                this.Coordinate(1),...
                this.Coordinate(2),...
                this.String,...
                'Color', this.Color,...
                'Fontsize', this.FontSize,...
                'VerticalAlignment','Bottom',...
                'HorizontalAlignment','center',...
                'Hittest','off',...
                'Parent',this.Parent.hImageAx);
            
            update_textstamp(this)
        end %fun
        
        function initialize_textstamp(this,src)
            switch get(src,'Checked')
                case 'off'
                    set(src,'Checked','on')
                    
                    this.HasTextstamp = 1;
                    construct_textstamp(this)
                case 'on'
                    set(src,'Checked','off')
                    
                    this.HasTextstamp = 0;
                    delete(this.hTextstamp)
            end %switch
        end %fun
        
        function string = get.String(this)
            string = this.SrcContainer.String;
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
        
        function points2px = get.Points2px(this)
            set(this.Parent.hImageAx,'Units','inch')
            axSize = get(this.Parent.hImageAx,'position');
            set(this.Parent.hImageAx,'Units','pixels')
            points2px = 72*axSize(4)/this.Parent.FieldOfView(6);
        end %fun
        
        function change_string(this)
            string = inputdlg('Set desired Text:','',1,{this.String});
            
            if isempty(cell2mat(string))
                %do nothing
            else
                this.SrcContainer.String = cell2mat(string);
            end %if
            
            if ishandle(this.hTextstamp)
                update_textstamp(this)
            end %if
        end %fun
        function change_textstampsize(this,src)
            this.SrcContainer.FontSize = str2double(get(src,'Label'));
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hTextstamp)
                update_textstamp(this)
            end %if
        end %fun
        function change_position(this,src)
            this.SrcContainer.Position = get(src,'Label');
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hTextstamp)
                set_textstamp_position(this)
            end %if
        end %fun
        function change_color(this)
            this.SrcContainer.Color = num2str(uisetcolor(this.Color));
            
            if ishandle(this.hTextstamp)
                set(this.hTextstamp,'Color',this.Color)
            end %if
        end %fun
        
        function update_textstamp(this)
            set(this.hTextstamp,...
                'String', this.String,...
                'FontSize', this.FontSize)
            
            calculate_textstamp_extent(this)
            
            if strcmp(this.Position,'Free')
            else
                set_textstamp_position(this)
            end %if
        end %fun
        function calculate_textstamp_extent(this)
            h = text(0,0,...
                this.String,...
                'FontSize', this.FontSize,...
                'VerticalAlignment','Bottom',...
                'HorizontalAlignment','center',...
                'Parent',this.Parent.hImageAx);
            extent = get(h,'Extent');
            this.Extent = extent(3:4);
            
            delete(h)
        end %fun
        
        function set_textstamp_position(this)
            %define distance to image border
            dist2borderX = 7.5/this.Points2px;
            dist2borderY = 2.5/this.Points2px;
            
            switch this.SrcContainer.Position
                case 'North-East'
                    set(this.hTextstamp, ...
                        'Position', [0.5+this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                        dist2borderX-this.Extent(1)/2 ...
                        0.5+dist2borderY+this.Extent(2)])
                case 'North-West'
                    set(this.hTextstamp, ...
                        'Position', [0.5+dist2borderX+this.Extent(1)/2 ...
                        0.5+dist2borderY+this.Extent(2)])
                case 'South-East'
                    set(this.hTextstamp, ...
                        'Position', [0.5+this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                        dist2borderX-this.Extent(1)/2 ...
                        0.5+this.Parent.FieldOfView(6)*this.Parent.ActExp-dist2borderY])
                case 'South-West'
                    set(this.hTextstamp, ...
                        'Position', [0.5+dist2borderX+this.Extent(1)/2 ...
                        0.5+this.Parent.FieldOfView(6)*this.Parent.ActExp-dist2borderY])
            end %switch
            
            %save textstamp coordinates
            this.Coordinate = get(this.hTextstamp,'Position');
        end %fun
        function create_dragable_frame(this,src)
            if ishandle(this.hTextstamp)
                this.SrcContainer.Position = get(src,'Label');
                
                %update contextmenu
                set(allchild(get(src, 'Parent')), 'Checked', 'off')
                
                textstampPos = get(this.hTextstamp,'Position');
                framePos(1) = textstampPos(1)-this.Extent(1)/2;
                framePos(3) = this.Extent(1);
                framePos(2) = textstampPos(2)-this.Extent(2);
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
                    @this.update_textstamp_position);
                
                set(this.Parent.hImageFig,...
                    'WindowButtonUpFcn',@(src,evnt)remove_dragable_frame(this))
            end %if
        end %fun
        function update_textstamp_position(this,position)
            xFrameCenter = position(1)+position(3)/2;
            set(this.hTextstamp,'Position',[xFrameCenter position(2)+this.Extent(2)])
        end %fun
        function remove_dragable_frame(this)
            %save textstamp coordinates
            this.Coordinate = get(this.hTextstamp,'Position');
            
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
            
            cpObj.HasTextstamp = 0;
            cpObj.hTextstamp = nan;
            
            if strcmp(cpObj.Position,'Free')
                cpObj.SrcContainer.Position = 'North-West';
            end %if
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerTextstamp;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef