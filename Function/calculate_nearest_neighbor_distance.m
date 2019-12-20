function dNN = calculate_nearest_neighbor_distance(srcPnts,queryPnts)
tri = DelaunayTri(srcPnts(:,1),srcPnts(:,2));
idxNN = nearestNeighbor(tri,queryPnts);
dNN = sqrt(sum((srcPnts-queryPnts(idxNN,:)).^2,2));
end %fun