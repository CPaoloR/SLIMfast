classdef ManagerDummy < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden)
    end %properties
    properties (Hidden,Dependent)
    end %properties
    properties (Hidden,Transient)
    end %properties
    
    methods
        %% constructor
        function this = ManagerDummy(parent)
            this = this@SuperclassManager(parent);
        end %fun
        
        %%

        %% setter
        
        %% getter
                
        %%
        function close_object(this)
            close_object@SuperclassManager(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@SuperclassManager(this);
        end %fun
    end %methods
    methods (Static)
        function loadObj = loadobj(this)
            loadObj = loadobj@SuperclassManager(this);
        end %fun
    end %methods
end %classdef