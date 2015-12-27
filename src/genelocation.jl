
@doc """  download genecode file to data_dir
""" ->
function download_gencode()
    gz_genecode = string(genecode_fl, ".gz")
    cmd = `wget
    ftp://ftp.sanger.ac.uk/pub/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz
    $gene_code_fl`
    run(cmd)
    
    run(`guzip $(gz_genecode) $(genecode_fl)`)
end

@doc """ read gtf file with out header info
""" ->
function read_gtf()
    if !isfile(genecode_fl)
        download_gencode()
    end
    records =  Array{ASCIIString,2}()
    open(genecode_fl) do file
        while !eof(file)
            line = readline(file)
            if line[1] == '#'
                continue
            end
            fields = split(strip(line,'\n'),"\t")
            num_field = length(fields)
            @assert num_field == 9
            push!(records, fields)
        end
    end
    records
end

@doc """ get chr, start, end, gene_name given records
""" ->
function get_gene_mgp(data::Array{ASCIIString,2})
    @assert size(data,2) == 9
    n = size(data,1)
    gene_mgs = @parallel (hcat) for i = 1:n
        get_gene_mpg(data[i,:])
    end
    gene_mgps
end

@doc """ get gene_name, chr, start, end  given a record
         mgp means mutation genome position
""" ->
function get_gene_mgp(record::Array{ASCIIString,1})
    @assert length(record) == 9
    chr = convert(ASCIIString, fields[1])
    st  = convert(ASCIIString, fields[4])
    ed  = convert(ASCIIString, fields[5])
    gene_names = filter(subfield->contains(subfield, "gene_name"), split(fields[end],";"))
    @assert length(gene_names) == 1
    gene_name = split(gene_names[1]," ")[2]
    gene_name = convert(ASCIIString, gene_name)
    vcat(gene_name,chr,st,ed)'
end

@doc """ Given a location, find which gene it is from.
         So the index is (chr,pos)=>genename
         Save it to disk
""" ->
function pos_gene_dict(data::Array{ASCIIString,2})
    @assert size(data,2) == 4
    #TODO check st,eds not intersect
    pos_gene = Dict{Tuple{ASCIIString,Int64}, ASCIIString}()
    for i = 1:size(data,1)
        genename = data[i,1]
        chr      = data[i,2]
        st       = data[i,3]
        ed       = data[i,4]
        for pos = st:ed
            pos_gene[(chr,pos)] = genename
        end
    end
    save(pos_gene_dict_fl, "pos_gene_dict", pos_gene)

    nothing
end

@doc """ build index pos_gene dict
""" ->
function build_pos_gene()
    gtf = read_gtf()
    gene_mgps = get_gene_mgp(gtf)
    pos_gene_dict(gene_mgps)
    
    true
end