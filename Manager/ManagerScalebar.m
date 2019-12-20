classdef ManagerScalebar < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        BarExtent
        BarCtrCoordNorm
        LabelExtent
        LabelCoordNorm
        
        HasScalebar
    end %properties
    properties (Hidden,Dependent)
        Scale
        Unit
        BarSize
        Position
        Color
        UseLabel
        FontSize
        
        Points2px
    end %properties
    properties (Hidden,Transient)
        hBar = nan;
        hLabel = nan;
        hContextmenu
        hDragFrame
        hDragFrameFcn
    end %properties
    
    methods
        %constructor
        function this = ManagerScalebar(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
        end %fun
        function construct_scalebar(this)
            %initialize Scalebar
            
            this.hBar = line([0 1],[0 0],...
                'Color', this.Color, ...
                'LineWidth', this.BarSize,...
                'Hittest','off',...
                'Parent',this.Parent.hImageAx);
            
            if this.UseLabel
                this.hLabel = text(0,0,...
                    [num2str(this.Scale) this.Unit],...
                    'Color', this.Color,...
                    'Fontsize', this.FontSize,...
                    'VerticalAlignment','Bottom',...
                    'HorizontalAlignment','center',...
                    'Hittest','off',...
                    'Parent',this.Parent.hImageAx);
            end %if
            
            update_bar(this)
        end %fun
        
        function initialize_scalebar(this,src)
            switch get(src,'Checked')
                case 'off'
                    set(src,'Checked','on')
                    this.HasScalebar = 1;
                    construct_scalebar(this)
                case 'on'
                    set(src,'Checked','off')
                    
                    this.HasScalebar = 0;
                    delete(this.hBar)
                    if ishandle(this.hLabel)
                        delete(this.hLabel)
                    end %if
            end %switch
        end %fun
        
        function scale = get.Scale(this)
            scale = this.SrcContainer.Scale;
        end %fun
        function unit = get.Unit(this)
            unit = this.SrcContainer.Unit;
        end %fun
        function barsize = get.BarSize(this)
            barsize = this.SrcContainer.BarSize;
        end %fun
        function color = get.Color(this)
            color = this.SrcContainer.Color;
        end %fun
        function uselabel = get.UseLabel(this)
            uselabel = this.SrcContainer.UseLabel;
        end %fun
        function fontsize = get.FontSize(this)
            fontsize = this.SrcContainer.FontSize;
        end %fun
        function position = get.Position(this)
            position = this.SrcContainer.Position;
        end %fun
        
        function points2px = get.Points2px(this)
            set(this.Parent.hImageAx,'Units','points')
            pntSize = get(this.Parent.hImageAx,'position');
            set(this.Parent.hImageAx,'Units','pixels')
            points2px = pntSize(3)/this.Parent.FieldOfView(5)/this.Parent.ActExp;
        end %fun
        
        function change_scale(this)
            answer = inputdlg('Set desired Scale:');
            this.SrcContainer.Scale = str2double(answer);
            
            if ishandle(this.hBar)
                update_bar(this)
                
                if ~strcmp(this.Position,'Free')
                    set_scalebar_position(this)
                end %if
            end %if
        end %fun
        function change_units(this,src)
            this.SrcContainer.Unit = get(src,'Label');
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hBar)
                update_bar(this)
            end %if
        end %fun
        function change_barsize(this,src)
            this.SrcContainer.BarSize = str2double(get(src,'Label'));
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hBar)
                update_bar(this)
            end %if
        end %fun
        function change_labelstate(this,src)
            switch get(src,'Checked')
                case 'off'
                    set(src, 'Checked', 'on')
                    this.SrcContainer.UseLabel = 1;
                    
                    if ishandle(this.hBar)
                        this.hLabel = text(0,0,...
                            [num2str(this.Scale) this.Unit],...
                            'Color', this.Color,...
                            'Fontsize', this.FontSize,...
                            'VerticalAlignment','Bottom',...
                            'HorizontalAlignment','center',...
                            'Hittest','off');
                        labelExt = get(this.hLabel,'Extent');
                        
                        barCtr = this.BarCtrCoordNorm.*...
                            this.Parent.FieldOfView(5:6)*this.Parent.ActExp;
                        this.LabelCoordNorm = [barCtr(1) ...
                            barCtr(2)+labelExt(4)]./...
                            (this.Parent.FieldOfView(5:6)*this.Parent.ActExp);
                        
                        update_bar(this)
                    end %if
                case 'on'
                    set(src, 'Checked', 'off')
                    this.SrcContainer.UseLabel = 0;
                    
                    if ishandle(this.hBar)
                        delete(this.hLabel)
                        
                        update_bar(this)
                    end %if
            end %switch
        end %fun
        function change_labelsize(this,src)
            this.SrcContainer.FontSize = str2double(get(src,'Label'));
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hBar)
                update_bar(this)
            end %if
        end %fun
        function change_position(this,src)
            this.SrcContainer.Position = get(src,'Label');
            
            %update context menu
            set(allchild(get(src, 'Parent')), 'Checked', 'off')
            set(src, 'Checked', 'on')
            
            if ishandle(this.hBar)
                set_scalebar_position(this)
            end %if
        end %fun
        function change_color(this)
            this.SrcContainer.Color = num2str(uisetcolor(this.Color));
            
            if ishandle(this.hBar)
                set(this.hBar,'Color',this.Color)
                
                if this.UseLabel
                    set(this.hLabel,'Color',this.Color)
                end %if
            end %if
        end %fun
        
        function update_bar(this)
            set(this.hBar,...
                'LineWidth', this.BarSize)
            
            calculate_bar_extent(this)
            if this.UseLabel
                update_label(this)
                calculate_label_extent(this)
            end %if
            
            if strcmp(this.Position,'Free')
                barCtr = this.BarCtrCoordNorm.*...
                    this.Parent.FieldOfView(5:6)*this.Parent.ActExp;
                set(this.hBar,...
                    'XData',[1 1]*barCtr(1)+[-1 1]*this.BarExtent(1)/2,...
                    'YData',[1 1]*barCtr(2)+this.LabelExtent(2)+this.BarExtent(2)/2);
                
                if this.UseLabel
                    set(this.hLabel,...
                        'Position',[barCtr(1) ...
                        barCtr(2)+this.LabelExtent(2)]);
                    
                    labelPos = get(this.hLabel,'Position');
                    this.LabelCoordNorm = labelPos(1:2)./...
                        (this.Parent.FieldOfView(5:6)*this.Parent.ActExp);
                end %if
            else
                set_scalebar_position(this)
            end %if
        end %fun
        function update_label(this)
            set(this.hLabel,...
                'String', [num2str(this.Scale) this.Unit],...
                'FontSize', this.FontSize)
        end %fun
        function calculate_bar_extent(this)
            switch this.Unit
                case 'nm'
                    %nanometer
                    suffixFactor = 1;
                case 'µm'
                    %micrometer
                    suffixFactor = 1e3;
                case 'mm'
                    %millimeter
                    suffixFactor = 1e6;
                case 'cm'
                    suffixFactor = 1e7;
                case 'px'
                    suffixFactor = this.Parent.Px2nm/this.Parent.ActExp;
            end %switch
            barwidth = this.Scale*suffixFactor/...
                (this.Parent.Px2nm/this.Parent.ActExp); %[px]
            
            %check that bar width < image width
            if barwidth > this.Parent.FieldOfView(5)*this.Parent.ActExp
                %set barwidth to imagewidth
                barwidth = this.Parent.FieldOfView(5)*this.Parent.ActExp;
                
                this.SrcContainer.Scale = barwidth*...
                    (this.Parent.Px2nm/this.Parent.ActExp)/suffixFactor;
            end %if
            barheight = this.BarSize/this.Points2px;
            
            this.BarExtent = [barwidth barheight];
        end %fun
        function calculate_label_extent(this)
            h = text(0,0,...
                [num2str(this.Scale) this.Unit],...
                'FontSize', this.FontSize,...
                'VerticalAlignment','Bottom',...
                'HorizontalAlignment','center',...
                'Parent',this.Parent.hImageAx);
            extent = get(h,'Extent');
            this.LabelExtent = extent(3:4);
            
            delete(h)
        end %fun
        
        function set_scalebar_position(this)
            %define distance to image border
            dist2borderX = 7.5/this.Points2px;
            dist2borderY = 2.5/this.Points2px;
            
            switch this.SrcContainer.Position
                case 'North-East'
                    if this.UseLabel
                        scalebarWidth = max(this.LabelExtent(1),this.BarExtent(1));
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*...
                            (this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                            dist2borderX-scalebarWidth/2)+...
                            [-this.BarExtent(1)/2 this.BarExtent(1)/2],...
                            'YData', 0.5+[1 1]* ...
                            (dist2borderY+this.LabelExtent(2)+this.BarExtent(2)/2))
                        set(this.hLabel, ...
                            'Position', 0.5+[this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                            dist2borderX-scalebarWidth/2 dist2borderY+this.LabelExtent(2)])
                    else
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*...
                            (this.Parent.FieldOfView(5)*this.Parent.ActExp-dist2borderX)+...
                            [-this.BarExtent(1) 0],...
                            'YData', 0.5+[1 1]* ...
                            (dist2borderY+this.BarExtent(2)/2))
                    end %if
                case 'North-West'
                    if this.UseLabel
                        scalebarWidth = max(this.LabelExtent(1),this.BarExtent(1));
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*(dist2borderX+scalebarWidth/2)+...
                            [-this.BarExtent(1)/2 this.BarExtent(1)/2],...
                            'YData', 0.5+[1 1]*...
                            (dist2borderY+this.LabelExtent(2)+this.BarExtent(2)/2))
                        set(this.hLabel, ...
                            'Position', 0.5+[dist2borderX+scalebarWidth/2 ...
                            dist2borderY+this.LabelExtent(2)])
                    else
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*(dist2borderX)+ ...
                            [0 this.BarExtent(1)],...
                            'YData', 0.5+[1 1]* ...
                            (dist2borderY+this.BarExtent(2)/2))
                    end %if
                case 'South-East'
                    if this.UseLabel
                        scalebarWidth = max(this.LabelExtent(1),this.BarExtent(1));
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*...
                            (this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                            dist2borderX-scalebarWidth/2)+...
                            [-this.BarExtent(1)/2 +this.BarExtent(1)/2],...
                            'YData', 0.5+[1 1]*...
                            (this.Parent.FieldOfView(6)*this.Parent.ActExp-...
                            dist2borderY-this.BarExtent(2)/2))
                        set(this.hLabel, ...
                            'Position', 0.5+[this.Parent.FieldOfView(5)*this.Parent.ActExp-...
                            dist2borderX-scalebarWidth/2 ...
                            this.Parent.FieldOfView(6)*this.Parent.ActExp-...
                            dist2borderY-this.BarExtent(2)])
                    else
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*...
                            (this.Parent.FieldOfView(5)*this.Parent.ActExp-dist2borderX)+...
                            [-this.BarExtent(1) 0],...
                            'YData', 0.5+[1 1]*...
                            (this.Parent.FieldOfView(6)*this.Parent.ActExp-...
                            dist2borderY-this.BarExtent(2)/2))
                    end
                case 'South-West'
                    if this.UseLabel
                        scalebarWidth = max(this.LabelExtent(1),this.BarExtent(1));
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*(dist2borderX+scalebarWidth/2)+...
                            [-this.BarExtent(1)/2 this.BarExtent(1)/2],...
                            'YData', 0.5+[1 1]*...
                            (this.Parent.FieldOfView(6)*this.Parent.ActExp-...
                            dist2borderY-this.BarExtent(2)/2))
                        set(this.hLabel, ...
                            'Position', 0.5+[dist2borderX+scalebarWidth/2 ...
                            this.Parent.FieldOfView(6)*this.Parent.ActExp-...
                            dist2borderY-this.BarExtent(2)])
                    else
                        set(this.hBar, ...
                            'XData',0.5+[1 1]*(dist2borderX)+ ...
                            [0 this.BarExtent(1)],...
                            'YData', 0.5+[1 1]*...
                            (this.Parent.FieldOfView(6)*this.Parent.ActExp-...
                            dist2borderY-this.BarExtent(2)/2))
                    end %if
            end %switch
            
            %save scalebar coordinates
            xdata = get(this.hBar,'XData');
            ydata = get(this.hBar,'YData');
            this.BarCtrCoordNorm = ([xdata(1) ydata(1)]+this.BarExtent/2)./...
                (this.Parent.FieldOfView(5:6)*this.Parent.ActExp);
            
            if this.UseLabel
                this.BarCtrCoordNorm(2) = ...
                    (ydata(1)-this.LabelExtent(2)-this.BarExtent(2)/2)/...
                    (this.Parent.FieldOfView(6)*this.Parent.ActExp);
                
                labelPos = get(this.hLabel,'Position');
                this.LabelCoordNorm = labelPos(1:2)./...
                    (this.Parent.FieldOfView(5:6)*this.Parent.ActExp);
            end %if
        end %fun
        function create_dragable_frame(this,src)
            if ishandle(this.hBar)
                this.SrcContainer.Position = get(src,'Label');
                
                %update contextmenu
                set(allchild(get(src, 'Parent')), 'Checked', 'off')
                
                barPos = [get(this.hBar,'XData') get(this.hBar,'YData')];
                framePos = [barPos(1) barPos(3)-this.BarExtent(2)/2 ...
                    this.BarExtent(1) this.BarExtent(2)];
                if this.UseLabel
                    labelPos = get(this.hLabel,'Position');
                    if this.LabelExtent(1) > this.BarExtent(1)
                        framePos(1) = labelPos(1)-this.LabelExtent(1)/2;
                        framePos(3) = this.LabelExtent(1);
                    end %if
                    framePos(2) = labelPos(2)-this.LabelExtent(2);
                    framePos(4) = framePos(4)+this.LabelExtent(2);
                end %if
                
                this.hDragFrame = imrect(this.Parent.hImageAx,framePos);
                %deactivate resize functionality
                hList = get(this.hDragFrame,'Children');
                set(hList(1:12),'Marker','none','LineStyle','none','ButtonDownFcn',[])
                
                fcn = makeConstrainToRectFcn('imrect',...
                    [0 ceil(this.Parent.FieldOfView(5)*this.Parent.ActExp)]+0.5, ...
                    [0 ceil(this.Parent.FieldOfView(6)*this.Parent.ActExp)]+0.5);
                setPositionConstraintFcn(this.hDragFrame,fcn);
                this.hDragFrameFcn = addNewPositionCallback(...
                    this.hDragFrame,@this.update_scalebar_position);
                
                set(this.Parent.hImageFig,'WindowButtonUpFcn',@(src,evnt)remove_dragable_frame(this))
            end %if
        end %fun
        function update_scalebar_position(this,position)
            xFrameCenter = position(1)+position(3)/2;
            set(this.hBar,'XData',[position(1) position(1)+this.BarExtent(1)],...
                'YData', [position(2) position(2)]+this.BarExtent(2)/2)
            if this.UseLabel
                set(this.hBar,'XData',[xFrameCenter-this.BarExtent(1)/2 xFrameCenter+this.BarExtent(1)/2],...
                    'YData', [position(2) position(2)]+this.LabelExtent(2)+this.BarExtent(2)/2)
                set(this.hLabel,'Position',[xFrameCenter position(2)+this.LabelExtent(2)])
            else
            end %if
        end %fun
        function remove_dragable_frame(this)
            %save scalebar coordinates
            xdata = get(this.hBar,'XData');
            ydata = get(this.hBar,'YData');
            this.BarCtrCoordNorm = ([xdata(1) ydata(1)]+this.BarExtent/2)./...
                (this.Parent.FieldOfView(5:6)*this.Parent.ActExp);
            this.BarCtrCoordNorm(2) = ...
                (ydata(1)-this.LabelExtent(2)-this.BarExtent(2)/2)/...
                (this.Parent.FieldOfView(6)*this.Parent.ActExp);
            if this.UseLabel
                labelPos = get(this.hLabel,'Position');
                this.LabelCoordNorm = labelPos(1:2)./...
                    (this.Parent.FieldOfView(5:6)*this.Parent.ActExp);
            end %if
            
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
            
            cpObj.HasScalebar = 0;
            cpObj.hBar = nan;
            cpObj.hLabel = nan;
            
            if strcmp(cpObj.Position,'Free')
                cpObj.SrcContainer.Position = 'North-East';
            end %if
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerScalebar;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef