import math, time, statistics as stat

class Param:
    def __init__(self, value, name):
        self.value = value
        self.name = name
        self.info = f"{self.name}: {self.value}"

class ParamStat(Param):
    def __init__(self, value, name, symbol):
        super().__init__(value, name)
        self.symbol = symbol
        self.info = f"{self.name} ({self.symbol}): {self.value}"

class ParamList(Param):
    def __init__(self, list, name, form = ""):
        super().__init__(False, name)
        self.list = list
        self.count = len(list)
        self.form = form
        self.first = list[0] if self.count > 0 else False
        self.last = list[-1] if self.count > 0 else False
        self.info = f"{self.name}: {self.count}"

class ParamGaps(ParamStat):
    def __init__(self, value, list, name, symbol):
        super().__init__(value, name, symbol)
        self.list = list
        self.count = len(list)
        if self.count > 0:
            self.count_text = "1 time" if self.count == 1 else f"{self.count} times"
            self.first = f"{{{list[0][0]}, {list[0][1]}}}"
            self.last = f"{{{list[-1][0]}, {list[-1][1]}}}"
            self.more = self.count - 2 if self.count > 3 else False
        else:
            self.count_text = ""
            self.first = False
            self.last = False
            self.more = False

class Prime(ParamStat):
    def __init__(self, value, name, symbol, index):
        super().__init__(value, name, symbol)
        if value:
            self.index = index
            self.sufix = self.sfx(index)
            self.indexs = f"{index}{self.sufix}"
        else:
            self.index = False
            self.sufix = False
            self.indexs = False
        self.info = f"{self.name}: {self.symbol} = {self.value} ({self.indexs} prime)"
    def sfx(self, n: int):
        return "%s"%({1:"st",2:"nd",3:"rd"}.get(n%100 if (n%100)<20 else n%10,"th"))

class TimerItem:
    def __init__(self, start: float, stop: float, name: str):
        self.name = name
        self.start = start
        self.stop = stop
        self.diff = stop - start
        self.value = round(self.diff * 10**3, 4)
        self.info = f"{self.name}: {self.value} ms"

class Timer:
    def __init__(self):
        self.start = time.time()
        self.unit = "ms"
    def sieve(self):
        self.sieve = time.time()
    def gaps(self):
        self.gaps = time.time()
    def basics(self):
        self.basics = time.time()
    def stats(self):
        self.stats = time.time()
    def weird(self):
        self.weird = time.time()
    def stop(self):
        self.sieve = TimerItem(self.start, self.sieve, Primes.str("timep"))
        self.gaps = TimerItem(self.sieve.stop, self.gaps, Primes.str("timeg"))
        self.basics = TimerItem(self.gaps.stop, self.basics, Primes.str("timeb"))
        self.stats = TimerItem(self.basics.stop, self.stats, Primes.str("times"))
        self.weird = TimerItem(self.stats.stop, self.weird, Primes.str("timew"))
        self.total = TimerItem(self.start, time.time(), Primes.str("timet"))

class All:
    def __init__(self, list: list) -> None:
        self.list = list
        self.count = len(self.list)
        if self.count > 0:
            self.first = Prime(self.list[0], Primes.str("frstp"), "First", 1)
            self.last = Prime(self.list[-1], Primes.str("lastp"), "Last", self.count)
            self.interval = f"{{{self.first.value}..{self.last.value}}}"

