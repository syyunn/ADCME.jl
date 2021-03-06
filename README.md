![](docs/src/assets/icon.jpg)

---



![](https://travis-ci.org/kailaix/ADCME.jl.svg?branch=master)
![Coverage Status](https://coveralls.io/repos/github/kailaix/ADCME.jl/badge.svg?branch=master)


![](docs/src/assets/demo.png)

The ADCME library (**A**utomatic **D**ifferentiation Library for **C**omputational and **M**athematical **E**ngineering) aims at generic and scalable inverse modeling with gradient-based optimization techniques. It has [TensorFlow](https://www.tensorflow.org/) as the automatic differentiation and parallel computing backends. The dataflow model adopted by the framework enables researchers to do high-performance inverse modeling *without substantial effort after implementing the forward simulation*.

Several features of the library are

* *MATLAB-style syntax*. Write `A*B` for matrix production instead of `tf.matmul(A,B)`.
* *Custom operators*. Implement operators in C/C++ for bottleneck parts; incorporate legacy code or specially designed C/C++ code in `ADCME`.
* *Numerical Scheme*. Easy to implement numerical schemes for solving PDEs.
* *Static graphs*. Compilation time computational graph optimization; automatic parallelism for your simulation codes.
* *Custom optimizers*. Large scale constrained optimization? Use `CustomOptimizer` to integrate your favorite optimizer. 

Start building your forward and inverse modeling on top of the million-dollar [TensorFlow](https://www.tensorflow.org/) project with ADCME today!

| Documentation                                                |
| ------------------------------------------------------------ |
| [![](https://img.shields.io/badge/docs-dev-blue.svg)](https://kailaix.github.io/ADCME.jl/dev) |



# Installation

⚠️ The latest version only supports Julia≧1.3

⚠️ `PyCall` is forced to use the default interpreter by `ADCME`. Do not try to reset the interpreter by rebuilding `PyCall`. 

1. Install [Julia](https://julialang.org/)

2. Install `ADCME`
```
julia> ]
pkg> add ADCME
```

3. (Optional) Test `ADCME.jl`
```
julia> ]
pkg> test ADCME
```

4. (Optional) Enable GPU Support
To enable GPU support, first, make sure `nvcc` is available from your environment (e.g., type `nvcc` in your shell and you should get the location of the executable binary file).
```julia
ENV["GPU"] = 1
Pkg.build("ADCME")
```


# Tutorial

Consider solving the following problem

-bu''(x)+u(x) = f(x), x∈[0,1], u(0)=u(1)=0

where 

f(x) = 8 + 4x - 4x²

Assume that we have observed `u(0.5)=1`, we want to estimate `b`. The true value, in this case, should be `b=1`.

```julia
using LinearAlgebra
using ADCME

n = 101 # number of grid nodes in [0,1]
h = 1/(n-1)
x = LinRange(0,1,n)[2:end-1]

b = Variable(10.0) # we use Variable keyword to mark the unknowns
A = diagm(0=>2/h^2*ones(n-2), -1=>-1/h^2*ones(n-3), 1=>-1/h^2*ones(n-3)) 
B = b*A + I  # I stands for the identity matrix
f = @. 4*(2 + x - x^2) 
u = B\f # solve the equation using built-in linear solver
ue = u[div(n+1,2)] # extract values at x=0.5

loss = (ue-1.0)^2 

# Optimization
sess = Session(); init(sess) 
BFGS!(sess, loss)

println("Estimated b = ", run(sess, b))
```
Expected output 
```
Estimated b = 0.9995582304494237
```

The gradients can be obtained very easily. For example, if we want the gradients of `loss` with respect to `b`, the following code will create a Tensor for the gradient
```
julia> gradients(loss, b)
PyObject <tf.Tensor 'gradients_1/Mul_grad/Reshape:0' shape=() dtype=float64>
```

Under the hood, a computational graph is created for gradients back-propagation.

![](docs/src/assets/code.png)


For more documentation, see [here](https://kailaix.github.io/ADCME.jl/dev).


# Manual Installation

It is recommended that you use the default build script. However, in some cases, you may want to install the package and configure the environment manually. 

Step 1: Install `ADCME` on a computer with Internet access and zip all files from the following paths
```julia
julia> using Pkg
julia> Pkg.depots()
```
The files will contain all the dependencies. 

Step 2: Build `ADCME` mannually. 
```julia
using Pkg;
ENV["manual"] = 1
Pkg.build("ADCME")
```
However, in this case you are responsible for configuring the environment by modifying the file
```julia
using ADCME; 
print(joinpath(splitdir(pathof(ADCME))[1], "deps/deps.jl"))
```

# Research Work


| <img src="docs/src/assets/ana.png" width="380">              | <img src="docs/src/assets/levy.png" width="380">             |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| Stochastic Inversion with Adversarial Training [[Documentation]](https://kailaix.github.io/ADCME.jl/dev/apps_ana/) | Calibrating Lévy Processes  [[Documentation]](https://kailaix.github.io/ADCME.jl/dev/apps_levy/) |
| <img src="docs/src/assets/law.png" width="380">              | <img src="docs/src/assets/diagram.png" width="380">          |
| Learning Constitutive Relations  [[Documentation]](https://kailaix.github.io/ADCME.jl/dev/apps_constitutive_law/) | Time-lapse FWI  [[Documentation]](https://kailaix.github.io/ADCME.jl/dev/apps_ad/) |
| <img src="docs/src/assets/hidden.png" width="380">           |                                                              |
| Intelligent Automatic Differentiation [[Documentation]](https://kailaix.github.io/ADCME.jl/dev/apps_ad/) |                                                              |



# LICENSE

ADCME.jl is released under MIT License. See [License](https://github.com/kailaix/ADCME.jl/tree/master/LICENSE) for details. 
