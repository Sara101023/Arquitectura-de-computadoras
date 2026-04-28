
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
	-- La mayoria de las instrucciones se sacaron de la siguientes paginas:
	-- http://www.fdi.ucm.es/profesor/mendias/512/docs/tema5.pdf
	-- http://cv.uoc.edu/annotation/8255a8c320f60c2bfd6c9f2ce11b2e7f/619469/PID_00218277/PID_00218277.html
	-- https://www.exabyteinformatica.com/uoc/Informatica/Estructura_de_computadores/Estructura_de_computadores_(Modulo_2).pdf
	--
	
	---------------------------------------------------------------------------------------------------------------------
	--
	-- Codigo de la ALU
	-- Esta ALU tiene 20 operaciones
	-- de las cuales se utilizan 17 en la unidad de control
	--
	-- Operaciones aritmeticas:
	--
	-- 1		ADD				AX,d		Suma al acumulador el valor de "d"
	-- 2		SUB				AX,d		Resta al acumulador el valor de "d"
	-- 3		MUL				AX,d		Multiplica por el acumulador el valor de "d"
	-- 4		DIV				AX,d		Divide el acumulador entre el valor de "d"
	-- 5		INC				AX			Incrementa el valor del acumulador en 1 
	-- 6		DEC				AX			Decrementa el valor del acumulador en 1
	-- 7		CMP				AX,d		Compara el valor del acumulador con el de "d", restando y lo muestra sin guardarlo
	--
	-- Operaciones Logicas:
	--
	-- 8		AND				AX,d		
	-- 9		OR					AX,d
	-- 10		XOR				AX,d
	-- 11		NOT				AX
	-- 12		LSL				AX,n		Desplaza de forma lógica el valor del acumulador "n" bits a la izquierda
	-- 13		LSR				AX,n		Desplaza de forma lógica el valor del acumulador "n" bits a la derecha
	-- 14		RL					AX,n		Rota de forma lógica "n" bits hacia la izquierda el valor del acumulador 
	-- 15		RR					AX,n		Rota de forma lógica "n" bits hacia la derecha el valor del acumulador 
	-- 16		BCLR 				AX,n		Coloca el bit "n" del acumulador en 0
	-- 17		BSET 				AX,n		Coloca el bit "n" del acumulador en 1
	--
	-- 18-20 NAND, NOR, XNOR
	--
	---------------------------------------------------------------------------------------------------------------------
	
	-- Declaración de las bibliotecas
	library ieee;
	use ieee.numeric_std.all;	  -- Permite el cast entre tipos de datos
	use ieee.std_logic_1164.all;    
	use ieee.std_logic_signed.all;  -- Permite operaciones con signo con datos tipo STD_LOGIC_VECTOR.
	
	---------------------------------------------------------------------------------------------------------------------
	--
	-- Declaración del paquete
	--
	---------------------------------------------------------------------------------------------------------------------
	package ALU_UC is 
	
		signal aux : std_logic_vector(7 downto 0) := "00000000";
	
		--
		-- Declaracion de operaciones aritmeticas
		--
		procedure ADD(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure SUB(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure MUL(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure DIV(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
						  
		procedure INC(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure DEC(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure CMP(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0);
						  signal aux: in std_logic_vector(7 downto 0));
		
		--
		-- Declaracion de operaciones logicas
		--
		procedure OPAND(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure OPOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure OPXOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure OPNOT(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure LSL(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure LSR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure RL(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure RR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure BCLR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure BSET(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		--
		-- Otras no usadas
		--
		procedure OPNAND(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure OPNOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
		procedure OPXNOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0));
		
								  
	end package;

	---------------------------------------------------------------------------------------------------------------------
	--
	-- Cuerpo o funciones del paquete
	--
	---------------------------------------------------------------------------------------------------------------------
	package body ALU_UC is 
	
		---------------------------------------------------------------------------------------------------------------------
		--
		-- Operaciones aritmeticas
		--
		---------------------------------------------------------------------------------------------------------------------
	
		--
		-- Operacion suma aritmetica
		--
		procedure ADD(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando suma
				acumulador <= std_logic_vector(signed(acumulador) + signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
				
				-- comprobando si el resultado de la operacion fue un desborde
				if acumulador > "0000000011111111" then
					acumulador <= "0000000000000000";
					flag(1) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion resta aritmetica
		--
		procedure SUB(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- comprobando si el resultado fue negativo
				if acumulador < datos then
					flag(2) <= '1';
				end if;
				
				-- realizando resta
				acumulador <= std_logic_vector(signed(acumulador) - signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
				
				-- comprobando si el resultado de la operacion fue un desborde
				if acumulador > "0000000011111111" then
					acumulador <= "0000000000000000";
					flag(1) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion multiplicacion aritmetica
		--
		procedure MUL(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando multiplicacion
				acumulador <= std_logic_vector(signed(acumulador(7 downto 0)) * signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
				
				-- comprobando si el resultado de la operacion fue un desborde
				if acumulador > "0000000011111111" then
					acumulador <= "0000000000000000";
					flag(1) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion division aritmetica
		--
		procedure DIV(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando multiplicacion
				acumulador <= std_logic_vector(signed(acumulador) / signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion incremento aritmetica
		--
		procedure INC(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando incremento
				acumulador <= std_logic_vector(unsigned(acumulador) + 1);
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
				
				-- comprobando si el resultado de la operacion fue un desborde
				if acumulador > "0000000011111111" then
					acumulador <= "0000000000000000";
					flag(1) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion decremento aritmetica
		--
		procedure DEC(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- comprobando si el resultado fue negativo
				if acumulador = "0000000000000000" then
					flag(2) <= '1';
				end if;
				
				-- realizando decremento
				acumulador <= std_logic_vector(unsigned(acumulador) - 1);
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
				
				-- comprobando si el resultado de la operacion fue un desborde
				if acumulador > "0000000011111111" then
					acumulador <= "0000000000000000";
					flag(1) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion comparacion aritmetica
		--
		procedure CMP(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0);
						  signal aux:	inout std_logic_vector(7 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- comprobando si el resultado fue negativo
				if acumulador < datos then
					flag(2) <= '1';
				end if;
				
				-- realizando comparacion
				aux <= std_logic_vector(signed(acumulador(7 downto 0)) - signed(datos));
				
				-- comprobando si el resultado fue 0
				if aux = "00000000" then
					flag(0) <= '1';
				end if;
				
				-- comprobando si el resultado de la operacion fue un desborde
				if aux > "11111111" then
					flag(1) <= '1';
				end if;
		end procedure;
		
		---------------------------------------------------------------------------------------------------------------------
		--
		-- Operaciones logicas
		--
		---------------------------------------------------------------------------------------------------------------------
		
		--
		-- Operacion AND logica
		--
		procedure OPAND(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion AND
				acumulador <= acumulador(15 downto 8) & std_logic_vector(signed(acumulador(7 downto 0)) AND signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion OR logica
		--
		procedure OPOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion OR
				acumulador <= acumulador(15 downto 8) & std_logic_vector(signed(acumulador(7 downto 0)) OR signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion XOR logica
		--
		procedure OPXOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion XOR
				acumulador <= acumulador(15 downto 8) & std_logic_vector(signed(acumulador(7 downto 0)) XOR signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion NOT logica
		--
		procedure OPNOT(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion NOT
				acumulador <= acumulador(15 downto 8) & std_logic_vector(NOT signed(acumulador(7 downto 0)));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion LSL logica
		--
		procedure LSL(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- reiniciando aux
				aux <= "00000000";
				
				-- realizando operacion LSL
				for x in 1 to 300 loop
					aux <= std_logic_vector(unsigned(aux) + 1);
				
					if aux < datos then
						acumulador <= acumulador(15 downto 8) & acumulador(6 downto 0) & '0';
					else
						exit;
					end if;
				end loop;
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion LSR logica
		--
		procedure LSR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- reiniciando aux
				aux <= "00000000";
				
				-- realizando operacion LSR
				for x in 1 to 300 loop
					aux <= std_logic_vector(unsigned(aux) + 1);
				
					if aux < datos then
						acumulador <= acumulador(15 downto 8) & '0' & acumulador(7 downto 1);
					else
						exit;
					end if;
				end loop;
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion RL logica
		--
		procedure RL(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- reiniciando aux
				aux <= "00000000";
				
				-- realizando operacion RL
				for x in 1 to 300 loop
					aux <= std_logic_vector(unsigned(aux) + 1);
				
					if aux < datos then
						acumulador <= acumulador(15 downto 8) & acumulador(6 downto 0) & acumulador(7);
					else
						exit;
					end if;
				end loop;
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion RR logica
		--
		procedure RR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- reiniciando aux
				aux <= "00000000";
				
				-- realizando operacion RR
				for x in 1 to 300 loop
					aux <= std_logic_vector(unsigned(aux) + 1);
				
					if aux < datos then
						acumulador <= acumulador(15 downto 8) & acumulador(0) & acumulador(7 downto 1);
					else
						exit;
					end if;
				end loop;
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion BCLR logica
		--
		procedure BCLR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion BCLR
				acumulador(to_integer(unsigned(datos))) <= '0';
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion BSET logica
		--
		procedure BSET(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion BSET
				acumulador(to_integer(unsigned(datos))) <= '1';
				
				-- comprobando si el resultado de la operacion fue un desborde
				if acumulador > "0000000011111111" then
					acumulador <= "0000000000000000";
					flag(1) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion NAND logica
		--
		procedure OPNAND(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion NAND
				acumulador <= acumulador(15 downto 8) & std_logic_vector(signed(acumulador(7 downto 0)) NAND signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion NOR logica
		--
		procedure OPNOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion NOR
				acumulador <= acumulador(15 downto 8) & std_logic_vector(signed(acumulador(7 downto 0)) NOR signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
		--
		-- Operacion XNOR logica
		--
		procedure OPXNOR(signal acumulador: inout std_logic_vector(15 downto 0);
						  signal datos: in std_logic_vector(7 downto 0);
						  signal flag: out std_logic_vector(2 downto 0)) is
		begin
				-- reiniciando las banderas en caso de que estuvieran encendidas
				flag <= "000";
				
				-- realizando operacion XNOR
				acumulador <= acumulador(15 downto 8) & std_logic_vector(signed(acumulador(7 downto 0)) XNOR signed(datos));
				
				-- comprobando si el resultado fue 0
				if acumulador = "0000000000000000" then
					flag(0) <= '1';
				end if;
		end procedure;
		
	end ALU_UC;	
						
						
						
						