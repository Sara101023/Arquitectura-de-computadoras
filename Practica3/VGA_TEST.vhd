library ieee;
use ieee.std_logic_1164.all;     
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all;    


Entity VGA_TEST Is
    PORT(
        CLOCK_50   : IN  STD_LOGIC;                 -- Reloj de 50 MHz de la tarjeta
        VGA_HS     : OUT STD_LOGIC;                 -- Sincronía horizontal
        VGA_VS     : OUT STD_LOGIC;                 -- Sincronía vertical
        VGA_SYNC_N : OUT STD_LOGIC;                 -- Sincronía compuesta (no usada, se fuerza a '1')
        VGA_BLANK_N: OUT STD_LOGIC;                 -- Señal de blanking (no se usa, se fuerza a '1')
        VGA_CLK    : OUT STD_LOGIC;                 -- Reloj hacia el conector VGA
        SW         : IN  STD_LOGIC_VECTOR(1 downto 0);  -- Switches de la tarjeta (2 bits)
        KEY        : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);  -- Botones de la tarjeta (4 bits)
        VGA_R      : OUT STD_LOGIC_VECTOR(7 downto 0);  -- Canal rojo (8 bits)
        VGA_B      : OUT STD_LOGIC_VECTOR(7 downto 0);  -- Canal azul (8 bits)
        VGA_G      : OUT STD_LOGIC_VECTOR(7 downto 0)   -- Canal verde (8 bits)
    );
END VGA_TEST;


Architecture MAIN of VGA_TEST is

    -- Señales internas
    Signal VGACLK : STD_LOGIC;  -- Reloj generado por el PLL para el módulo de sincronía VGA
    Signal RESET  : STD_LOGIC;  -- Señal de reset para el PLL (no se asigna en este código)

    -- Declaración del componente SYNC, encargado de generar las señales de sincronía y color
    COMPONENT SYNC IS
        PORT(
            CLK   : IN  STD_LOGIC;                       -- Reloj de entrada
            HSYNC : OUT STD_LOGIC;                       -- Salida de sincronía horizontal
            VSYNC : OUT STD_LOGIC;                       -- Salida de sincronía vertical
            R     : OUT STD_LOGIC_VECTOR(7 downto 0);    -- Salida de color rojo
            G     : OUT STD_LOGIC_VECTOR(7 downto 0);    -- Salida de color verde
            B     : OUT STD_LOGIC_VECTOR(7 downto 0);    -- Salida de color azul
            KEYS  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Entradas de botones
            S     : IN  STD_LOGIC_VECTOR(1 downto 0)     -- Entradas de switches
        );
    END COMPONENT SYNC;

    -- Declaración del componente PLL, generado por el Megawizard/QSYS
    component pll is
        port (
            clkin_clk   : in  std_logic := 'X'; -- Reloj de entrada 
            reset_reset : in  std_logic := 'X'; -- Señal de reset del PLL
            clkout1_clk : out std_logic;        -- Primera salida de reloj (se usa para VGA_CLK)
            clkout2_clk : out std_logic         -- Segunda salida de reloj (se usa para VGACLK)
        );
    END COMPONENT pll;

BEGIN

    -- Forzamos las señales de blanking y sync compuesto a '1'
    -- indicando que no se usan estos mecanismos en este diseño.
    VGA_BLANK_N <= '1';  -- Siempre habilitado, no se realiza blanking por esta señal
    VGA_SYNC_N  <= '1';  -- No se utiliza sincronía compuesta

    -- Instancia del PLL
    -- Entradas:
    --   clkin_clk   <- CLOCK_50
    --   reset_reset <- RESET
    -- Salidas:
    --   clkout1_clk -> VGA_CLK: reloj que va al puerto VGA
    --   clkout2_clk -> VGACLK: reloj que se usa internamente en el módulo SYNC
    C: pll 
        PORT MAP (
            CLOCK_50,  -- clkin_clk
            RESET,     -- reset_reset
            VGA_CLK,   -- clkout1_clk
            VGACLK     -- clkout2_clk
        );

    -- Instancia del módulo SYNC
    -- Entradas:
    --   CLK  <- VGACLK: reloj generado por el PLL
    --   KEYS <- KEY: botones de la tarjeta
    --   S    <- SW: switches de la tarjeta
    -- Salidas:
    --   HSYNC -> VGA_HS
    --   VSYNC -> VGA_VS
    --   R     -> VGA_R
    --   G     -> VGA_G
    --   B     -> VGA_B
    C1: SYNC 
        PORT MAP(
            VGACLK, -- CLK
            VGA_HS, -- HSYNC
            VGA_VS, -- VSYNC
            VGA_R,  -- R
            VGA_G,  -- G
            VGA_B,  -- B
            KEY,    -- KEYS
            SW      -- S
        );

END MAIN;

--PLL(Lazo de Enganche de Fase) es una señal eléctrica cuya fase está relacionada 
--con la fase de una señal de entrada
