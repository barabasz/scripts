import sys
from colored import Fore, Back, Style
from primes import Primes

fb = Fore.blue
fm = Fore.magenta
fy = Fore.yellow
fg = Fore.green
fr = Fore.red
sb = Style.bold
sr = Style.reset
ok = f"{fg}✔{sr} "
er = f"{fr}✖{sr} "

stat = True

def print_primes():
    print(fm, end="")
    if p.range.count <= 10:
        print(*p.range.list, "\n")
    else:
        print(*p.range.list[:5], end="")
        print(f" {sr}...{p.range.count - 10} more...{fm} ", end="")
        print(*p.range.list[-5:], "\n")
    print(sr, end="")

def print_value(value, padding = 43):
    name = f"{value.name} {fg}{value.symbol}{sr}".ljust(padding)
    print(f"{name}{fy}{value.value}{sr}")

def print_list(value, padding = 43):
    if hasattr(value, "form"):
        name = f"{value.name}{fg} {value.form}{sr}".ljust(padding)
    else:
        name = value.name.ljust(padding)
    examples = f"({fm}" if value.count > 0 else ""
    match value.count:
        case 1: examples += f"{fm}{value.first}{sr}"
        case 2: examples += f"{fm}{value.first}{sr} and {fm}{value.last}{sr}"
        case _ if value.count < 6:
            list = (str(i) for i in value.list)
            examples += f"{sr}, {fm}".join(list)
        case _:
            examples += f"{fm}{value.list[0]}{sr}, {fm}{value.list[1]}{sr}, {fm}{value.list[2]}{sr}"
            examples += ", ..., "
            examples += f"{fm}{value.list[-3]}{sr}, {fm}{value.list[-2]}{sr}, {fm}{value.list[-1]}{sr}"
    examples += f"{sr})" if value.count > 0 else ""
    print(f"{name}{fy}{value.count}{sr} {examples}")

def print_gaps(value, padding = 43):
    if p.range.count > 2:
        name = f"{value.name} {fg}{value.symbol}{sr}".ljust(padding)
        if value.count > 0:
            if value.count == 1:
                examples = f"{fm}{value.first}{sr}"
            elif value.count == 2:
                examples = f"{fm}{value.first}{sr} and {fm}{value.last}{sr}"
            else:
                examples = f"{fm}{value.first}{sr} {fg}...{value.count - 2} more...{sr} {fm}{value.last}{sr}"
            print(f"{name}{fy}{value.value}{sr} ({value.count_text}) {examples}")
    else:
        name = f"Gap {fg}∆{sr}".ljust(padding)
        print(f"{name}{fy}{value.value}{sr}")

def print_prime(value, padding = 43):
    if p.range.count > 1:
        name = f"{value.name} {fg}{value.symbol}{sr}".ljust(padding)
        print(f"{name}{fm}{value.value}{sr} ({fg}{value.indexs}{sr} prime)")
    else:
        name = f"Prime number found".ljust(padding - 13)
        print(f"{name}{fm}{value.value}{sr} ({fg}{value.indexs}{sr} prime)")

def print_times(padding = 15):
    sieve = p.time.sieve.name.ljust(padding)
    print(f"\n{fb}{sieve}{p.time.sieve.value} {p.time.unit}{sr}")
    gaps = p.time.gaps.name.ljust(padding)
    print(f"{fb}{gaps}{p.time.gaps.value} {p.time.unit}{sr}")
    basics = p.time.basics.name.ljust(padding)
    print(f"{fb}{basics}{p.time.basics.value} {p.time.unit}{sr}")
    stats = p.time.stats.name.ljust(padding)
    print(f"{fb}{stats}{p.time.stats.value} {p.time.unit}{sr}")
    weird = p.time.weird.name.ljust(padding)
    print(f"{fb}{weird}{p.time.weird.value} {p.time.unit}{sr}")
    total = p.time.total.name.ljust(padding)
    print(f"{fb}{sb}{total}{p.time.total.value} {p.time.unit}{sr}")

def print_cli(p):
    title = f"\n{Primes.str('title')} {fy}{p.request.interval}{sr}:\n"
    match p.range.count:
        case 0: result = f"{er}No primes found"
        case 1: result = f"{ok}{fy}1{sr} prime found"
        case _: result = f"{ok}{fy}{p.range.count}{sr} primes found"
    result += f" among {fy}{p.request.count}{sr} "
    result += "natural numbers." if p.request.count > 1 else "natural number."

    print(title)
    print(result)
    if p.range.count > 0 and stat:
        print_primes()
        print_prime(p.range.first)
        if p.range.count > 1:
            print_prime(p.range.last)
            print_gaps(p.gaps.max)
            if p.range.count > 2:
                print_gaps(p.gaps.min)
                print_gaps(p.gaps.com)
                print_list(p.gaps, 30)
        print()
        if p.mersennes.count > 0: print_list(p.mersennes)
        if p.thabits.count > 0: print_list(p.thabits)
        if p.fermats.count > 0: print_list(p.fermats)
        if p.wagstaffs.count > 0: print_list(p.wagstaffs)
        print()
        print_value(p.pcent)
        if p.range.count > 1:
            print_value(p.sum)
            print_value(p.mean)
            print_value(p.median)
            print_value(p.pstdev)
            print_value(p.pvariance)
            print_value(p.stdev)
            print_value(p.variance)
            print_value(p.q1)
            print_value(p.q3)
            print_value(p.qi)
    print_times()
    
def print_cli_errors(p):
    print("")
    for e in p.error:
        print(f"{er} {e}")

def help():
    return '\n'.join(['',
        "Calculating primes and other mysterious numbers in specified range.\n",
        f"Usage:\t{fy}primes x{sr}\tfor range {fg}{{1..𝑥}}{sr}",
        f"or\t{fy}primes x y{sr}\tfor range {fg}{{𝑥..𝑦}}{sr}\n",
        f"where x and y"
        + f" are positive natural numbers, 𝑥 ≥ 1, "
        + f"𝑦 ≥ 𝑥 and 𝑦 < {Primes.max}.",
    ])

args = len(sys.argv)

match args:
    case _ if args > 3:
        print("\n" + Primes.er + Primes.help("argsm"))
        sys.exit(2)
    case 3:
        p = Primes(sys.argv[1], sys.argv[2])
    case 2:
        p = Primes(1, sys.argv[1])
    case _:
        print(help())
        sys.exit(0)

if not p.error:
    print_cli(p)
    sys.exit(0)
else:
    print_cli_errors(p)
    sys.exit(1)
