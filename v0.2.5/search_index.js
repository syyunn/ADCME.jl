var documenterSearchIndex = {"docs":
[{"location":"extra/#Additional-Tools-1","page":"Additional Tools","title":"Additional Tools","text":"","category":"section"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"There are many handy tools implemented in ADCME for analysis, benchmarking, input/output, etc. ","category":"page"},{"location":"extra/#Benchmarking-1","page":"Additional Tools","title":"Benchmarking","text":"","category":"section"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"The functions tic and toc can be used for recording the runtime between two operations. tic starts a timer for performance measurement while toc marks the termination of the measurement. Both functions are bound with one operations. For example, we can benchmark the runtime for svd","category":"page"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"A = constant(rand(10,20))\nA = tic(A)\nr = svd(A)\nB = r.U*diagm(r.S)*r.Vt \nB, t = toc(B)\nrun(sess, B)\nrun(sess, t)","category":"page"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"tic\ntoc","category":"page"},{"location":"extra/#ADCME.tic","page":"Additional Tools","title":"ADCME.tic","text":"tic(o::PyObject, i::Union{PyObject, Integer}=0)\n\nConstruts a TensorFlow timer with index i. The start time record is right before o is executed.\n\n\n\n\n\n","category":"function"},{"location":"extra/#ADCME.toc","page":"Additional Tools","title":"ADCME.toc","text":"toc(o::PyObject, i::Union{PyObject, Integer}=0)\n\nReturns the elapsed time from last tic call with index i (default=0). The terminal time record is right before o is executed.\n\n\n\n\n\n","category":"function"},{"location":"extra/#Save-and-Load-Python-Object-1","page":"Additional Tools","title":"Save and Load Python Object","text":"","category":"section"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"psave\npload","category":"page"},{"location":"extra/#ADCME.psave","page":"Additional Tools","title":"ADCME.psave","text":"psave(o::PyObject, file::String)\n\nSaves a Python objection o to file. See also pload\n\n\n\n\n\n","category":"function"},{"location":"extra/#ADCME.pload","page":"Additional Tools","title":"ADCME.pload","text":"pload(file::String)\n\nLoads a Python objection from file. See also psave\n\n\n\n\n\n","category":"function"},{"location":"extra/#Save-and-Load-TensorFlow-Session-1","page":"Additional Tools","title":"Save and Load TensorFlow Session","text":"","category":"section"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"load\nsave","category":"page"},{"location":"extra/#ADCME.load","page":"Additional Tools","title":"ADCME.load","text":"load(sess::PyObject, file::String, vars::Union{PyObject, Nothing, Array{PyObject}}=nothing, args...; kwargs...)\n\nLoads the values of variables to the session sess from the file file. If vars is nothing, it loads values to all the trainable variables. See also save, load\n\n\n\n\n\nload(sw::Diary, dirp::String)\n\nLoads Diary from dirp.\n\n\n\n\n\n","category":"function"},{"location":"extra/#ADCME.save","page":"Additional Tools","title":"ADCME.save","text":"save(sess::PyObject, file::String, vars::Union{PyObject, Nothing, Array{PyObject}}=nothing, args...; kwargs...)\n\nSaves the values of vars in the session sess. The result is written into file as a dictionary. If vars is nothing, it saves all the trainable variables. See also save, load\n\n\n\n\n\nsave(sw::Diary, dirp::String)\n\nSaves Diary to dirp.\n\n\n\n\n\n","category":"function"},{"location":"extra/#Save-and-Load-Diary-1","page":"Additional Tools","title":"Save and Load Diary","text":"","category":"section"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"We can use TensorBoard to track a scalar value easily","category":"page"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"d = Diary(\"test\")\np = placeholder(1.0, dtype=Float64)\nb = constant(1.0)+p\ns = scalar(b, \"variable\")\nfor i = 1:100\n    write(d, i, run(sess, s, Dict(p=>Float64(i))))\nend\nactivate(d)","category":"page"},{"location":"extra/#","page":"Additional Tools","title":"Additional Tools","text":"Diary\nscalar\nactivate\nload\nsave\nwrite","category":"page"},{"location":"extra/#ADCME.Diary","page":"Additional Tools","title":"ADCME.Diary","text":"Diary(suffix::Union{String, Nothing}=nothing)\n\nCreates a diary at a temporary directory path. It returns a writer and the corresponding directory path\n\n\n\n\n\n","category":"type"},{"location":"extra/#ADCME.scalar","page":"Additional Tools","title":"ADCME.scalar","text":"scalar(o::PyObject, name::String)\n\nReturns a scalar summary object.\n\n\n\n\n\n","category":"function"},{"location":"extra/#ADCME.activate","page":"Additional Tools","title":"ADCME.activate","text":"activate(sw::Diary, port::Int64=6006)\n\nRunning Diary at http://localhost:port.\n\n\n\n\n\n","category":"function"},{"location":"extra/#Base.write","page":"Additional Tools","title":"Base.write","text":"write(sw::Diary, step::Int64, cnt::Union{String, Array{String}})\n\nWrites to Diary.\n\n\n\n\n\n","category":"function"},{"location":"#ADCME-Documentation-1","page":"Getting Started","title":"ADCME Documentation","text":"","category":"section"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"ADCME is suitable for conducting inverse modeling in scientific computing. The purpose of the package is to: (1) provide differentiable programming framework for scientific computing based on TensorFlow automatic differentiation (AD) backend; (2) adapt syntax to facilitate implementing scientific computing, particularly for numerical PDE discretization schemes; (3) supply missing functionalities in the backend (TensorFlow) that are important for engineering, such as sparse linear algebra, constrained optimization, etc. Applications include","category":"page"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"full wavelength inversion\nreduced order modeling in solid mechanics\nlearning hidden geophysical dynamics\nphysics based machine learning\nparameter estimation in stochastic processes","category":"page"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"The package inherents the scalability and efficiency from the well-optimized backend TensorFlow. Meanwhile, it provides access to incooperate existing C/C++ codes via the custom operators. For example, some functionalities for sparse matrices are implemented in this way and serve as extendable \"plugins\" for ADCME. ","category":"page"},{"location":"#Getting-Started-1","page":"Getting Started","title":"Getting Started","text":"","category":"section"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"To install ADCME, use the following command:","category":"page"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"using Pkg\nPkg.add(\"ADCME\")","category":"page"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"to load the package, use","category":"page"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"using ADCME","category":"page"},{"location":"#","page":"Getting Started","title":"Getting Started","text":"The building process will check the dependencies (tensorflow, tensorflow-probability, etc.) If the install is not successful, check your system and make sure tensorflow==1.14 and tensorflow-probability==0.7 are properly installed.","category":"page"}]
}
