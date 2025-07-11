"""
Run testbenches for the simple Overture CPU design.

This script runs all testbenches in the `testbenches` directory of the simple CPU design.
It requires the first line of these testbenches to list the vhdl modules it depends on, for example:
-- Dependency: src/condition.vhdl

It uses the nvc simulator (https://github.com/nickg/nvc) to run the testbenches
but provides a fallback to ghdl (https://ghdl.github.io/ghdl/) if nvc is not available.
( ghdl fallback has not been tested, so please report issues if it does not work as expected. )

To generate waveforms, set the `capture_waveforms` variable to `True`.
It will create a `waveforms` directory in the root of the simple CPU design and store the waveforms there.

To easily observe the waveforms, you can use Surfer ( https://surfer-project.org/ ) and 
open the generated `.fst` or `.ghw` files. The `Surfer` directory has preconfigured
overview to easily see all required signals in the waveforms.
"""

import os
import shutil
import subprocess
import time

if __name__ == "__main__":
    # Capture waveforms too?
    capture_waveforms = True  # Set to True if you want to capture waveforms

    # Check if nvc or ghdl is installed
    nvc_found = False
    ghdl_found = False

    try:
        subprocess.run(["nvc", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        nvc_found = True
    except subprocess.CalledProcessError:
        print("\033[1;31m\033[1mError: nvc is not installed or not found in PATH.\033[0m")
    
    if not nvc_found:
        try:
            subprocess.run(["ghdl", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            ghdl_found = True
        except subprocess.CalledProcessError:
            print("\033[1;31m\033[1mError: ghdl is not installed or not found in PATH.\033[0m")
    
    if not nvc_found and not ghdl_found:
        print("\033[1;31m\033[1mPlease install nvc or ghdl to run the testbenches.\033[0m")
        exit(1)

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
    # If a testbench does not have the dependency-line, it won't be added to the dependencies 
    # dictionary and thus excluded from any execution.
    dependencies = {}
    for tb in testbenches:
        with open(os.path.join(testbench_dir, tb), "r") as f:
            first_line = f.readline().strip()
            if first_line.startswith("-- Dependency:"):
                # Extract the dependencies from the first line
                dep_files = first_line[len("-- Dependency:"):].strip().split(",")
                dep_files = [dep.strip().replace("/", os.sep).replace("\\", os.sep) for dep in dep_files]
                dependencies[tb] = dep_files

    # Check if a suitable folder for waveforms exists, if not create it
    if capture_waveforms:
        waveform_dir = os.path.join(script_dir, "waveforms")
        if not os.path.exists(waveform_dir):
            os.makedirs(waveform_dir)
            print(f"\033[1;32m\033[1mCreated waveform directory: {waveform_dir}\033[0m")
        else:
            print(f"\033[1;32m\033[1mUsing existing waveform directory: {waveform_dir}\033[0m")

    error_counter = 0
    skipped_counter = 0
    # Run each testbench with nvc and its dependencies
    for tb, deps in dependencies.items():
        # Create a list of dependency files with their full paths
        dep_paths = [os.path.join(script_dir, dep) for dep in deps if os.path.exists(os.path.join(script_dir, dep))]
        if not dep_paths:
            print("\033[1;33m\033[1mNo valid dependencies found for {tb}. Skipping.\033[0m")
            skipped_counter += 1
            continue
        
        # Get the testbench full path
        tb_path = os.path.join(testbench_dir, tb)
        if not os.path.exists(tb_path):
            print("\033[1;33m\033[1mTestbench file {tb_path} does not exist. Skipping.\033[0m")
            skipped_counter += 1
            continue

        # get the testbench name without the .vhdl extension - this will be the top level module name
        tb_name = os.path.splitext(tb)[0]

        # If waveforms are captured, set the output file name
        if capture_waveforms:
            waveform_tb_dir = os.path.join(waveform_dir, tb_name)
            if nvc_found:
                wave_command = f'--wave={waveform_tb_dir}.fst --dump-arrays'
            elif ghdl_found:
                wave_command = f'--wave={waveform_tb_dir}.ghw'
            else:
                wave_command = ""
        else:
            wave_command = ""

        # Prepare the command to run nvc
        nvc_command = f'nvc -a {" ".join(dep_paths)} {tb_path} --check-synthesis -e {tb_name} -r --stop-time=1ms {wave_command}'
        ghdl_command = f'ghdl -a {" ".join(dep_paths)} {tb_path} && ghdl -e {tb_name} && ghdl -r {tb_name} --stop-time=1ms {wave_command}'

        # Execute the command, capturing/printing the output
        if nvc_found:
            process = subprocess.run(nvc_command, shell=True, text=True, capture_output=True)
        elif ghdl_found:
            process = subprocess.run(ghdl_command, shell=True, text=True, capture_output=True)
        else:
            print("\033[1;31m\033[1mNo VHDL simulator found. Please install nvc or ghdl.\033[0m")
            exit(1)

        # Check the return code and print the output
        if process.returncode != 0:
            print("\033[1;31mError running testbench {tb}:\033[0m")
            print(process.stderr)
            error_counter += 1
        else:
            print(f"\033[1;32m\033[1mTestbench {tb} ran successfully:\033[0m")
            print(process.stdout)
            print(process.stderr)
    
    # Print the summary of testbench results
    print(f'\033[1;34m\033[1m{len(testbenches)} testbenches found, {skipped_counter} skipped, {error_counter} failed.\033[0m')

    # Clean up the 'work' directory if it exists
    work_dir = os.path.join(os.getcwd(), "work")
    
    if os.path.exists(work_dir):
        # Wait a second to ensure all processes are done
        time.sleep(0.5)
        # Remove the work directory

        try:
            shutil.rmtree(work_dir)
            print(f"\033[1;32m\033[1mCleaned up work directory: {work_dir}\033[0m")
        except Exception as e:
            print(f"\033[1;31m\033[1mFailed to clean up work directory: {e}\033[0m")
    
    # Run each testbench with nvc and its dependencies