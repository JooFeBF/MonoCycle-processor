#!/usr/bin/env python3
"""
Extract data memory initialization from ELF file for Harvard architecture
Creates proper program_data.hex containing only initialized data values
"""

import struct
import sys

try:
    from elftools.elf.elffile import ELFFile
    HAS_ELFTOOLS = True
except ImportError:
    HAS_ELFTOOLS = False

def extract_data_memory(elf_filename, output_hex):
    if HAS_ELFTOOLS:
        with open(elf_filename, 'rb') as f:
            elf = ELFFile(f)
            
            # Find .data section
            data_section = elf.get_section_by_name('.data')
            if not data_section:
                print("No .data section found, creating empty data memory")
                data_bytes = b''
            else:
                data_bytes = data_section.data()
                print(f"Found .data section: {len(data_bytes)} bytes")
            
            # Pad to 512 bytes (128 words * 4 bytes) - conservative for hardware
            data_memory = data_bytes + b'\x00' * (512 - len(data_bytes))
            
            # Convert to hex words (little-endian)
            with open(output_hex, 'w') as hex_file:
                for i in range(0, 512, 4):
                    word_bytes = data_memory[i:i+4]
                    # Convert to 32-bit little-endian word
                    word = struct.unpack('<I', word_bytes)[0]
                    hex_file.write(f'{word:08x}\n')
            
            print(f"Created {output_hex} with proper data memory initialization")
    else:
        # Fallback using objcopy
        fallback_extract_data(elf_filename, output_hex)

def fallback_extract_data(elf_file, hex_file):
    print("Using objcopy fallback for data extraction")
    import subprocess
    import os
    
    # Extract .data section as binary
    temp_bin = f"{hex_file}.tmp"
    try:
        subprocess.run(['riscv64-elf-objcopy', '-O', 'binary', '--only-section=.data', elf_file, temp_bin], check=True)
        
        # Convert to hex
        if os.path.getsize(temp_bin) == 0:
            # No data section, create empty memory
            data_bytes = b'\x00' * 512
        else:
            with open(temp_bin, 'rb') as f:
                data_bytes = f.read()
            # Pad to 512 bytes
            data_bytes += b'\x00' * (512 - len(data_bytes))
        
        # Convert to hex words
        with open(hex_file, 'w') as f:
            for i in range(0, 512, 4):
                word_bytes = data_bytes[i:i+4]
                word = struct.unpack('<I', word_bytes)[0]
                f.write(f'{word:08x}\n')
        
        os.remove(temp_bin)
        print(f"Created {hex_file} using objcopy fallback")
    except subprocess.CalledProcessError as e:
        print(f"Error using objcopy: {e}")
        # Create empty data memory as last resort
        with open(hex_file, 'w') as f:
            for i in range(128):  # 128 words of zeros
                f.write('00000000\n')
        print(f"Created empty {hex_file} as fallback")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 extract_data.py input.elf output.hex")
        sys.exit(1)
    
    extract_data_memory(sys.argv[1], sys.argv[2])