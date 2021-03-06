using BoundaryValueDiffEq
using DiffEqBase, DiffEqDevTools
using Base.Test

# First order test
function func_1!(x, y, du)
    du[1] = y[2]
    du[2] = 0
end

# Not able to change the initial condition.
# Hard coded solution.
func_1!(::Type{Val{:analytic}}, x, y0) = [5-x,-1]

function boundary!(residual, u)
    residual[1] = u[1][1]-5
    residual[2] = u[end][1]
end

function boundary_two_point!(residual, ua, ub)
    residual[1] = ua[1]-5
    residual[2] = ub[1]
end

# Second order linear test
function func_2!(x, y, du)
    du[1] = y[2]
    du[2] = -y[1]
end

# Not able to change the initial condition.
# Hard coded solution.
func_2!(::Type{Val{:analytic}}, x, y) = [5*(cos(x) - cot(5)*sin(x)),
                                         5*(-cos(x)*cot(5) - sin(x))]

tspan = (0.,5.)
u0 = [5.,-3.5]
probArr = [BVProblem(func_1!, boundary!, u0, tspan),
           BVProblem(func_2!, boundary!, u0, tspan),
           TwoPointBVProblem(func_1!, boundary_two_point!, u0, tspan),
           TwoPointBVProblem(func_2!, boundary_two_point!, u0, tspan)]

testTol = 0.2
affineTol = 1e-6
dts = 1./2.^(5:-1:1)
order = 4

println("Collocation method (GeneralMIRK)")
println("Affineness Test")
prob = probArr[1]
@time sol = solve(prob, GeneralMIRK4(), dt=0.2)
@test norm(diff(map(x->x[1], sol.u)) + 0.2, Inf) + abs(sol[1][1]-5) < affineTol

println("Convergence Test on Linear")
prob = probArr[2]
@time sim = test_convergence(dts,prob,GeneralMIRK4())
@test abs(sim.𝒪est[:final]-order) < testTol

println("Collocation method (MIRK)")
println("Affineness Test")
prob = probArr[3]
@time sol = solve(prob, MIRK4(), dt=0.2)
@test norm(diff(map(x->x[1], sol.u)) + 0.2, Inf) + abs(sol[1][1]-5) < affineTol

println("Convergence Test on Linear")
prob = probArr[4]
@time sim = test_convergence(dts,prob,MIRK4())
@test abs(sim.𝒪est[:final]-order) < testTol

