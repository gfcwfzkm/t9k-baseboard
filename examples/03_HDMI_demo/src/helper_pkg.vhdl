-- TEROSHDL Documentation:
--! @title Helper Package
--! @author Pascal G. (gfcwfzkm)
--! @version 1.0
--! @date 15.06.2025
--! @brief Provides a function to count the number of '1's in a std_logic_vector.
--!
--! This package is used in the TMDS encoder to calculate the DC balance level.
--! It provides a function to count the number of '1's in a std_logic_vector, which is useful for
--! ensuring the DC balance of the encoded TMDS data.

library ieee;
use ieee.std_logic_1164.all;

package helper_pkg is

    --! Function to count the number of '1's in a std_logic_vector
    function count_ones(s : std_logic_vector) return natural;

end package helper_pkg;

package body helper_pkg is
    function count_ones(s : std_logic_vector) return natural is
        variable temp : natural := 0;
    begin
        for i in s'range loop
            if s(i) = '1' then
                temp := temp + 1; 
            end if;
        end loop;
           return temp;
    end function count_ones;
end package body;