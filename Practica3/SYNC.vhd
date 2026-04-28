Library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ctrl.all;   


Entity SYNC is
    Port(
        CLK   : IN  std_logic;                         -- Reloj deL PIXEL ~108 MHz para 1280x1024.60Hz
        HSYNC : OUT std_logic;                         -- Sincronía horizontal
        VSYNC : OUT std_logic;                         -- Sincronía vertical
        R, G, B : OUT std_logic_vector(7 downto 0);    -- Salidas de color
        KEYS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);        -- Botones (activos en bajo)
        S    : IN STD_LOGIC_VECTOR(1 downto 0)         -- Switches de control
    );
end SYNC;

Architecture MAIN of SYNC is


    
    Signal RGB : STD_LOGIC_VECTOR(7 downto 0);

    -- Coordenadas del cuadrado 1 (SQ_X1, SQ_Y1) y cuadrado 2 (SQ_X2, SQ_Y2)
    -- El rango incluye todo el intervalo horizontal (0..1688)
    Signal SQ_X1, SQ_Y1 : INTEGER RANGE 0 TO 1688 := 500;
    Signal SQ_X2, SQ_Y2 : INTEGER RANGE 0 TO 1688 := 600;

    -- Señales que indican si se debe dibujar el cuadrado 1 o 2 en el pixel actual
    Signal DRAW1, DRAW2 : STD_LOGIC;

    -- Posición actual del pixel que se está “pintando”
    Signal HPOS : integer Range 0 to 1688 := 0;   -- Horizontal
    Signal VPOS : integer Range 0 to 1066 := 0;   -- Vertical

Begin

    -- Llamadas al procedimiento SQ que decide si el pixel actual está sobre el cuadrado
    SQ(HPOS, VPOS, SQ_X1, SQ_Y1, RGB, DRAW1);  -- Cuadrado 1
    SQ(HPOS, VPOS, SQ_X2, SQ_Y2, RGB, DRAW2);  -- Cuadrado 2

    -- Proceso secuencial sincronizado al reloj
    Process (CLK)
    Begin
        If (CLK'Event and CLK = '1') then  -- Flanco de subida del reloj

            -- 1
            If (DRAW1 = '1') then
                -- Si S(0) está activado, cuadrado color moradooo
                If (S(0) = '1') then
                    R <= "01100110";        
                    G <= (Others => '0');   
                    B <= "11111111";        
                Else
                    -- Si S(0) no está activado, color blanco
                    R <= (others => '1');
                    G <= (others => '1');
                    B <= (others => '1');
                End If;
            End If;    

            --2
            If (DRAW2 = '1') then
                -- Si S(1) está activado, cuadrado color azul cruz azul
                If (S(1) = '1') then
                    R <= (Others => '0');   
                    G <= "10101010";        
                    B <= "11111111";        
                Else
                    -- Si S(1) no está activado, color blanco
                    R <= (others => '1');
                    G <= (others => '1');
                    B <= (others => '1');
                End If;
            End If;

            -- Si no se dibuja ningún cuadrado en el pixel actual, fondo negro
            If (DRAW1 = '0' AND DRAW2 = '0') then
                R <= (others => '0');
                G <= (others => '0');
                B <= (others => '0');
            End if;

            -- Barrido de pantalla

            -- Contador horizontal
            If (HPOS < 1688) then--cuando llega, reinciia a 0, osea, termino un frame entero
                HPOS <= HPOS + 1;
            Else
                HPOS <= 0;

                -- Al terminar una línea, se incrementa la posición vertical
                If (VPOS < 1066) then
                    VPOS <= VPOS + 1;
                Else
                    -- Al terminar todas las líneas, se reinicia el frame
                    VPOS <= 0;

                    -- Moviendo cuadro 1 solo 5 pixeles
                    If (S(0) = '1') then
                        If (KEYS(0) = '0') then  -- Mover a la derecha
                            SQ_X1 <= SQ_X1 + 5;
                        End If;

                        If (KEYS(1) = '0') then  -- Mover a la izquierda
                            SQ_X1 <= SQ_X1 - 5;
                        End If;

                        If (KEYS(2) = '0') then  -- Mover hacia arriba
                            SQ_Y1 <= SQ_Y1 - 5;
                        End If;

                        If (KEYS(3) = '0') then  -- Mover hacia abajo
                            SQ_Y1 <= SQ_Y1 + 5;
                        End If;
                    End If;

                    -- Moviendo cuadro 2 solo 5 pixeles
                    If (S(1) = '1') then
                        If (KEYS(0) = '0') then  -- Mover a la derecha
                            SQ_X2 <= SQ_X2 + 5;
                        End If;

                        If (KEYS(1) = '0') then  -- Mover a la izquierda
                            SQ_X2 <= SQ_X2 - 5;
                        End If;

                        If (KEYS(2) = '0') then  -- Mover hacia arriba
                            SQ_Y2 <= SQ_Y2 - 5;
                        End If;

                        If (KEYS(3) = '0') then  -- Mover hacia abajo
                            SQ_Y2 <= SQ_Y2 + 5;
                        End If;--botones activo bajo, x eso "=0"
                    End If;

                End If;  -- Fin VPOS
            End If;      -- Fin HPOS

            -- Generación de HSYNC / VSYNC

            -- Pulso de sincronía horizontal (activo en bajo)
            If (HPOS > 48 and HPOS < 160) then
                HSYNC <= '0';
            Else
                HSYNC <= '1';
            End If;
            
            -- Pulso de sincronía vertical (activo en bajo)
            If (VPOS > 0 and VPOS < 4) then
                VSYNC <= '0';
            Else
                VSYNC <= '1';
            End If;

            -- Para saber como colocar cada linea y frame

        End If;  -- Fin flanco de reloj
    End Process;

End MAIN;
