# sz = size(img)

# xx = LinRange(mapcoords["minLat"],mapcoords["maxLat"],sz[1])
# yy = LinRange(mapcoords["minLon"],mapcoords["maxLon"],sz[2])

# x = ones(size(img,1),1)
# y = ones(size(img,2),1)
# z = -mapcoords["maxDepth"] * ones((size(img,1)),(size(img,2)))

# for i = 1:length(x)
#     x[i] = xx[i]
# end

# for i = 1:length(y)
#     y[i] = yy[i]
# end


#surface!(ga, lonmin..lonmax, latmin..latmax, ones(size(img)...); color = img, shading = false).