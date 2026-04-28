
	--
	-- Programa: Arquitectura de 8 bits
	-- Elaborado por: 
	--	Gutierrez de la Rosa Diego Armando
	-- Garcia Laureano Omar Alejandro
	-- Sanchez Sanchez Luis Gerardo 
	-- Tellez Perez Juan Manuel
	-- Perez Aguilar Ariadna Jaqueline
	-- Rodriguez Enriquez Miguel Yishay
	-- Perez Gomez Santiago
	--
	-- Fecha: 24 de Marzo de 2021
	--
	-- Este programa utiliza una libreria para manejar el LCD
	-- Dicha libreria pertenece a Intesc, url: https://www.intesc.mx/
	--
	-- La mayoria de las instrucciones se sacaron de la siguientes paginas:
	-- http://www.fdi.ucm.es/profesor/mendias/512/docs/tema5.pdf
	-- http://cv.uoc.edu/annotation/8255a8c320f60c2bfd6c9f2ce11b2e7f/619469/PID_00218277/PID_00218277.html
	-- https://www.exabyteinformatica.com/uoc/Informatica/Estructura_de_computadores/Estructura_de_computadores_(Modulo_2).pdf
	------------------------------------------------------------------------------------------
	--Programa porbado por:
	--Ariadna Sarai Lobato Brito
	--Luis Angel Cedeño Palestina
	--Fecha:26 de Septiembre de 2025
	---------------------------------------------------------------------------------------------------------------------
	--
	-- Las 22 instrucciones a realizar son:
	--
	-- 1		MOV				AX,d		Carga en el acumulador el valor de "d"
	--	2		MOV				IX,AX		Carga el valor de la parte baja del acumulador en el registro indice
	-- 3		MOV				AX,IX		Carga el valor del registro indice la parte baja del acumulador
	-- 4 		CLA							Limpia el acumulador
	-- 5		SET				AX			Coloca todos los bits del acumulador en 1
	-- 6		ADD				AX,d		Suma al acumulador el valor de "d"
	-- 7		SUB				AX,d		Resta al acumulador el valor de "d"
	-- 8		MUL				AX,d		Multiplica por el acumulador el valor de "d"
	-- 9		DIV				AX,d		Divide el acumulador entre el valor de "d"
	-- 10		INC				AX			Incrementa el valor del acumulador en 1 
	-- 11		DEC				AX			Decrementa el valor del acumulador en 1
	-- 12		CMP				AX,d		Compara el valor del acumulador con el de "d", restando y lo muestra sin guardarlo
	-- 13		AND				AX,d		
	-- 14		OR					AX,d
	-- 15		XOR				AX,d
	-- 16		NOT				AX
	-- 17		LSL				AX,n		Desplaza de forma lógica el valor del acumulador "n" bits a la izquierda
	-- 18		LSR				AX,n		Desplaza de forma lógica el valor del acumulador "n" bits a la derecha
	-- 19		RL					AX,n		Rota de forma lógica "n" bits hacia la izquierda el valor del acumulador 
	-- 20		RR					AX,n		Rota de forma lógica "n" bits hacia la derecha el valor del acumulador 
	-- 21		BCLR 				AX,n		Coloca el bit "n" del acumulador en 0
	-- 22		BSET 				AX,n		Coloca el bit "n" del acumulador en 1
	--
	---------------------------------------------------------------------------------------------------------------------
	
	-- Bibliotecas y paquetes a utilizar
	library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;
	use work.ALU_UC.all;
	use work.bcd_7seg.all;
	USE WORK.COMANDOS_LCD_REVD.ALL;
	
	---------------------------------------------------------------------------------------------------------------------
	--
	-- Inicio de la entidad
	--
	---------------------------------------------------------------------------------------------------------------------
	entity UnidadDeControl is
		GENERIC(
			FPGA_CLK : INTEGER := 100_000_000
		);
		
		Port(
			-- Entradas
			clk, clr, exe 		: in std_logic; 								-- reloj, reset y ejecucion
			datos 				: in std_logic_vector(7 downto 0);		-- datos de entrada
			instru				: in std_logic_vector(4 downto 0);		-- instrucciones del switch
			bus_datos 			: inout std_logic_vector(7 downto 0);	-- bus de datos
			
			--
			-- Salidas
			--
			-- banderas de estado son: 
			-- Z = zero
			-- V = desborde por un resultado mas grande que el registro
			-- N = para un resultado negativo
			--
			flag			: out std_logic_vector(2 downto 0);			-- banderas de estado
			displays 	: out std_logic_vector(55 downto 0);		-- displays de 7 segmentos
			bus_dir		: out std_logic_vector(12 downto 0);		-- bus de direccciones
			bus_ctrl		: out std_logic_vector(4 downto 0);		   -- bus de control
			
			-- Salidas para el LCD
			ENCENDIDO	: out STD_LOGIC;									-- para prender LCD
			RS 			: out STD_LOGIC; 									-- command/data del LCD 
			RW 			: out STD_LOGIC; 									-- read/write del LCD 
			ENA 			: out STD_LOGIC; 									-- enable del LCD 
			DATA_LCD		: out STD_LOGIC_VECTOR (7 downto 0) 		-- bus de datos del LCD
		);
	end entity;
	
	---------------------------------------------------------------------------------------------------------------------
	--
	-- Inicio de la arquitectura
	--
	---------------------------------------------------------------------------------------------------------------------
	architecture principal of UnidadDeControl is
	
		-- Señales de apoyo para las instrucciones de la arquitectura
		signal reg_acum	:	std_logic_vector(15 downto 0)	:=	"0000000000000000";		-- registro acumulador
		signal reg_cont	:	unsigned(7 downto 0)				:=	"00000000";					-- registro contador de programa
		signal reg_ind		:	std_logic_vector(12 downto 0)	:=	"0000000000000";			-- registro indice
		signal aux			:	std_logic_vector(3 downto 0)	:=	"0000";						-- auxiliar para displays
		signal aux2			:	std_logic_vector(7 downto 0)	:=	"00000000";					-- auxiliar 2 para displays
		signal auxArray	:	std_logic_vector(7 downto 0)	:=	"00000000";					-- arreglo auxiliar para la operacion CMP
		signal bandera		: 	std_logic							:=	'1';							-- bandera para iniciar LCD
		
		-- Cantidad maxima de instrucciones para la LCD
		CONSTANT NUM_INSTRUCCIONES : INTEGER := 30; 	

		--------------------------------------------------------------------------------
		--------------------------------------------------------------------------------
		-- Señales de apoyo para la libreria del LCD												--
		component PROCESADOR_LCD_REVD is																--
																												--
		GENERIC(																								--
					FPGA_CLK : INTEGER := 50_000_000;												--
					NUM_INST : INTEGER := 1																--
		);																										--
																												--
		PORT( CLK 				 : IN  STD_LOGIC;														--
				VECTOR_MEM 		 : IN  STD_LOGIC_VECTOR(8  DOWNTO 0);							--
				C1A,C2A,C3A,C4A : IN  STD_LOGIC_VECTOR(39 DOWNTO 0);							--
				C5A,C6A,C7A,C8A : IN  STD_LOGIC_VECTOR(39 DOWNTO 0);							--
				RS 				 : OUT STD_LOGIC;														--
				RW 				 : OUT STD_LOGIC;														--
				ENA 				 : OUT STD_LOGIC;														--
				BD_LCD 			 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);			         	--
				DATA 				 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);							--
				DIR_MEM 			 : OUT INTEGER RANGE 0 TO NUM_INSTRUCCIONES;					--
				exe				 :	IN	 STD_LOGIC;														--
				clr				 :	IN  STD_LOGIC														--
			);																									--
																												--
		end component PROCESADOR_LCD_REVD;															--
																												--
		COMPONENT CARACTERES_ESPECIALES_REVD is													--
																												--
		PORT( C1,C2,C3,C4 : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);								--
				C5,C6,C7,C8 : OUT STD_LOGIC_VECTOR(39 DOWNTO 0)									--
			 );																								--
																												--
		end COMPONENT CARACTERES_ESPECIALES_REVD;													--
																												--
		CONSTANT CHAR1 : INTEGER := 1;																--
		CONSTANT CHAR2 : INTEGER := 2;																--
		CONSTANT CHAR3 : INTEGER := 3;																--
		CONSTANT CHAR4 : INTEGER := 4;																--
		CONSTANT CHAR5 : INTEGER := 5;																--
		CONSTANT CHAR6 : INTEGER := 6;																--
		CONSTANT CHAR7 : INTEGER := 7;																--
		CONSTANT CHAR8 : INTEGER := 8;																--
																												--
		type ram is array (0 to  NUM_INSTRUCCIONES) of std_logic_vector(8 downto 0); 	--
		signal INST : ram := (others => (others => '0'));										--
																												--
		signal blcd 			  : std_logic_vector(7 downto 0):= (others => '0');		--																										
		signal vector_mem 	  : STD_LOGIC_VECTOR(8  DOWNTO 0) := (others => '0');		--
		signal c1s,c2s,c3s,c4s : std_logic_vector(39 downto 0) := (others => '0');		--
		signal c5s,c6s,c7s,c8s : std_logic_vector(39 downto 0) := (others => '0'); 	--
		signal dir_mem 		  : integer range 0 to NUM_INSTRUCCIONES := 0;				--
		--------------------------------------------------------------------------------
		--------------------------------------------------------------------------------
		
	begin
	
		---------------------------------------------------------------
		---------------------------------------------------------------
		-- Componentes para el funcionamiento de la libreria del LCD --
																						 --
		u1: PROCESADOR_LCD_REVD													 --
		GENERIC map( FPGA_CLK => FPGA_CLK,									 --
						 NUM_INST => NUM_INSTRUCCIONES )						 --
																						 --
		PORT map( CLK,VECTOR_MEM,C1S,C2S,C3S,C4S,C5S,C6S,C7S,C8S,RS, --
					 RW,ENA,BLCD,DATA_LCD, DIR_MEM, exe, clr );			 --
																						 --
		U2 : CARACTERES_ESPECIALES_REVD 										 --
		PORT MAP( C1S,C2S,C3S,C4S,C5S,C6S,C7S,C8S );				 		 --
																						 --
		VECTOR_MEM <= INST(DIR_MEM);											 --
		---------------------------------------------------------------
		---------------------------------------------------------------
	
		-- Se enciende el LCD
		ENCENDIDO <= '1';
		
		---------------------------------------------------------------------------------------------------------------------
		--
		-- Proceso para mostrar en todo momento los cambios en los displays
		--
		---------------------------------------------------------------------------------------------------------------------
		process(clk, clr)
		begin
			
			if(clk'event and clk = '1') then
			
				-- Mostrando el contador del programa
				aux2 <= std_logic_vector(reg_cont);
				bcd_conv(aux2(3 downto 0), displays(48 downto 42));
				bcd_conv(aux2(7 downto 4), displays(55 downto 49));
				
				-- Mostrando el indice del programa
				bcd_conv(reg_ind(3 downto 0), displays(34 downto 28));
				bcd_conv(reg_ind(7 downto 4), displays(41 downto 35));
				
				-- Mostrando el numero de instruccion
				aux <= "000" & instru(4);
				bcd_conv(instru(3 downto 0), displays(20 downto 14));
				bcd_conv(aux, displays(27 downto 21));
				
				-- Mostrando parte baja del acumulador
				bcd_conv(reg_acum(3 downto 0), displays(6 downto 0));
				bcd_conv(reg_acum(7 downto 4), displays(13 downto 7));
			
			end if;
			
		end process;
		
		---------------------------------------------------------------------------------------------------------------------
		--
		-- Proceso para la ejecucion de las 22 instrucciones
		--
		-- Incluye actualizacion del LCD en este mismo process
		--
		---------------------------------------------------------------------------------------------------------------------
		process(clk, clr, exe, datos, instru, bandera)
		begin
			
			if clr = '0' then
				
				-- Reiniciando variables
				reg_acum <= "0000000000000000";
				reg_cont <= "00000000";
				flag <= "000";
				reg_ind <= "0000000000000";
				bus_dir <= "0000000000000";
				bus_ctrl <= "00000";
				
				-- Activando la bandera para reiniciar LCD
				bandera <= '1';
			
			elsif(clk'event and clk = '1') then
				
				if bandera = '1' then
			
					-- Quitando la bandera de apoyo
					bandera <= '0';
				
					------------------------------------------------------------------------------------------------------------
					-- LCD Caso por default
					-- Es para cuando inicia el programa
					--
					-- Muestra lo siguiente:
					--
					--	Esperando una
					-- instruccion...
					------------------------------------------------------------------------------------------------------------
					INST(0) <= LCD_INI("00");
					INST(1) <= LIMPIAR_PANTALLA('1');
					INST(2) <= CHAR(ME);
					INST(3) <= CHAR(S);
					INST(4) <= CHAR(P);
					INST(5) <= CHAR(E);
					INST(6) <= CHAR(R);
					INST(7) <= CHAR(A);
					INST(8) <= CHAR(N);
					INST(9) <= CHAR(D);
					INST(10) <= CHAR(O);
					-- ESPACIO EN BLANCO
					INST(11) <= CHAR_ASCII(x"20");
					INST(12) <= CHAR(U);
					INST(13) <= CHAR(N);
					INST(14) <= CHAR(A);
					
					-- Segunda fila
					INST(15) <= POS(2,1);
					INST(16) <= CHAR(I);
					INST(17) <= CHAR(N);
					INST(18) <= CHAR(S);
					INST(19) <= CHAR(T);
					INST(20) <= CHAR(R);
					INST(21) <= CHAR(U);
					INST(22) <= CHAR(C);
					INST(23) <= CHAR(C);
					INST(24) <= CHAR(I);
					INST(25) <= CHAR(O);
					INST(26) <= CHAR(N);
					-- PUNTO EN ASCII
					INST(27) <= CHAR_ASCII(x"2E");
					INST(28) <= CHAR_ASCII(x"2E");
					INST(29) <= CHAR_ASCII(x"2E");
					INST(30) <= CODIGO_FIN(1);
				
				elsif exe = '0' then
					
					case instru is
					
						-------------------------------------------------------------------------------------------------------
						-- Operacion 1 - MOV AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "00000" =>
						
							reg_cont <= reg_cont + 1;
							reg_acum(7 downto 0) <= datos;
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MM);
							INST(3) <= CHAR(MO);
							INST(4) <= CHAR(MV);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(0);
							INST(14) <= INT_NUM(0);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(16) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
							
						-------------------------------------------------------------------------------------------------------
						-- Operacion 2 - MOV IX AX - cargando al indice
						-------------------------------------------------------------------------------------------------------
						when "00001" =>
						
							reg_cont <= reg_cont + 1;
							reg_ind(7 downto 0) <= datos;
							
							bus_ctrl(0) <= '0';     -- Seleccionando del byte bajo 
							bus_ctrl(1) <= '1';     -- Seleccionando del byte alto
							bus_ctrl(2) <= '1';     -- Output Enable
							bus_ctrl(3) <= '0';     -- Escritura activada
							bus_ctrl(4) <= '1';     -- Chip enable de la RAM activado
			
							bus_dir(10) <= '0';     								-- Al0 del bus de direccion en 1 para pre-carga
							bus_dir(12 downto 4) <= "000000000";   			-- Direcciones no usadas se ponen en 0
							bus_dir(7 downto 0) <= reg_ind(7 downto 0);
		
							bus_datos <= reg_acum(7 downto 0);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MM);
							INST(3) <= CHAR(MO);
							INST(4) <= CHAR(MV);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MI);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							INST(9) <= CHAR(MA);
							INST(10) <= CHAR(MX);
							
							-- Segunda fila
							INST(11) <= POS(2,1);
							INST(12) <= INT_NUM(0);
							INST(13) <= INT_NUM(1);
							-- ESPACIO EN BLANCO
							INST(14) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(15) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(15) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(15) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(15) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(15) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(15) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(15) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(15) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(15) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(15) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(15) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(15) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(15) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(15) <= CHAR_ASCII(x"45"); -- E
								when others => INST(15) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(16) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(17) <= CHAR(H);
							INST(18) <= CODIGO_FIN(1);
							
						-------------------------------------------------------------------------------------------------------
						-- Operacion 3 - MOV AX IX - cargando al acumulador
						-------------------------------------------------------------------------------------------------------
						when "00010" =>
						
							reg_cont <= reg_cont + 1;
							reg_ind(7 downto 0) <= datos;
							
							bus_ctrl(0) <= '0';     -- Seleccionando del byte bajo 
							bus_ctrl(1) <= '1';     -- Seleccionando del byte alto
							bus_ctrl(2) <= '1';     -- Output Enable
							bus_ctrl(3) <= '1';     -- Escritura activada
							bus_ctrl(4) <= '1';     -- Chip enable de la RAM activado
						   
							
							bus_dir(10) <= '0';
							bus_dir(12 downto 4) <= "000000000";   			-- Direcciones no usadas se ponen en 0
							bus_dir(7 downto 0) <= reg_ind(7 downto 0);     -- Direccion a leer
							
							reg_acum <= "00000000" & bus_datos;
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MM);
							INST(3) <= CHAR(MO);
							INST(4) <= CHAR(MV);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							INST(9) <= CHAR(MI);
							INST(10) <= CHAR(MX);
							
							-- Segunda fila
							INST(11) <= POS(2,1);
							INST(12) <= INT_NUM(0);
							INST(13) <= INT_NUM(2);
							-- ESPACIO EN BLANCO
							INST(14) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(15) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(15) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(15) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(15) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(15) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(15) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(15) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(15) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(15) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(15) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(15) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(15) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(15) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(15) <= CHAR_ASCII(x"45"); -- E
								when others => INST(15) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(16) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(17) <= CHAR(H);
							INST(18) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 4 - CLA
						-------------------------------------------------------------------------------------------------------
						when "00011" =>
						
							reg_cont <= reg_cont + 1;
							reg_acum <= "0000000000000000";
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MC);
							INST(3) <= CHAR(ML);
							INST(4) <= CHAR(MA);
							
							-- Segunda fila
							INST(11) <= POS(2,1);
							INST(12) <= INT_NUM(0);
							INST(13) <= INT_NUM(3);
							-- ESPACIO EN BLANCO
							INST(14) <= CHAR_ASCII(x"20");
							INST(15) <= INT_NUM(0);
							INST(16) <= INT_NUM(0);
							INST(17) <= CHAR(H);
							INST(18) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 5 - SET AX
						-------------------------------------------------------------------------------------------------------
						when "00100" =>
						
							reg_cont <= reg_cont + 1;
							reg_acum <= "0000000011111111";
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							-- Letra S mayuscula
							INST(2) <= CHAR_ASCII(x"53");
							INST(3) <= CHAR(ME);
							INST(4) <= CHAR(MT);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							
							-- Segunda fila
							INST(8) <= POS(2,1);
							INST(9) <= INT_NUM(0);
							INST(10) <= INT_NUM(4);
							-- ESPACIO EN BLANCO
							INST(11) <= CHAR_ASCII(x"20");
							INST(12) <= CHAR(MF);
							INST(13) <= CHAR(MF);
							INST(14) <= CHAR(H);
							INST(15) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 6 - ADD AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "00101" =>
						
							reg_cont <= reg_cont + 1;
							ADD(reg_acum, datos, flag);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MA);
							INST(3) <= CHAR(MD);
							INST(4) <= CHAR(MD);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(0);
							INST(14) <= INT_NUM(5);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(16) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(17) <= CHAR(H);
							INST(18) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 7 - SUB AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "00110" =>
						
							reg_cont <= reg_cont + 1;
							SUB(reg_acum, datos, flag);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							-- Letra S mayuscula
							INST(2) <= CHAR_ASCII(x"53");
							INST(3) <= CHAR(MU);
							INST(4) <= CHAR(MB);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(0);
							INST(14) <= INT_NUM(6);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 8 - MUL AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "00111" =>
						
							reg_cont <= reg_cont + 1;
							MUL(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MM);
							INST(3) <= CHAR(MU);
							INST(4) <= CHAR(ML);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(0);
							INST(14) <= INT_NUM(7);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 9 - DIV AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "01000" =>
						
							reg_cont <= reg_cont + 1;
							DIV(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MD);
							INST(3) <= CHAR(MI);
							INST(4) <= CHAR(MV);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(0);
							INST(14) <= INT_NUM(8);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 10 - INC AX
						-------------------------------------------------------------------------------------------------------
						when "01001" =>
						
							reg_cont <= reg_cont + 1;
							INC(reg_acum, flag);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MI);
							INST(3) <= CHAR(MN);
							INST(4) <= CHAR(MC);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							
							-- Segunda fila
							INST(8) <= POS(2,1);
							INST(9) <= INT_NUM(0);
							INST(10) <= INT_NUM(9);
							-- ESPACIO EN BLANCO
							INST(11) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(12) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(12) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(12) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(12) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(12) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(12) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(12) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(12) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(12) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(12) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(12) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(12) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(12) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(12) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(12) <= CHAR_ASCII(x"45"); -- E
								when others => INST(12) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(13) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(13) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(13) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(13) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(13) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(13) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(13) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(13) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(13) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(13) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(13) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(13) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(13) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(13) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(13) <= CHAR_ASCII(x"45"); -- E
								when others => INST(13) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(14) <= CHAR(H);
							INST(15) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 11 - DEC AX
						-------------------------------------------------------------------------------------------------------
						when "01010" =>
						
							reg_cont <= reg_cont + 1;
							DEC(reg_acum, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MD);
							INST(3) <= CHAR(ME);
							INST(4) <= CHAR(MC);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							
							-- Segunda fila
							INST(8) <= POS(2,1);
							INST(9) <= INT_NUM(1);
							INST(10) <= INT_NUM(0);
							-- ESPACIO EN BLANCO
							INST(11) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(12) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(12) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(12) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(12) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(12) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(12) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(12) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(12) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(12) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(12) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(12) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(12) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(12) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(12) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(12) <= CHAR_ASCII(x"45"); -- E
								when others => INST(12) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(13) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(13) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(13) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(13) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(13) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(13) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(13) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(13) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(13) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(13) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(13) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(13) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(13) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(13) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(13) <= CHAR_ASCII(x"45"); -- E
								when others => INST(13) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(14) <= CHAR(H);
							INST(15) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 12 - CMP AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "01011" =>
						
							reg_cont <= reg_cont + 1;
							CMP(reg_acum, datos, flag, auxArray);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MC);
							INST(3) <= CHAR(MM);
							INST(4) <= CHAR(MP);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(1);
							INST(14) <= INT_NUM(1);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion del resultado a hexadecimal
							-- Primer nibble
							case auxArray(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion del resultado a hexadecimal
							-- Segundo nibble
							case auxArray(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
							
							-- Reiniciando el valor del arreglo auxiliar
							auxArray <= "00000000";
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 13 - AND AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "01100" =>
						
							reg_cont <= reg_cont + 1;
							OPAND(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MA);
							INST(3) <= CHAR(MN);
							INST(4) <= CHAR(MD);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(1);
							INST(14) <= INT_NUM(2);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							--- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 14 - OR AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "01101" =>
						
							reg_cont <= reg_cont + 1;
							OPOR(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MO);
							INST(3) <= CHAR(MR);
							-- ESPACIO EN BLANCO
							INST(4) <= CHAR_ASCII(x"20");
							INST(5) <= CHAR(MA);
							INST(6) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(7) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(8) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(8) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(8) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(8) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(8) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(8) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(8) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(8) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(8) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(8) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(8) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(8) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(8) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(8) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(8) <= CHAR_ASCII(x"45"); -- E
								when others => INST(8) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(10) <= CHAR(H);
							
							-- Segunda fila
							INST(11) <= POS(2,1);
							INST(12) <= INT_NUM(1);
							INST(13) <= INT_NUM(3);
							-- ESPACIO EN BLANCO
							INST(14) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(15) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(15) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(15) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(15) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(15) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(15) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(15) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(15) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(15) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(15) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(15) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(15) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(15) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(15) <= CHAR_ASCII(x"45"); -- E
								when others => INST(15) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(16) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(17) <= CHAR(H);
							INST(18) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 15 - XOR AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "01110" =>
						
							reg_cont <= reg_cont + 1;
							OPXOR(reg_acum, datos, flag);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MX);
							INST(3) <= CHAR(MO);
							INST(4) <= CHAR(MR);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(1);
							INST(14) <= INT_NUM(4);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 16 - NOT AX
						-------------------------------------------------------------------------------------------------------
						when "01111" =>
						
							reg_cont <= reg_cont + 1;
							OPNOT(reg_acum, flag);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MN);
							INST(3) <= CHAR(MO);
							INST(4) <= CHAR(MT);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							
							-- Segunda fila
							INST(8) <= POS(2,1);
							INST(9) <= INT_NUM(1);
							INST(10) <= INT_NUM(5);
							-- ESPACIO EN BLANCO
							INST(11) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(12) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(12) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(12) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(12) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(12) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(12) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(12) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(12) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(12) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(12) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(12) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(12) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(12) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(12) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(12) <= CHAR_ASCII(x"45"); -- E
								when others => INST(12) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(13) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(13) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(13) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(13) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(13) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(13) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(13) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(13) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(13) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(13) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(13) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(13) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(13) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(13) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(13) <= CHAR_ASCII(x"45"); -- E
								when others => INST(13) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(14) <= CHAR(H);
							INST(15) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 17 - LSL AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "10000" =>
						
							reg_cont <= reg_cont + 1;
							LSL(reg_acum, datos, flag);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(ML);
							-- Letra S mayuscula
							INST(3) <= CHAR_ASCII(x"53");
							INST(4) <= CHAR(ML);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(1);
							INST(14) <= INT_NUM(6);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 18 - LSR AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "10001" =>
						
							reg_cont <= reg_cont + 1;
							LSR(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(ML);
							-- Letra S mayuscula
							INST(3) <= CHAR_ASCII(x"53");
							INST(4) <= CHAR(MR);
							-- ESPACIO EN BLANCO
							INST(5) <= CHAR_ASCII(x"20");
							INST(6) <= CHAR(MA);
							INST(7) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(8) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(11) <= CHAR(H);
							
							-- Segunda fila
							INST(12) <= POS(2,1);
							INST(13) <= INT_NUM(1);
							INST(14) <= INT_NUM(7);
							-- ESPACIO EN BLANCO
							INST(15) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(18) <= CHAR(H);
							INST(19) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 19 - RL AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "10010" =>
						
							reg_cont <= reg_cont + 1;
							RL(reg_acum, datos, flag);
						
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MR);
							INST(3) <= CHAR(ML);
							-- ESPACIO EN BLANCO
							INST(4) <= CHAR_ASCII(x"20");
							INST(5) <= CHAR(MA);
							INST(6) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(7) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(8) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(8) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(8) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(8) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(8) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(8) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(8) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(8) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(8) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(8) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(8) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(8) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(8) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(8) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(8) <= CHAR_ASCII(x"45"); -- E
								when others => INST(8) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(10) <= CHAR(H);
							
							-- Segunda fila
							INST(11) <= POS(2,1);
							INST(12) <= INT_NUM(1);
							INST(13) <= INT_NUM(8);
							-- ESPACIO EN BLANCO
							INST(14) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(15) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(15) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(15) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(15) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(15) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(15) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(15) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(15) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(15) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(15) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(15) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(15) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(15) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(15) <= CHAR_ASCII(x"45"); -- E
								when others => INST(15) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(16) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(17) <= CHAR(H);
							INST(18) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 20 - RR AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "10011" =>
						
							reg_cont <= reg_cont + 1;
							RR(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MR);
							INST(3) <= CHAR(MR);
							-- ESPACIO EN BLANCO
							INST(4) <= CHAR_ASCII(x"20");
							INST(5) <= CHAR(MA);
							INST(6) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(7) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(8) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(8) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(8) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(8) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(8) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(8) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(8) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(8) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(8) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(8) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(8) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(8) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(8) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(8) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(8) <= CHAR_ASCII(x"45"); -- E
								when others => INST(8) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(9) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(9) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(9) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(9) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(9) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(9) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(9) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(9) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(9) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(9) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(9) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(9) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(9) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(9) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(9) <= CHAR_ASCII(x"45"); -- E
								when others => INST(9) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(10) <= CHAR(H);
							
							-- Segunda fila
							INST(11) <= POS(2,1);
							INST(12) <= INT_NUM(1);
							INST(13) <= INT_NUM(9);
							-- ESPACIO EN BLANCO
							INST(14) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(15) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(15) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(15) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(15) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(15) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(15) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(15) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(15) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(15) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(15) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(15) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(15) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(15) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(15) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(15) <= CHAR_ASCII(x"45"); -- E
								when others => INST(15) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(16) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(16) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(16) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(16) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(16) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(16) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(16) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(16) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(16) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(16) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(16) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(16) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(16) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(16) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(16) <= CHAR_ASCII(x"45"); -- E
								when others => INST(16) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(17) <= CHAR(H);
							INST(18) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 21 - BCLR AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "10100" =>
						
							reg_cont <= reg_cont + 1;
							BCLR(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MB);
							INST(3) <= CHAR(MC);
							INST(4) <= CHAR(ML);
							INST(5) <= CHAR(MR);
							-- ESPACIO EN BLANCO
							INST(6) <= CHAR_ASCII(x"20");
							INST(7) <= CHAR(MA);
							INST(8) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(9) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(11) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(11) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(11) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(11) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(11) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(11) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(11) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(11) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(11) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(11) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(11) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(11) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(11) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(11) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(11) <= CHAR_ASCII(x"45"); -- E
								when others => INST(11) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(12) <= CHAR(H);
							
							-- Segunda fila
							INST(13) <= POS(2,1);
							INST(14) <= INT_NUM(2);
							INST(15) <= INT_NUM(0);
							-- ESPACIO EN BLANCO
							INST(16) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(18) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(18) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(18) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(18) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(18) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(18) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(18) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(18) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(18) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(18) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(18) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(18) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(18) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(18) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(18) <= CHAR_ASCII(x"45"); -- E
								when others => INST(18) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(19) <= CHAR(H);
							INST(20) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- Operacion 22 - BSET AX DATOS
						-------------------------------------------------------------------------------------------------------
						when "10101" =>
						
							reg_cont <= reg_cont + 1;
							BSET(reg_acum, datos, flag);
							
							--
							-- Instrucciones de mostrado en LCD
							--
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(MB);
							-- Letra S mayuscula
							INST(3) <= CHAR_ASCII(x"53");
							INST(4) <= CHAR(ME);
							INST(5) <= CHAR(MT);
							-- ESPACIO EN BLANCO
							INST(6) <= CHAR_ASCII(x"20");
							INST(7) <= CHAR(MA);
							INST(8) <= CHAR(MX);
							-- ESPACIO EN BLANCO
							INST(9) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Primer nibble
							case datos(7 downto 4) is
							
								when "0000" => INST(10) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(10) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(10) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(10) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(10) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(10) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(10) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(10) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(10) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(10) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(10) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(10) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(10) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(10) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(10) <= CHAR_ASCII(x"45"); -- E
								when others => INST(10) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la entrada del usuario a hexadecimal
							-- Segundo nibble
							case datos(3 downto 0) is
							
								when "0000" => INST(11) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(11) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(11) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(11) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(11) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(11) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(11) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(11) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(11) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(11) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(11) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(11) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(11) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(11) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(11) <= CHAR_ASCII(x"45"); -- E
								when others => INST(11) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(12) <= CHAR(H);
							
							-- Segunda fila
							INST(13) <= POS(2,1);
							INST(14) <= INT_NUM(2);
							INST(15) <= INT_NUM(1);
							-- ESPACIO EN BLANCO
							INST(16) <= CHAR_ASCII(x"20");
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Primer nibble
							case reg_acum(7 downto 4) is
							
								when "0000" => INST(17) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(17) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(17) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(17) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(17) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(17) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(17) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(17) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(17) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(17) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(17) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(17) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(17) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(17) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(17) <= CHAR_ASCII(x"45"); -- E
								when others => INST(17) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							-- Case para conversion de la parte baja del acumulador a hexadecimal
							-- Segundo nibble
							case reg_acum(3 downto 0) is
							
								when "0000" => INST(18) <= CHAR_ASCII(x"30"); -- 0
								when "0001" => INST(18) <= CHAR_ASCII(x"31"); -- 1
								when "0010" => INST(18) <= CHAR_ASCII(x"32"); -- 2
								when "0011" => INST(18) <= CHAR_ASCII(x"33"); -- 3
								when "0100" => INST(18) <= CHAR_ASCII(x"34"); -- 4
								when "0101" => INST(18) <= CHAR_ASCII(x"35"); -- 5
								when "0110" => INST(18) <= CHAR_ASCII(x"36"); -- 6
								when "0111" => INST(18) <= CHAR_ASCII(x"37"); -- 7
								when "1000" => INST(18) <= CHAR_ASCII(x"38"); -- 8
								when "1001" => INST(18) <= CHAR_ASCII(x"39"); -- 9
								when "1010" => INST(18) <= CHAR_ASCII(x"41"); -- A
								when "1011" => INST(18) <= CHAR_ASCII(x"42"); -- B
								when "1100" => INST(18) <= CHAR_ASCII(x"43"); -- C
								when "1101" => INST(18) <= CHAR_ASCII(x"44"); -- D
								when "1110" => INST(18) <= CHAR_ASCII(x"45"); -- E
								when others => INST(18) <= CHAR_ASCII(x"46"); -- F
							
							end case;
							
							INST(19) <= CHAR(H);
							INST(20) <= CODIGO_FIN(1);
						
						-------------------------------------------------------------------------------------------------------
						-- LCD en otro caso
						-- Cuando se selecciona una instruccion no existente
						--
						-- Muestra lo siguiente:
						--
						--	Error :c
						-- No es operacion
						-------------------------------------------------------------------------------------------------------
						when others =>
						
							INST(0) <= LCD_INI("00");
							INST(1) <= LIMPIAR_PANTALLA('1');
							INST(2) <= CHAR(ME);
							INST(3) <= CHAR(R);
							INST(4) <= CHAR(R);
							INST(5) <= CHAR(O);
							INST(6) <= CHAR(R);
							-- ESPACIO EN BLANCO
							INST(7) <= CHAR_ASCII(x"20");
							-- dos puntos
							INST(8) <= CHAR_ASCII(x"3A");
							INST(9) <= CHAR(MC);
							
							-- Segunda fila
							INST(10) <= POS(2,1);
							INST(11) <= CHAR(MN);
							INST(12) <= CHAR(O);
							-- ESPACIO EN BLANCO
							INST(13) <= CHAR_ASCII(x"20");
							INST(14) <= CHAR(E);
							INST(15) <= CHAR(S);
							-- ESPACIO EN BLANCO
							INST(16) <= CHAR_ASCII(x"20");
							INST(17) <= CHAR(O);
							INST(18) <= CHAR(P);
							INST(19) <= CHAR(E);
							INST(20) <= CHAR(R);
							INST(21) <= CHAR(A);
							INST(22) <= CHAR(C);
							INST(23) <= CHAR(I);
							INST(24) <= CHAR(O);
							INST(25) <= CHAR(N);
							INST(26) <= CODIGO_FIN(1);
					
					end case;
				
				end if;
				
			end if;
		
		end process;
		
	end architecture;
	
	
	
	