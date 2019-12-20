function isInside = SML_inside_mask(i,j,mask,actExp,offset)
%calculate linear indices for bins inside
            %arbitrary shaped user defined region of interest
            [imgHeight,imgWidth] = size(mask);
            linMask = find(mask);
            
            %calculate linear indices of bins which contain point            
            [~, row] = histc(transform_orig_to_mag(i,actExp,offset(1)), 1:imgHeight);
            [~, col] = histc(transform_orig_to_mag(j,actExp,offset(2)), 1:imgWidth);

            linCoords = col*imgHeight+row;
            
            isInside = ismembc(linCoords,linMask);
end %fun