using Random
export customop,
xavier_init,
load_op_and_grad,
load_op,
compile_op,
use_gpu,
test_jacobian,
install,
load_system_op

"""
    xavier_init(size, dtype=Float64)

Returns a matrix of size `size` and its values are from Xavier initialization. 
"""
function xavier_init(size, dtype=Float64)
    in_dim = size[1]
    xavier_stddev = 1. / sqrt(in_dim / 2.)
    return randn(dtype, size...)*xavier_stddev
end

############### custom operators ##################
function cmake(DIR::String="..")
    ENV_ = copy(ENV)
    if haskey(ENV_, "LD_LIBRARY_PATH")
        ENV_["LD_LIBRARY_PATH"] = ENV["LD_LIBRARY_PATH"]*":$LIBDIR"
    else
        ENV_["LD_LIBRARY_PATH"] = LIBDIR
    end
    if Sys.islinux()
        run(setenv(`$CMAKE -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX $DIR`, ENV_))
    else
        run(setenv(`$CMAKE $DIR`, ENV_))
    end
end

function make()
    ENV_ = copy(ENV)
    if haskey(ENV_, "LD_LIBRARY_PATH")
        ENV_["LD_LIBRARY_PATH"] = ENV["LD_LIBRARY_PATH"]*":$LIBDIR"
    else
        ENV_["LD_LIBRARY_PATH"] = LIBDIR
    end
    run(setenv(`$MAKE -j`, ENV_))
end

load_op_dict = Dict{Tuple{String, String}, PyObject}()
load_op_grad_dict = Dict{Tuple{String, String}, PyObject}()


"""
    compile_op(oplibpath::String; check::Bool=false)

Compile the library operator by force.
"""
function compile_op(oplibpath::String; check::Bool=false)
    PWD = pwd()
    if splitext(oplibpath)[2]==""
        oplibpath = abspath(oplibpath * (Sys.islinux() ? 
                        ".so" : Sys.isapple() ? ".dylib" : ".dll"))
    end
    if check && isfile(oplibpath)
        return 
    end
    DIR, FILE = splitdir(oplibpath)
    if !isdir(DIR); mkdir(DIR); end 
    cd(DIR)
    try
        cmake()
        make()
    catch
        @warn("Compiling not successful. Instruction: Check $oplibpath")
    finally
        cd(PWD)
    end
end

@doc """
    load_op(oplibpath::String, opname::String)

Loads the operator `opname` from library `oplibpath`.
"""
function load_op(oplibpath::String, opname::String)
    if splitext(oplibpath)[2]==""
        oplibpath = abspath(oplibpath * (Sys.islinux() ? 
                        ".so" : Sys.isapple() ? ".dylib" : ".dll"))
    end
    oplibpath = abspath(oplibpath)
    if haskey(load_op_dict, (oplibpath,opname))
        return load_op_dict[(oplibpath,opname)]
    end

    if !isfile(oplibpath)
        error("File $oplibpath does not exist. Instruction:\nRunning `compile_op(oplibpath)` to compile the library first.")
    end
    fn_name = opname*randstring(8)
py"""
import tensorflow as tf
lib$$fn_name = tf.load_op_library($oplibpath)
"""
    lib = py"lib$$fn_name"
    s = getproperty(lib, opname)
    load_op_dict[(oplibpath,opname)] = s
    printstyled("Load library operator: $oplibpath ==> $opname\n", color=:green)
    return s
end

@doc """
    load_op_and_grad(oplibpath::String, opname::String; multiple::Bool=false)

Loads the operator `opname` from library `oplibpath`; gradients are also imported. 
If `multiple` is true, the operator is assumed to have multiple outputs. 
"""
function load_op_and_grad(oplibpath::String, opname::String; multiple::Bool=false)
    if splitext(oplibpath)[2]==""
        oplibpath = oplibpath * (Sys.islinux() ? 
                        ".so" : Sys.isapple() ? ".dylib" : ".dll")
    end
    oplibpath = abspath(oplibpath)
    if haskey(load_op_grad_dict, (oplibpath,opname))
        return load_op_grad_dict[(oplibpath,opname)]
    end
    if !isfile(oplibpath)
        error("File $oplibpath does not exist. Instruction:\nRunning `compile_op(oplibpath)` to compile the library first.")
    end
    
    opname_grad = opname*"_grad"
    fn_name = opname*randstring(8)
if !multiple
py"""
import tensorflow as tf
lib$$fn_name = tf.load_op_library($oplibpath)
@tf.custom_gradient
def $$fn_name(*args):
    u = lib$$fn_name.$$opname(*args)
    def grad(dy):
        return lib$$fn_name.$$opname_grad(dy, u, *args)
    return u, grad
"""
else
py"""
import tensorflow as tf
lib$$fn_name = tf.load_op_library($oplibpath)
@tf.custom_gradient
def $$fn_name(*args):
    u = lib$$fn_name.$$opname(*args)
    def grad(*dy):
        dy = [y for y in dy if y is not None and y.dtype in [tf.float64, tf.float32]] # only float64 and float32 can backpropagate gradients
        return lib$$fn_name.$$opname_grad(*dy, *u, *args)
    return u, grad
"""
end
        s = py"$$fn_name"
        load_op_grad_dict[(oplibpath,opname)] = s
        printstyled("Load library operator (with gradient): $oplibpath ==> $opname\n", color=:green)
        return s
end

