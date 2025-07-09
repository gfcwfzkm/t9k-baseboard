"""
Run testbenches for the simple Overture CPU design.

This script runs all testbenches in the `testbenches` directory of the simple CPU design.
It requires the first line of these testbenches to list the vhdl modules it depends on, for example:
-- Dependency: src/condition.vhdl

It uses the nvc simulator (https://github.com/nickg/nvc) to run the testbenches.
"""

import os
import subprocess

if __name__ == "__main__":
    # Get the current directory of this script - it should be in the root of the simple CPU design
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Look for all testbenches in the testbenches directory
    testbench_dir = os.path.join(script_dir, "testbench")
    if not os.path.exists(testbench_dir):
        print(f"Testbench directory {testbench_dir} does not exist.")
        exit(1)
    testbenches = [f for f in os.listdir(testbench_dir) if f.endswith(".vhdl")]

    # Read the first line of each testbench file to get the vhdl source file dependencies
    # It may contain multiple, comma-seperated files and should look like this:
    # -- Dependency: src/condition.vhdl, src/alu.vhdl
    # If the directory seperator does not match the current OS, it will be replaced
    # with the correct one.
    dependencies = {}
    for tb in testbenches:
        with open(os.path.join(testbench_dir, tb), "r") as f:
            first_line = f.readline().strip()
            if first_line.startswith("-- Dependency:"):
                # Extract the dependencies from the first line
                dep_files = first_line[len("-- Dependency:"):].strip().split(",")
                dep_files = [dep.strip().replace("/", os.sep).replace("\\", os.sep) for dep in dep_files]
                dependencies[tb] = dep_files
    
    error_counter = 0
    # Run each testbench with nvc and its dependencies
    for tb, deps in dependencies.items():
        # Create a list of dependency files with their full paths
        dep_paths = [os.path.join(script_dir, dep) for dep in deps if os.path.exists(os.path.join(script_dir, dep))]
        if not dep_paths:
            print("\033[1;33m\033[1mNo valid dependencies found for {tb}. Skipping.\033[0m")
            continue
        
        # Get the testbench full path
        tb_path = os.path.join(testbench_dir, tb)
        if not os.path.exists(tb_path):
            print("\033[1;33m\033[1mTestbench file {tb_path} does not exist. Skipping.\033[0m")
            continue

        # get the testbench name without the .vhdl extension - this will be the top level module name
        tb_name = os.path.splitext(tb)[0]

        # Prepare the command to run nvc
        nvc_command = f'nvc -a {" ".join(dep_paths)} {tb_path} --check-synthesis -e {tb_name} -r'

        # Execute the command, capturing/printing the output
        process = subprocess.run(nvc_command, shell=True, text=True, capture_output=True)
        if process.returncode != 0:
            print("\033[1;31mError running testbench {tb}:\033[0m")
            print(process.stderr)
            error_counter += 1
        else:
            print(f"\033[1;32m\033[1mTestbench {tb} ran successfully:\033[0m")
            print(process.stdout)
            print(process.stderr)
    
    # Print the summary of testbench results
    if error_counter > 0:
        print(f"\033[1;31m\033[1m{error_counter} testbenches failed.\033[0m")
    else:
        print("\033[1;32m\033[1mAll testbenches ran successfully.\033[0m")

    
    # Run each testbench with nvc and its dependencies