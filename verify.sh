#!/bin/bash

# ==========================================
# CONFIGURATION (Multi-Partition Targets)
# ==========================================
SONAL_DIR="/storage/F8FCADDDFCAD9702/Android/data/com.termux/files/Wedding_Backup/Sonal_Wedding"
ROSHAN_DIR="/storage/7AF87657F876119D/Android/data/com.termux/files/Wedding_Backup/Roshan_Wedding"
REPORT_FILE="orphan_report.txt"
CPP_FILE="nef_verifier.cpp"
BIN_FILE="nef_verifier"

# ==========================================
# INITIALIZATION & COMPILER CHECK
# ==========================================
echo "================================================================"
echo " UNIFIED VERIFICATION ENGINE: INITIALIZING                      "
echo "================================================================"

if ! command -v clang++ &> /dev/null; then
    echo "[-] Clang missing. Installing build tools..."
    pkg update && pkg install clang -y
fi

# ==========================================
# EMBEDDED C++ VERIFIER SOURCE
# ==========================================
cat << 'EOF' > "$CPP_FILE"
// nef_verifier.cpp
// 100% Read-Only multi-directory .NEF / .JPG verification engine.

#include <filesystem>
#include <unordered_set>
#include <vector>
#include <string>
#include <cstdint>
#include <cstdio>
#include <cctype>
#include <system_error>
#include <fstream>
#include <iostream>

namespace fs = std::filesystem;

static std::uint64_t g_scanned = 0;
static std::uint64_t g_missing_jpg = 0;
static std::uint64_t g_missing_nef = 0;
static std::uint64_t g_errors  = 0;

static inline std::string to_lower(std::string s) {
    for (auto& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

static inline void print_counter() {
    std::fprintf(stderr,
        "\rScanned: %llu | Missing JPGs: %llu | Missing NEFs: %llu | Errors: %llu   ",
        static_cast<unsigned long long>(g_scanned),
        static_cast<unsigned long long>(g_missing_jpg),
        static_cast<unsigned long long>(g_missing_nef),
        static_cast<unsigned long long>(g_errors));
    std::fflush(stderr);
}

static void process_directory(const fs::path& dir, std::ofstream& log_file) {
    std::error_code ec;
    std::vector<fs::directory_entry> entries;
    entries.reserve(256);

    fs::directory_iterator it(dir, fs::directory_options::skip_permission_denied, ec);
    if (ec) { ++g_errors; print_counter(); return; }

    for (const fs::directory_iterator end{}; it != end; it.increment(ec)) {
        if (ec) { ++g_errors; break; }
        entries.push_back(*it);
    }

    std::unordered_set<std::string> jpg_stems;
    std::unordered_set<std::string> nef_stems;
    std::vector<fs::path> subdirs;

    for (const auto& e : entries) {
        std::error_code tmp_ec;
        if (e.is_directory(tmp_ec)) {
            subdirs.push_back(e.path());
            continue;
        }

        const fs::path& p = e.path();
        const std::string ex = to_lower(p.extension().string());
        const std::string stem = p.stem().string();

        if (ex == ".jpg" || ex == ".jpeg") {
            jpg_stems.insert(stem);
        } else if (ex == ".nef") {
            nef_stems.insert(stem);
        }
    }

    for (const auto& stem : nef_stems) {
        if (jpg_stems.find(stem) == jpg_stems.end()) {
            log_file << "ORPHAN NEF (No JPG found): " << (dir / stem).string() << ".NEF\n";
            ++g_missing_jpg;
        }
    }

    for (const auto& stem : jpg_stems) {
        if (nef_stems.find(stem) == nef_stems.end()) {
            log_file << "ORPHAN JPG (No NEF found): " << (dir / stem).string() << ".JPG\n";
            ++g_missing_nef;
        }
    }

    g_scanned += entries.size();
    print_counter();

    for (const fs::path& sd : subdirs) {
        process_directory(sd, log_file);
    }
}

int main(int argc, char** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "Usage: %s <output_log.txt> <target_dir_1> [target_dir_2 ...]\n", argv[0]);
        return 1;
    }

    const fs::path report_path(argv[1]);
    std::ofstream log_file(report_path, std::ios::trunc);
    if (!log_file.is_open()) {
        std::fprintf(stderr, "Error: Could not open output file '%s'\n", argv[1]);
        return 1;
    }

    for (int i = 2; i < argc; ++i) {
        std::error_code ec;
        const fs::path root(argv[i]);
        if (!fs::is_directory(root, ec)) {
            std::fprintf(stderr, "\nWarning: Directory unreachable or missing: '%s'\n", argv[i]);
            ++g_errors;
            continue;
        }
        std::fprintf(stderr, "\nScanning target: %s\n", argv[i]);
        process_directory(root, log_file);
    }

    log_file.close();
    return 0;
}
EOF

# ==========================================
# COMPILATION
# ==========================================
echo "[+] Compiling C++ verification engine with -O3 ARM optimizations..."
clang++ -O3 -std=c++17 "$CPP_FILE" -o "$BIN_FILE"

if [ $? -ne 0 ]; then
    echo "[-] Compilation failed."
    exit 1
fi

# ==========================================
# EXECUTION
# ==========================================
echo -e "\n================================================================"
echo " STARTING AUDIT PASS: SCANNING ALL PARTITIONS FOR UNPAIRED PHOTOS"
echo "================================================================"

./"$BIN_FILE" "$REPORT_FILE" "$SONAL_DIR" "$ROSHAN_DIR"

echo -e "\n\n================================================================"
echo " AUDIT COMPLETE                                                 "
echo "================================================================"
echo "Report written to: $(pwd)/$REPORT_FILE"