"""
    load_system_op(s::String, oplib::String, grad::Bool=true)

Loads custom operator from CustomOps directory (shipped with ADCME instead of TensorFlow)
For example 
```
s = "SparseOperator"
oplib = "libSO"
grad = true
```
this will direct Julia to find library `CustomOps/SparseOperator/libSO.dylib` on MACOSX
"""
function load_system_op(s::String, oplib::String, opname::String, grad::Bool=true; 
    return_str::Bool=false, multiple::Bool=false)
    dir = joinpath(joinpath("$(@__DIR__)", "../deps/CustomOps"), s)
    if !isdir(dir)
        error("Folder for the operator $s does not exist: $dir")
    end
    oplibpath = joinpath(joinpath(dir, "build"), oplib)
    # check if the library exists 
    libfile = oplibpath * (Sys.islinux() ? 
                        ".so" : Sys.isapple() ? ".dylib" : ".dll")
    # @show libfile
    if !isfile(libfile)
        @info "Lib $s exists in registery but was not initialized. Compiling..."
        compile(s)
    end
    if return_str
        return oplibpath
    end
    if grad
        load_op_and_grad(oplibpath, opname; multiple=multiple)
    else
        load_op(oplibpath, opname)
    end
end

load_system_op(s::String; kwargs...) = load_system_op(COLIB[s]...; kwargs...)

"""
    compile(s::String)

Compiles the library `s` by force.
"""
function compile(s::String)
    PWD = pwd()
    dir = joinpath(joinpath("$(@__DIR__)", "../deps/CustomOps"), s)
    if !isdir(dir)
        error("Folder for the operator $s does not exist: $dir")
    end
    cd(dir)
    rm("build",force=true,recursive=true)
    mkdir("build")
    cd("build")
    try
        cmake()
        make()
    catch e 
        error("Compilation error: $e")
    finally
        cd(PWD)
    end
end

"""
    customop(simple::Bool=false)

Create a new custom operator. If `simple=true`, the custom operator only supports CPU and does not have gradients. 

# Example

```julia-repl
julia> customop() # create an editable `customop.txt` file
[ Info: Edit custom_op.txt for custom operators
julia> customop() # after editing `customop.txt`, call it again to generate interface files.
```
"""
function customop(simple::Bool=false)
    # install_custom_op_dependency()
    py_dir = "$(@__DIR__)/../examples/custom_op/template"
    if !("custom_op.txt" in readdir("."))
        cp("$(py_dir)/custom_op.example", "custom_op.txt")
        @info "Edit custom_op.txt for custom operators"
        return
    else
        python = PyCall.python
        run(`$python $(py_dir)/customop.py custom_op.txt $py_dir $simple`)
    end
end



function use_gpu(i::Union{Nothing,Int64}=nothing)
    dl = pyimport("tensorflow.python.client.device_lib")
    if !isnothing(i) && i>=1
        i = join(collect(0:i-1),',') 
        ENV["CUDA_VISIBLE_DEVICES"] = i 
    elseif !isnothing(i) && i==0
        ENV["CUDA_VISIBLE_DEVICES"] = ""
    end
    local_device_protos = dl.list_local_devices()
    return [x.name for x in local_device_protos if x.device_type == "GPU"]
end




"""
    test_jacobian(f::Function, x0::Array{Float64}; scale::Float64 = 1.0)

Testing the gradients of a vector function `f`:
`y, J = f(x)` where `y` is a vector output and `J` is the Jacobian.
"""
function test_jacobian(f::Function, x0::Array{Float64}; scale::Float64 = 1.0)
    v0 = rand(Float64,size(x0))
    γs = scale ./10 .^(1:5)
    err2 = []
    err1 = []
    f0, J = f(x0)
    for i = 1:5
        f1, _ = f(x0+γs[i]*v0)
        push!(err1, norm(f1-f0))
        @show f1, f0, 2γs[i]*J*v0
        push!(err2, norm(f1-f0-γs[i]*J*v0))
        # push!(err2, norm((f1-f2)/(2γs[i])-J*v0))
        # #@show "test ", f1, f2, f1-f2
    end
    close("all")
    loglog(γs, err2, label="Automatic Differentiation")
    loglog(γs, err1, label="Finite Difference")
    loglog(γs, γs.^2 * 0.5*abs(err2[1])/γs[1]^2, "--",label="\$\\mathcal{O}(\\gamma^2)\$")
    loglog(γs, γs * 0.5*abs(err1[1])/γs[1], "--",label="\$\\mathcal{O}(\\gamma)\$")
    plt.gca().invert_xaxis()
    legend()
    println("Finite difference: $err1")
    println("Automatic differentiation: $err2")
    return err1, err2
end

"""
    install(s::String; force::Bool = false)

Install a custom operator via URL. `s` can be
- A URL. ADCME will download the directory through `git`
- A string. ADCME will search for the associated package on https://github.com/ADCMEMarket
"""
function install(s::String; force::Bool = false)
    global COLIB
    codir = "$(@__DIR__)/../deps/CustomOps"
    if !startswith(s, "https://github.com")
        s = "https://github.com/ADCMEMarket/"*s
    end
    _, name = splitdir(s)
    if name in readdir(codir)
        if force
            rm(joinpath(codir, name), recursive=true, force=true)
        else
            error("$name already in $codir, fix it with\n\n\tinstall(\"$s\", force=true)\n")
        end
    end
    try
        run(`$GIT clone $s $(joinpath(codir, name))`)
    catch
        run(`$GIT clone git://$(s[9:end]).git $(joinpath(codir, name))`)
    end
    formula = eval(Meta.parse(read(joinpath(joinpath(codir, name),"formula.txt"), String)))
    if isnothing(formula)
        error("Broken package: $s does not have formula.txt.")
    else
        @info "Add formula $formula"
        push!(COLIB, formula)
    end

    rm("$(@__DIR__)/../deps/CustomOps/formulas.txt", force=true)
    open("$(@__DIR__)/../deps/CustomOps/formulas.txt", "a") do io 
        for c in COLIB
            write(io, string(c)*"\n")
        end
    end
end