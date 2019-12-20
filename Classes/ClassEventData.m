classdef ClassEventData < event.EventData
   properties
      Value
   end

   methods
      function evntData = ClassEventData(value)
         evntData.Value = value;
      end
   end
end