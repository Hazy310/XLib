// re.x —— 字符串正则-like 便捷封装
// 基于内置字符安全函数：split_str / index_of / len

// 分割字符串：按分隔符拆分为字符串数组（字符安全，支持中文）
fn split(s, sep) {
    return split_str(s, sep);
}

// 是否包含子串
fn contains(s, sub) {
    return index_of(s, sub) != -1;
}

// 替换所有子串：将 s 中所有 old 替换为 rep（字符安全，支持中文）
// 空 old 视为不替换，直接返回原串
fn replace(s, old, rep) {
    if old == "" {
        return s;
    }
    let parts = std.re.split(s, old);
    // 未找到分隔符：split 返回单元素数组，直接返回原串
    if len(parts) == 1 {
        return s;
    }
    let result = "";
    for i in 0..len(parts) {
        result = result + parts[i];
        if i < len(parts) - 1 {
            result = result + rep;
        }
    }
    return result;
}

// 仅替换第一处：s 中第一个 old 替换为 rep，其余保留
fn replace_first(s, old, rep) {
    if old == "" {
        return s;
    }
    let parts = std.re.split(s, old);
    if len(parts) == 1 {
        return s;
    }
    // 首段 + rep + 其余段（其余段之间用 old 重新连接，保留剩余分隔符）
    let result = parts[0] + rep;
    for i in 1..len(parts) {
        result = result + old + parts[i];
    }
    return result;
}

// 提取所有成对定界符之间的内容：groups(s, left, right) -> 数组
// 例：groups("a=1,b=2", "=", ",") -> ["1","2"]；left 为空则从串首开始
// 注意：内置 index_of 按字节、substr 按字符，这里用逐字符扫描（中文安全）
fn _find_c(s, start, ch) {
    let i = start;
    let n = len(s);
    while i < n {
        if substr(s, i, 1) == ch {
            return i;
        }
        i = i + 1;
    }
    -1
}

fn _find_sub(s, start, sub) {
    let k = len(sub);
    let n = len(s);
    let i = start;
    while i + k <= n {
        if substr(s, i, k) == sub {
            return i;
        }
        i = i + 1;
    }
    -1
}

fn groups(s, left, right) {
    let out = [];
    let n = len(s);
    let pos = 0;
    if left == "" {
        let r = std.re._find_sub(s, 0, right);
        if r > 0 {
            out = out + [substr(s, 0, r)];
        }
        if r >= 0 {
            pos = r + len(right);
        }
    }
    while pos < n {
        let l = std.re._find_sub(s, pos, left);
        if l < 0 {
            break;
        }
        let ls = l + len(left);
        let r = std.re._find_sub(s, ls, right);
        if r < 0 {
            break;
        }
        out = out + [substr(s, ls, r - ls)];
        pos = r + len(right);
    }
    out
}

// 通配符匹配：wildcard(s, pat) -> bool（* 任意串，? 单个字符，其余字面）
fn wildcard(s, pat) {
    // 双指针 + 回溯：星号位置可回退
    let si = 0;
    let pi = 0;
    let star = -1;
    let mark = 0;
    let sn = len(s);
    let pn = len(pat);
    while si < sn {
        if pi < pn {
            let pc = substr(pat, pi, 1);
            if pc == "?" or pc == substr(s, si, 1) {
                si = si + 1;
                pi = pi + 1;
                continue;
            }
            if pc == "*" {
                star = pi;
                mark = si;
                pi = pi + 1;
                continue;
            }
        }
        if star >= 0 {
            pi = star + 1;
            mark = mark + 1;
            si = mark;
        } else {
            return false;
        }
    }
    while pi < pn and substr(pat, pi, 1) == "*" {
        pi = pi + 1;
    }
    pi == pn
}

// 查找所有出现位置：findall(s, sub) -> 起始下标数组（空 sub 返回 []；字符下标）
fn findall(s, sub) {
    let out = [];
    if sub == "" {
        return out;
    }
    let n = len(s);
    let pos = 0;
    while pos <= n - len(sub) {
        let l = std.re._find_sub(s, pos, sub);
        if l < 0 {
            break;
        }
        out = out + [l];
        pos = l + len(sub);
    }
    out
}

// 是否以 prefix 开头
fn starts_with(s, prefix) {
    if len(prefix) > len(s) {
        return false;
    }
    substr(s, 0, len(prefix)) == prefix
}

// 是否以 suffix 结尾
fn ends_with(s, suffix) {
    if len(suffix) > len(s) {
        return false;
    }
    substr(s, len(s) - len(suffix), len(suffix)) == suffix
}