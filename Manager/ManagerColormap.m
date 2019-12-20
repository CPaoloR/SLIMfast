classdef ManagerColormap < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden,Dependent)
        Colormapping
    end %properties
    properties (Hidden,Transient)
        hFig = nan;
    end %properties
    
    methods
        %% constructor
        function this = ManagerColormap(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
        end %fun
        
        %%
        function adjust_colormap(this)
            %check if image is indexed
            if size(get(this.Parent.hImage,'Cdata'),3) == 3
                waitfor(errordlg('Colormap Tool is not supported for True Color Images',''))
                return
            end %if
            
            %check if gui already open
            if ishandle(this.hFig)
                if this.hFig.isValid()
                    waitfor(msgbox('COLORMAP SERIES MANAGER already open','INFO','help','modal'))
                    return
                end %if
            end %if
            
            colormapeditor
            
            objEditor = getappdata(0,'CMEditor');
            this.hFig = get(objEditor,'Frame');
            this.hFig.setTitle('COLORMAP MANAGER')
            this.hFig.setForeground(...
                java.awt.Color(...
                this.Parent.FamilyColor(1),...
                this.Parent.FamilyColor(2),...
                this.Parent.FamilyColor(3)))
            set(this.hFig,'WindowLostFocusCallback',...
                @(src,evnt)store_colormap(this));
        end %fun
        function store_colormap(this)
            this.SrcContainer.Colormapping = colormap(this.Parent.hImageAx);
%             close_object(this)
        end %fun
        
        %% setter
        
        %% getter
        function colormap = get.Colormapping(this)
            colormap = this.SrcContainer.Colormapping;
        end %fun
        
        %%
        function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassManager(this);
        end %fun
        function close_object(this)
            if ishandle(this.hFig)
                validate(this.hFig)
                if isValid(this.hFig)
                    close(this.hFig)
                end %if
            end %if
            this.hFig = nan;
        end %fun
        function delete_object(this)
            delete_object@SuperclassManager(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@SuperclassManager(this);
            
            cpObj.hFig = nan;
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerColormap;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef