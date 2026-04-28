library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


Package ctrl is
    -- Procedimiento SQ:
    -- Determina si el pixel actual (Xcur,Ycur) pertenece a un
    -- rectángulo ubicado en (Xpos,Ypos) de tamaño 500x300.
    -- DRAW = '1' si pertenece, '0' si no.
    -- RGB puede devolver un color base (opcional).
    Procedure SQ(
        SIGNAL Xcur, Ycur : IN INTEGER;                 -- pixel actual
        SIGNAL Xpos, Ypos : IN INTEGER;                 -- posición del cuadro
        SIGNAL RGB : OUT STD_LOGIC_VECTOR(7 downto 0);  -- color 
        SIGNAL DRAW : OUT STD_LOGIC                     
    );
End ctrl;

-- Implementación real del procedimiento SQ
Package body ctrl is

    Procedure SQ(
        SIGNAL Xcur, Ycur : IN INTEGER;
        SIGNAL Xpos, Ypos : IN INTEGER;
        SIGNAL RGB : OUT STD_LOGIC_VECTOR(7 downto 0);
        SIGNAL DRAW : OUT STD_LOGIC
    ) is
    Begin
        --tamaño rectangulo
        If ( Xcur > Xpos AND Xcur < (Xpos + 500) AND
             Ycur > Ypos AND Ycur < (Ypos + 300) ) then

            RGB  <= "11111111";   -- Color blanco (no usado en SYNC)
            DRAW <= '1';          -- Se debe dibujar en este pixel

        Else
            DRAW <= '0';          -- Fuera de la figura
        End If;

    End SQ;

END ctrl;


--Xcur	posición horizontal del pixel actual	0 → 1688
--Ycur	posición vertical del pixel actual		0 → 1066
--Xpos	posición X donde está tu cuadrado		500
--Ypos	posición Y donde está tu cuadrado		300
