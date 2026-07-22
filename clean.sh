#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================
TARGET_DIR="/storage/7AF87657F876119D/Android/data/com.termux/files/Wedding_Backup/Roshan_Wedding"
CPP_FILE="nef_cleaner.cpp"
BIN_FILE="nef_cleaner"

# ==========================================
# INITIALIZATION & COMPILER CHECK
# ==========================================
echo "================================================================"
echo " DELETION ENGINE: INITIALIZING ENVIRONMENT                      "
echo "================================================================"

if ! command -v clang++ &> /dev/null; then
    echo "[-] Clang missing. Installing build tools..."
    pkg update && pkg install clang -y
fi

# ==========================================
# EMBEDDED C++ DELETION SOURCE
# ==========================================
cat << 'EOF' > "$CPP_FILE"
// nef_cleaner.cpp
// Single-threaded, FUSE-aware .NEF redundancy cleaner.
// Deletes a .NEF only when an exact-stem .JPG/.JPEG twin exists in the SAME directory.

#include <filesystem>
#include <unordered_set>
#include <vector>
#include <string>
#include <utility>
#include <cstdint>
#include <cstdio>
#include <cctype>
#include <system_error>

namespace fs = std::filesystem;

static std::uint64_t g_scanned = 0;
static std::uint64_t g_deleted = 0;
static std::uint64_t g_errors  = 0;

static inline std::string to_lower(std::string s) {
    for (auto& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

static inline void print_counter() {
    std::fprintf(stderr,
        "\rScanned: %llu | Deleted: %llu | Errors: %llu   ",
        static_cast<unsigned long long>(g_scanned),
        static_cast<unsigned long long>(g_deleted),
        static_cast<unsigned long long>(g_errors));
    std::fflush(stderr);
}

static void process_directory(const fs::path& dir) {
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
    jpg_stems.reserve(entries.size() * 2);

    std::vector<fs::path> subdirs;
    subdirs.reserve(32);

    std::vector<std::pair<fs::path, std::string>> nef_candidates;
    nef_candidates.reserve(entries.size() / 4);

    for (const auto& e : entries) {
        std::error_code tmp_ec;
        if (e.is_directory(tmp_ec)) {
            subdirs.push_back(e.path());
            continue;
        }

        const fs::path& p   = e.path();
        const std::string ex = to_lower(p.extension().string());

        if (ex == ".jpg" || ex == ".jpeg") {
            jpg_stems.insert(p.stem().string());
        } else if (ex == ".nef") {
            nef_candidates.emplace_back(p, p.stem().string());
        }
    }

    for (const auto& [p, stem] : nef_candidates) {
        if (jpg_stems.count(stem) != 0) {
            std::error_code rec;
            const bool removed = fs::remove(p, rec);
            if (rec) {
                ++g_errors;           
            } else if (removed) {
                ++g_deleted;          
            }
        }
    }

    g_scanned += entries.size();
    print_counter();

    for (const fs::path& sd : subdirs) {
        process_directory(sd);
    }
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s <root_dir>\n", argv[0]);
        return 1;
    }

    std::error_code ec;
    const fs::path root(argv[1]);
    if (!fs::is_directory(root, ec)) {
        std::fprintf(stderr, "Error: '%s' is not a directory: %s\n",
                     argv[1], ec.message().c_str());
        return 1;
    }

    process_directory(root);
    std::fprintf(stderr, "\n");
    return (g_errors == 0) ? 0 : 2;
}
EOF

# ==========================================
# COMPILATION
# ==========================================
echo "[+] Compiling C++ deletion engine with -O3 ARM optimizations..."
clang++ -O3 -std=c++17 "$CPP_FILE" -o "$BIN_FILE"

if [ $? -ne 0 ]; then
    echo "[-] Compilation failed."
    exit 1
fi

# ==========================================
# EXECUTION
# ==========================================
echo -e "\n================================================================"
echo " STARTING PURGE PASS: DELETING REDUNDANT .NEF FILES             "
echo "================================================================"

./"$BIN_FILE" "$TARGET_DIR"

echo -e "\n================================================================"
echo " PURGE COMPLETE. CHECKING RECLAIMED STORAGE...                  "
echo "================================================================"
df -h | grep /storage/
