classdef DataExchange < handle
    %DATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data
    end
    
    methods
        function obj = DataExchange()
        end
        
        function obj = setData(obj, data)
            obj.data = data;
        end
    end
end

