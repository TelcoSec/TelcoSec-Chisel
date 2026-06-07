#!/bin/bash
set -e
echo "=== Testing RocksDB compilation on WSL Kali Linux ==="

# Clean up any previous runs
rm -rf /tmp/test-rocksdb-venv /tmp/rocksdb-compile /tmp/test_db

cd /tmp
python3 -m venv test-rocksdb-venv
source test-rocksdb-venv/bin/activate
pip install --upgrade pip
pip install "Cython<3.0.0" setuptools wheel

# Create a temporary compilation directory
mkdir -p rocksdb-compile
cd rocksdb-compile

# Download rocksdb source
pip download --no-binary :all: --no-deps rocksdb
tar -xzf rocksdb-*.tar.gz
cd rocksdb-*/

# Apply our C++ patch
python3 -c "
with open('rocksdb/cpp/filter_policy_wrapper.hpp', 'r') as f:
    content = f.read()

replacement = '''            virtual const char* CompatibilityName() const override {
                return this->name.c_str();
            }

            virtual rocksdb::FilterBitsBuilder* GetBuilderWithContext(
                const rocksdb::FilterBuildingContext&) const override {
                return nullptr;
            }

            virtual rocksdb::FilterBitsReader* GetFilterBitsReader(
                const rocksdb::Slice&) const override {
                return nullptr;
            }

            virtual const char* Name() const {'''

new_content = content.replace('            virtual const char* Name() const {', replacement)
with open('rocksdb/cpp/filter_policy_wrapper.hpp', 'w') as f:
    f.write(new_content)
"

# Patch 2: _rocksdb.pyx & table_factory.pxd & filter_policy.pxd & setup.py
python3 -c "
import re, pathlib

pyx = pathlib.Path('rocksdb/_rocksdb.pyx').read_text()

# Remove properties from ColumnFamilyOptions/Options
for prop in ['purge_redundant_kvs_while_flush', 'rate_limit_delay_max_milliseconds', 'soft_rate_limit', 'hard_rate_limit', 'max_mem_compaction_level', 'skip_log_error_on_recovery']:
    pyx = re.sub(
        r'\s*property ' + prop + r':\s*'
        r'def __get__\(self\):.*?'
        r'def __set__\(self, \w+\):.*?self\.(copts|opts)\.' + prop + r'\s*=\s*\w+\b[^\n]*\n',
        '\n',
        pyx,
        flags=re.DOTALL
    )

# Comment out hash_index_allow_collision and block_cache_compressed assignments in BlockBasedTableFactory
pyx = pyx.replace(
    '        if hash_index_allow_collision:\n            table_options.hash_index_allow_collision = True\n        else:\n            table_options.hash_index_allow_collision = False',
    '        # disabled hash_index_allow_collision for RocksDB 7+'
)
pyx = pyx.replace(
    '        if block_cache_compressed is not None:\n            table_options.block_cache_compressed = block_cache_compressed.get_cache()',
    '        # disabled block_cache_compressed for RocksDB 7+'
)

# Patch PyBloomFilterPolicy in _rocksdb.pyx
pyx = pyx.replace(
    '    def create_filter(self, keys):\n        cdef string dst\n        cdef vector[Slice] c_keys\n\n        for key in keys:\n            c_keys.push_back(bytes_to_slice(key))\n\n        self.policy.get().CreateFilter(\n            vector_data(c_keys),\n            <int>c_keys.size(),\n            cython.address(dst))\n\n        return string_to_bytes(dst)',
    '    def create_filter(self, keys):\n        raise NotImplementedError(\"create_filter is not supported in RocksDB 7+\")'
)
pyx = pyx.replace(
    '    def key_may_match(self, key, filter_):\n        return self.policy.get().KeyMayMatch(\n            bytes_to_slice(key),\n            bytes_to_slice(filter_))',
    '    def key_may_match(self, key, filter_):\n        raise NotImplementedError(\"key_may_match is not supported in RocksDB 7+\")'
)

pathlib.Path('rocksdb/_rocksdb.pyx').write_text(pyx)
print('Patched _rocksdb.pyx successfully')

# Patch table_factory.pxd
pxd = pathlib.Path('rocksdb/table_factory.pxd').read_text()
pxd = pxd.replace('        cpp_bool hash_index_allow_collision\n', '')
pxd = pxd.replace('        shared_ptr[Cache] block_cache_compressed\n', '')
pathlib.Path('rocksdb/table_factory.pxd').write_text(pxd)
print('Patched table_factory.pxd successfully')

# Patch filter_policy.pxd
f_pxd = pathlib.Path('rocksdb/filter_policy.pxd').read_text()
f_pxd = f_pxd.replace('        void CreateFilter(const Slice*, int, string*) nogil except+\n', '')
f_pxd = f_pxd.replace('        cpp_bool KeyMayMatch(const Slice&, const Slice&) nogil except+\n', '')
pathlib.Path('rocksdb/filter_policy.pxd').write_text(f_pxd)
print('Patched filter_policy.pxd successfully')

# Patch setup.py to use C++17 (required by modern RocksDB headers on Ubuntu 24.04 noble)
setup_py = pathlib.Path('setup.py').read_text()
setup_py = setup_py.replace(\"'-std=c++11'\", \"'-std=c++17'\")
pathlib.Path('setup.py').write_text(setup_py)
print('Patched setup.py to compile with C++17 successfully')
"

# Remove the pre-compiled C++ source file so setuptools/pip is forced
# to run Cython to regenerate _rocksdb.cpp from our patched _rocksdb.pyx.
rm -f rocksdb/_rocksdb.cpp

# Also create the dummy backupable_db.h if it doesn't exist on this system
if [ ! -f /usr/include/rocksdb/utilities/backupable_db.h ]; then
  echo "=== Creating compatibility header backupable_db.h ==="
  mkdir -p /usr/include/rocksdb/utilities/
  cat << 'EOF' > /usr/include/rocksdb/utilities/backupable_db.h
#pragma once
#include "rocksdb/utilities/backup_engine.h"
namespace rocksdb {
  typedef BackupEngineOptions BackupableDBOptions;
  typedef BackupEngine BackupableDB;
  typedef BackupInfo BackupableDBInfo;
}
EOF
fi

# Run compilation
pip install --no-build-isolation .

# Verify import and basic database operation
python -c "import rocksdb; db = rocksdb.DB('/tmp/test_db', rocksdb.Options(create_if_missing=True)); db.put(b'test_key', b'test_val'); print('Import and write test passed! Val:', db.get(b'test_key'))"

echo "=== Compilation and import test completed successfully! ==="
