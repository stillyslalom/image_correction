using DataStructures.OrderedDict, ProgressMeter.@showprogress,
      Images.Gray, FixedPointNumbers

function readcine(fname)
    f = open(fname)
    h = OrderedDict()

    # Check magic number
    read(f, UInt16) == UInt(18755) || error(basename(fname), " is not a .cine file")

    fhtypes = OrderedDict(          # File header
        :HeadSize       => UInt16,
        :Compression    => UInt16,
        :Version        => UInt16,
        :FirstImageIndex => Int32,
        :TotalImages    => UInt32,
        :FirstImageNum  => Int32,
        :ImCount        => UInt32,
        :OffImageHeader => UInt32,
        :OffSetup       => UInt32,
        :OffImageOffsetscl => UInt32,
        :TriggerFrac    => UInt32,
        :TriggerSec     => UInt32
    )
    ihtypes = OrderedDict(          # Image header
        :ImHeadSize     => UInt32,
        :Width          => Int32,
        :Height         => Int32,
        :Planes         => UInt16,
        :BitDepth       => UInt16,
        :Comp           => UInt32,
        :SizeImage      => UInt32,
        :PxPerMX        => UInt32,
        :PxPerMY        => UInt32,
        :ClrUsed        => UInt32,
        :ClrImportant   => UInt32,
        :FPS            => UInt16
    )

    for (ID, headertype) in fhtypes     # Read .cine file header
        h[ID] = read(f, headertype)
    end

    seek(f, h[:OffImageHeader])
    for (ID, headertype) in ihtypes     # Read image header
        h[ID] = read(f, headertype)
    end

    bittype = h[:BitDepth] == 8 ? Gray{N0f8} : Gray{N0f16}
    numframes = h[:ImCount]
    numframes > 0 || error("no images exist in file")

    seek(f, h[:OffImageOffsetscl])
    imlocs = read(f, Int64, numframes)

    seekstart(f)
    i = 1
    while read(f, UInt16) != 1002   # Get location of images
        i += 1
    end
    h[:ImageOffset] = i

    dt = zeros(numframes)
    skip(f, 2)
    for i = 1:numframes     # Calculate dt for each frame
        fracstart = read(f, UInt32)
        secstart  = read(f, UInt32)
        dt[i] = (secstart - h[:TriggerSec]) + ((fracstart - h[:TriggerFrac])/2^32)
    end
    h[:DeltaT] = dt

    img = zeros(bittype, h[:Height], h[:Width], numframes)
    @showprogress .1 "Loading $(basename(fname)) " for i = 1:numframes
        seek(f, imlocs[i])
        skip(f, read(f, UInt32) - 4)
        img[:,:,i] = rotl90(read(f, bittype, h[:Width], h[:Height]))
    end

    close(f)
    return img, h
end
