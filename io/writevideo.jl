using Images

function writevideo(fname, imgstack;
                    overwrite=true, framerate=30, compat_mode=false)
    # Input validation
    length(size(imgstack)) == 3 || error("input image must have three dimensions")
    if !(eltype(imgstack) <: Color)
        error("element type of input array is $(eltype(imgstack));
         needs to be RGB or Gray")
     end

    # Translate inputs to command line args
    ow = overwrite ? "-y" : ""
    w, h, nframes = size(imgstack)

    if eltype(imgstack) <: RGB
    open(`ffmpeg $ow -f rawvideo -pix_fmt rgb24 -s:v $(w)x$(h)
            -r $framerate -i pipe:0 -vf "transpose=0" $fname`, "w") do out
        for i = 1:nframes
            write(out, convert.(RGB{N0f8}, imgstack[:,:,i]))
        end
    end
    else
        open(`ffmpeg $ow -f rawvideo -pix_fmt gray -s:v $(w)x$(h)
            -r $framerate -i pipe:0 -vf "transpose=0" $fname`, "w") do out
            for i = 1:nframes
                write(out, convert.(Gray{N0f8}, imgstack[:,:,i]))
            end
        end
    end
end
