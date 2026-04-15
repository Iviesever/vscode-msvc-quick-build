#pragma once
#ifndef _MODULE_STD
#include <cmath>
#include <format>
#include <string>
#endif

template<typename T = double>
struct Vec3 {
    T x{}, y{}, z{};
    auto operator+(this const Vec3& self, const Vec3& rhs) -> Vec3 { return {self.x+rhs.x, self.y+rhs.y, self.z+rhs.z}; }
    auto operator*(this const Vec3& self, T s) -> Vec3 { return {self.x*s, self.y*s, self.z*s}; }
    auto length(this const Vec3& self) -> T { return std::sqrt(self.x*self.x + self.y*self.y + self.z*self.z); }
    auto dot(this const Vec3& self, const Vec3& rhs) -> T { return self.x*rhs.x + self.y*rhs.y + self.z*rhs.z; }
    auto to_string(this const Vec3& self) -> std::string { return std::format("({:.2f}, {:.2f}, {:.2f})", self.x, self.y, self.z); }
};
