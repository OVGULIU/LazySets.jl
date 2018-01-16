import LazySets.Approximations.overapproximate

# Approximation of a 2D centered unit ball in norm 2
# All vertices v should be like this:
# ‖v‖ >= 1 and ‖v‖ <= 1+ɛ
# Where ɛ is the given error bound
b = Ball2([0., 0.], 1.)
ɛ = .01
p = tovrep(overapproximate(b, ɛ))
for v in p.vertices_list
    @test norm(v) >= 1.
    @test norm(v) <= 1.+ɛ
end

# Check that there are no redundant constraints for a ballinf
b = BallInf([0.5,0.5],0.1)
lcl = overapproximate(b, .001).constraints_list
@test length(lcl) == 4
@test lcl[1].a == [1.0,0.0]
@test lcl[1].b == 0.6
@test lcl[2].a == [0.0,1.0]
@test lcl[2].b == 0.6
@test lcl[3].a == [-1.0,0.0]
@test lcl[3].b == -0.4
@test lcl[4].a == [0.0,-1.0]
@test lcl[4].b == -0.4

# Check that there are no redundant constraints for a HPolygon (octagon)
p = HPolygon()
addconstraint!(p, LinearConstraint([1.0, 0.0], 1.0))
addconstraint!(p, LinearConstraint([0.0, 1.0], 1.0))
addconstraint!(p, LinearConstraint([-1.0, 0.0], 1.0))
addconstraint!(p, LinearConstraint([0.0, -1.0], 1.0))
addconstraint!(p, LinearConstraint([sqrt(2.0)/2.0, sqrt(2.0)/2.0], 1.0))
addconstraint!(p, LinearConstraint([-sqrt(2.0)/2.0, sqrt(2.0)/2.0], 1.0))
addconstraint!(p, LinearConstraint([sqrt(2.0)/2.0, -sqrt(2.0)/2.0], 1.0))
addconstraint!(p, LinearConstraint([-sqrt(2.0)/2.0, -sqrt(2.0)/2.0], 1.0))
lcl = overapproximate(p, .001).constraints_list
@test length(lcl) == 8
@test lcl[1].a ≈ [1.0,0.0]
@test lcl[1].b ≈ 1.0
@test lcl[2].a ≈ [sqrt(2.0)/2.0, sqrt(2.0)/2.0]
@test lcl[2].b ≈ 1.0
@test lcl[3].a ≈ [0.0,1.0]
@test lcl[3].b ≈ 1.0
@test lcl[4].a ≈ [-sqrt(2.0)/2.0, sqrt(2.0)/2.0]
@test lcl[4].b ≈ 1.0
@test lcl[5].a ≈ [-1.0,0.0]
@test lcl[5].b ≈ 1.0
@test lcl[6].a ≈ [-sqrt(2.0)/2.0, -sqrt(2.0)/2.0]
@test lcl[6].b ≈ 1.0
@test lcl[7].a ≈ [0.0,-1.0]
@test lcl[7].b ≈ 1.0
@test lcl[8].a ≈ [sqrt(2.0)/2.0, -sqrt(2.0)/2.0]
@test lcl[8].b ≈ 1.0