class Range(All):
    def __init__(self, list: list, index_first, index_last) -> None:
        self.list = list
        self.count = len(self.list)
        if self.count > 0:
            self.first = Prime(self.list[0], Primes.str("lwstp"), "min(𝑥)", index_first)
            self.last = Prime(self.list[-1], Primes.str("highp"), "max(𝑥)", index_last)
            self.interval = f"{{{self.first.value}..{self.last.value}}}"
        else:
            self.first = Prime(False, Primes.str("lwstp"), "min(𝑥)", False)
            self.last = Prime(False, Primes.str("highp"), "max(𝑥)", False)
            self.interval = False
        match self.count:
            case 0: self.result = Primes.str("r_npf")
            case 1: self.result = Primes.str("r_1pf")
            case _: self.result = f"{self.count} {Primes.str('r_psf')}"
        self.half = int(self.count // 2)

class Request:
    def __init__(self, start, stop) -> None:
        self.first = int(start)
        self.last = int(stop)
        self.count = self.last - self.first + 1
        self.interval = f"{{{self.first}..{self.last}}}"
        self.title = f"{Primes.str('title')} {self.interval}:"

class Gaps:
    def __init__(self, list: list) -> None:
        gaps, gaps_list = {}, []
        if len(list) > 1:
            for i in range(len(list) - 1):
                gap = list[i+1] - list[i]
                try:
                    gaps[gap] += 1
                except KeyError:
                    gaps[gap] = 1
                gaps_list.append((list[i], list[i+1], gap))
            gaps_list.append((list[-1], None, None))
            max_value = max(gaps)
            max_list = tuple((i[0], i[1]) for i in gaps_list if i[2] == max_value)
            min_value = min(gaps)
            min_list = tuple((i[0], i[1]) for i in gaps_list if i[2] == min_value)
            com_count = max(gaps.values())
            com_value = next((i for i in gaps if gaps[i] == com_count))
            com_list = tuple((i[0], i[1]) for i in gaps_list if i[2] == com_value)
        else:
            max_value, min_value, com_value = False, False, False
            max_list, min_list, com_list = (), (), ()
        self.kinds = gaps
        self.list = tuple(sorted(gaps.keys()))
        self.first = self.list[0]
        self.last = self.list[-1]
        self.name = Primes.str("g_kin")
        self.count = len(self.list)
        
        self.max = ParamGaps(max_value, max_list, Primes.str("g_max"), "∆ₘₐₓ")
        self.min = ParamGaps(min_value, min_list, Primes.str("g_min"), "∆ₘᵢₙ")
        self.com = ParamGaps(com_value, com_list, Primes.str("g_com"), "∆ᶠ")

class Primes:
    """
    Calculating primes, their statistics and other related numbers in specified range.
    Usage:  primes x        for range {1..𝑥}
    or      primes x y      for range {𝑥..𝑦}
    where x and y are positive natural numbers, 𝑥 ≥ 1, 𝑦 ≥ 𝑥 and 𝑦 < 10000000.
    """
    max = 100000000
    
    def __init__(self, first, last):
        self.error = []
        if self.check(first, last):
            self.time = Timer()
            self.sieve()
            self.gaps()
            self.basics()
            self.stats()
            self.weird()
            self.time.stop()

    def check(self, first, last):
        try:
            first = int(first)
        except ValueError:
            self.error.append(self.str('b_int'))
            return False
        try:
            last = int(last)
        except ValueError:
            self.error.append(self.str('e_int'))
            return False
        if first < 1: self.error.append(self.str('b_pos'))
        if last < 1: self.error.append(self.str('e_pos'))
        if first > last: self.error .append(self.str('e_gtb'))
        if last > self.max: self.error.append(self.str('e_max'))
        if not self.error:
            self.request = Request(first, last)
            return True
        else:
            return False
    
    def sieve(self):
        n = self.request.last
        sieve_array = [True for i in range(n + 1)]
        sieve_array[0], sieve_array[1] = False, False

        for i in range(math.isqrt(n) + 1):
            if sieve_array[i] == True:
                for j in range(i * 2 , n + 1, i):
                    sieve_array[j] = False

        primes_all = tuple(k for k, v in enumerate(sieve_array) if v == True)
        primes_range = tuple(i for i in primes_all if i >= self.request.first)
                
        self.all = All(primes_all)
        if len(primes_all) > 0 and len(primes_range) > 0:
            first_index = primes_all.index(primes_range[0]) + 1
            self.range = Range(primes_range, first_index, self.all.count)
        else:
            self.range = Range(primes_range, 0, self.all.count)
        
        self.time.sieve()

    def gaps(self):
        if self.range.count >= 2:
            self.gaps = Gaps(self.range.list)
        else:
            self.gaps = Gaps([])
        self.time.gaps()

    def basics(self):
        if self.range.count > 0:
            self.pcent = ParamStat(round(self.range.count / self.request.count * 100, 4), self.str("pcent"), "%")
            self.sum = ParamStat(sum(self.range.list), self.str("sumpr"), "Σ𝑥")
        else:
            self.pcent = ParamStat(False, self.str("pcent"), "%")
            self.sum = ParamStat(False, self.str("sumpr"), "Σ𝑥")
        self.time.basics()

    def stats(self):
        if self.range.count >= 2:
            self.median = ParamStat(stat.median(self.range.list), self.str("mdnpr"), "𝑀𝑒")
            self.mean = ParamStat(stat.mean(self.range.list), self.str("amean"), "μ")
            self.pstdev = ParamStat(stat.pstdev(self.range.list), self.str("pstdv"), "σ𝑥")
            self.pvariance = ParamStat(stat.pvariance(self.range.list), self.str("pvari"), "σ²𝑥")
            self.stdev = ParamStat(stat.stdev(self.range.list), self.str("stdev"), "s𝑥")
            self.variance = ParamStat(stat.variance(self.range.list), self.str("svari"), "s²𝑥")
            self.q1 = ParamStat(stat.median(self.range.list[:self.range.half]), self.str("lquar"), "Q₁")
            self.q3 = ParamStat(stat.median(self.range.list[-self.range.half:]), self.str("uquar"), "Q₃")
            self.qi = ParamStat(self.q3.value - self.q1.value, self.str("irang"), "Qᵢ")
        else:
            self.median = ParamStat(False, self.str("mdnpr"), "𝑀𝑒")
            self.mean = ParamStat(False, self.str("amean"), "μ")
            self.pstdev = ParamStat(False, self.str("pstdv"), "σ𝑥")
            self.pvariance = ParamStat(False, self.str("pvari"), "σ²𝑥")
            self.stdev = ParamStat(False, self.str("stdev"), "s𝑥")
            self.variance = ParamStat(False, self.str("svari"), "s²𝑥")
            self.q1 = ParamStat(False, self.str("lquar"), "Q₁")
            self.q3 = ParamStat(False, self.str("uquar"), "Q₃")
            self.qi = ParamStat(False, self.str("irang"), "Qᵢ")
        self.time.stats()
        
    def weird(self):
        if self.range.count > 0:
            self.thabits = ParamList(self.find_thabits(), self.str("p_tha"), "3⋅2ⁿ-1")
            self.mersennes = ParamList(self.find_mersennes(), self.str("p_mer"), "2ⁿ-1")
            self.fermats = ParamList(self.find_fermats(), self.str("p_fer"), "2^2ⁿ-1")
            self.wagstaffs = ParamList(self.find_wagstaffs(), self.str("p_wag"), "(2ᵖ+1)/3")
        else:
            self.thabits = ParamList([], self.str("p_tha"), "3⋅2ⁿ-1")
            self.mersennes = ParamList([], self.str("p_mer"), "2ⁿ-1")
            self.fermats = ParamList(self.find_fermats(), self.str("p_fer"), "2^2ⁿ-1")
            self.wagstaffs = ParamList(self.find_wagstaffs(), self.str("p_wag"), "(2ᵖ+1)/3")
        self.time.weird()

    def find_carols(self):
        i, c = 0, 0
        carols = set()
        while c < self.request.last:
            c = (2 ** i - 1) ** 2 - 2
            carols.add(c)
            i += 1 
        return tuple(sorted(carols & set(self.range.list)))

    def find_thabits(self):
        i, t = 0, 0
        thabits = set()
        while t < self.request.last:
            t = 3 * 2 ** i - 1
            thabits.add(t)
            i += 1 
        return tuple(sorted(thabits & set(self.range.list)))
    
    def find_mersennes(self):
        i, m = 0, 0
        mersennes = set()
        while m < self.request.last:
            m = 2 ** i - 1
            mersennes.add(m)
            i += 1
        return tuple(sorted(mersennes & set(self.range.list)))

    def find_fermats(self):
        i, f = 0, 0
        fermats = set()
        while f < self.request.last:
            f = 2 ** 2 ** i + 1
            fermats.add(f)
            i += 1
        return tuple(sorted(fermats & set(self.range.list)))
    
    def find_wagstaffs(self):
        i, w = 0, 0
        wagstaffs = set()
        while w < self.request.last:
            p = self.range.list[i]
            if (p % 2) != 0:
                w = (2 ** p + 1) / 3
                if w.is_integer():
                    wagstaffs.add(int(w))
            i += 1
        return tuple(sorted(wagstaffs & set(self.range.list)))

    def is_prime(self, p: int):
        return True if p in self.range.list else False
    
    @staticmethod
    def str(code):
        match code:
            case "amean": return "Arithmetic mean"
            case "argsm": return "Too many arguments"
            case "b_int": return "Beginning of range must be an integer"
            case "b_pos": return "Beginning of range must be a positive natural number"
            case "e_gt2": return "End of range must be greater than or equal to 2"
            case "e_gtb": return "End of the range must be greater than its beginning"
            case "e_int": return "End of range must be an integer"
            case "e_max": return f"End of range must be less than {Primes.max}"
            case "e_pos": return "End of range must be a positive natural number"
            case "frstp": return "First prime"
            case "g_com": return "Most common gap"
            case "g_max": return "Longest gap"
            case "g_min": return "Shortest gap"
            case "g_oth": return "Other gaps"
            case "g_kin": return "Different gap lengths"
            case "highp": return "Highest prime"
            case "irang": return "Interquartile Range"
            case "lastp": return "Last prime"
            case "lquar": return "Lower Quartile"
            case "lwstp": return "Lowest prime"
            case "mdnpr": return "Median (middle value)"
            case "notap": return "Not applicable"
            case "p_cen": return "Centrist primes"
            case "p_dem": return "Democratic primes"
            case "p_rep": return "Republican primes"
            case "p_tha": return "Thabit primes"
            case "p_mer": return "Mersenne primes"
            case "p_fer": return "Fermat primes"
            case "p_wag": return "Wagstaff primes"
            case "pcent": return "Percentage of primes"
            case "pstdv": return "Pop. standard deviation"
            case "pvari": return "Pop. variance"
            case "r_1pf": return "1 prime found"
            case "r_npf": return "No primes found"
            case "r_psf": return "primes found"
            case "stdev": return "Sample standard deviation"
            case "sumpr": return "Sum of primes"
            case "svari": return "Sample variance"
            case "timeb": return "Basics"
            case "timeg": return "Gaps"
            case "timew": return "Curiosities"
            case "times": return "Stats"
            case "timep": return "Sieve"
            case "timet": return "Total"
            case "title": return "Primes, their statistics and other related numbers in range"
            case "uquar": return "Upper Quartile"
