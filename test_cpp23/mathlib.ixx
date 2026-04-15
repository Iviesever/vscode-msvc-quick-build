module;
#include "config.h"

export module mathlib;
import std;

export inline constexpr double Pi  = PI;
export inline constexpr double Tau = TAU;

export struct Circle {
    double radius;
    auto area(this const Circle& self) -> double { return Pi * self.radius * self.radius; }
    auto circumference(this const Circle& self) -> double { return Tau * self.radius; }
};

export auto safe_divide(double a, double b) -> std::expected<double, std::string> {
    if (b == 0.0) return std::unexpected(std::string("division by zero"));
    return a / b;
}

export auto deg_to_rad(double degrees) -> double { return DEG2RAD(degrees); }

export consteval auto factorial(int n) -> long long {
    long long r = 1;
    for (int i = 2; i <= n; ++i) r *= i;
    return r;
}

export auto fizzbuzz(int n) -> std::string {
    if (n % 15 == 0) return "FizzBuzz";
    if (n % 3 == 0)  return "Fizz";
    if (n % 5 == 0)  return "Buzz";
    return std::to_string(n);
}
