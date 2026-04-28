
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
	
	---------------------------------------------------------------------------------------------------------------------
	--
	-- Codigo para manejo de los displays
	-- Este codigo simplemente convierte los datos a 7 segmentos
	--
	---------------------------------------------------------------------------------------------------------------------

	-- Declaración de las bibliotecas
	Library ieee;
	use ieee.std_logic_1164.all;

	---------------------------------------------------------------------------------------------------------------------
	--
	-- Declaración del paquete
	--
	---------------------------------------------------------------------------------------------------------------------
	package bcd_7seg is 

		-- Definiendo las conversiones a 7 segmentos
		constant zero  : std_logic_vector(6 downto 0)  := "1000000";	-- 0 en 7 segmentos
		constant uno   : std_logic_vector(6 downto 0)  := "1111001";	-- 1 en 7 segmentos
		constant dos   : std_logic_vector(6 downto 0)  := "0100100";	-- 2 en 7 segmentos
		constant tres  : std_logic_vector(6 downto 0)  := "0110000";	-- 3 en 7 segmentos
		constant quat  : std_logic_vector(6 downto 0)  := "0011001";	-- 4 en 7 segmentos
		constant qint  : std_logic_vector(6 downto 0)  := "0010010";	-- 5 en 7 segmentos
		constant sixt  : std_logic_vector(6 downto 0)  := "0000010";	-- 6 en 7 segmentos
		constant sept  : std_logic_vector(6 downto 0)  := "1111000";	-- 7 en 7 segmentos
		constant octo  : std_logic_vector(6 downto 0)  := "0000000";	-- 8 en 7 segmentos
		constant nono  : std_logic_vector(6 downto 0)  := "0010000";	-- 9 en 7 segmentos
		constant alph  : std_logic_vector(6 downto 0)  := "0001000";	-- A en 7 segmentos
		constant beta  : std_logic_vector(6 downto 0)  := "0000011";	-- B en 7 segmentos
		constant cobi  : std_logic_vector(6 downto 0)  := "1000110";	-- C en 7 segmentos
		constant delt  : std_logic_vector(6 downto 0)  := "0100001";	-- D en 7 segmentos
		constant eco   : std_logic_vector(6 downto 0)  := "0000110";	-- E en 7 segmentos
		constant fox	: std_logic_vector(6 downto 0)  := "0001110";	-- F en 7 segmentos
		
		-- Declarando el procedimiento a usar
		procedure bcd_conv (signal bcd : in std_logic_vector (3 downto 0);
								  signal D : out std_logic_vector (6 downto 0) );
								  
	end bcd_7seg;

	---------------------------------------------------------------------------------------------------------------------
	--
	-- Cuerpo o funciones del paquete
	--
	---------------------------------------------------------------------------------------------------------------------
	package body bcd_7seg is 
	
		-- Iniciando el procedimiento
		procedure bcd_conv (signal BCD : in std_logic_vector (3 downto 0);
								  signal D : out std_logic_vector (6 downto 0) ) is
		begin
				
					-- Conversion de los valores de BCD a 7 segmentos
					case BCD is 
					
						when "0000" => D <= zero;
						when "0001" => D <= uno;
						when "0010" => D <= dos;
						when "0011" => D <= tres;
						when "0100" => D <= quat;
						when "0101" => D <= qint;
						when "0110" => D <= sixt;
						when "0111" => D <= sept;
						when "1000" => D <= octo;
						when "1001" => D <= nono;
						when "1010" => D <= alph;
						when "1011" => D <= beta;
						when "1100" => D <= cobi;
						when "1101" => D <= delt;
						when "1110" => D <= eco;
						when others => D <= fox;
						
					end case;
					
		end bcd_conv;
		
	end bcd_7seg;
						
						
						
				