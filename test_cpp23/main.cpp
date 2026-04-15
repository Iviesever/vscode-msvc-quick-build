import std;
import mathlib;

#define _MODULE_STD
#include "vec3.hpp"
#include "config.h"
 
int main() { 
    std::println("=== {} v{} ===", APP_NAME, APP_VERSION);
    std::println("");

    std::println("--- Vec3 (.hpp) ---");
    Vec3 a{1.0, 2.0, 3.0}, b{4.0, 5.0, 6.0};
    std::println("  a + b = {}", (a + b).to_string());
    std::println("  a * 2 = {}", (a * 2.0).to_string());
    std::println("  |a|   = {:.4f}", a.length());
    std::println("  a . b = {:.1f}", a.dot(b));
    std::println("");

    std::println("--- mathlib (.ixx) ---");
    std::println("  Pi  = {:.10f}", Pi);
    std::println("  Tau = {:.10f}", Tau);
    Circle c1{1.0}, c5{5.0};
    std::println("  area(r=1)  = {:.4f}", c1.area());
    std::println("  circ(r=5)  = {:.4f}", c5.circumference());
    std::println("  90 deg     = {:.4f} rad", deg_to_rad(90.0));
    std::println("  10!        = {}", factorial(10));
    std::println("");

    std::println("--- std::expected ---");
    for (auto [num, den] : {std::pair{10.0, 3.0}, {42.0, 0.0}, {100.0, 7.0}}) {
        auto r = safe_divide(num, den);
        if (r) std::println("  {:.0f}/{:.0f} = {:.4f}", num, den, *r);
        else   std::println("  {:.0f}/{:.0f} = ERROR: {}", num, den, r.error());
    }
    std::println("");

    std::println("--- FizzBuzz (1..20) ---");
    std::print("  ");
    for (auto i : std::views::iota(1, 21)) {
        if (i > 1) std::print(", ");
        std::print("{}", fizzbuzz(i));
    }
    std::println("");
    std::println("");

    std::println("--- C++23 ranges ---");
    auto nums = std::to_array({3, 1, 4, 1, 5, 9, 2, 6, 5, 3});
    std::print("  chunks(3): ");
    for (auto chunk : nums | std::views::chunk(3)) {
        std::print("[");
        for (auto&& [i, v] : chunk | std::views::enumerate) {
            if (i > 0) std::print(",");
            std::print("{}", v);
        }
        std::print("] ");
    }
    std::println("");

    auto names  = std::to_array<std::string_view>({"alpha", "beta", "gamma"});
    auto scores = std::to_array({95, 87, 92});
    std::print("  zip: ");
    for (auto&& [n, s] : std::views::zip(names, scores))
        std::print("{}={} ", n, s);
    std::println("");

    std::println("\n=== All tests passed! ===");
}
