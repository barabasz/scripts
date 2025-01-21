const pi = 3.1415926535897932; // rounded to 16th place
let pi4 = 1; // initial value for π/4
let max = 5; // number of additional 1/n fractions
let sign = false; // false = minus (subtract value), true = plus (add value)

for (let i = 3; i <= max * 2 + 1; i += 2) {
    pi4 += (sign ? 1 : -1) / i;
    sign = !sign;
}

console.log("calculated π: ", pi4*4);
console.log("error: ", pi - pi4*4);
