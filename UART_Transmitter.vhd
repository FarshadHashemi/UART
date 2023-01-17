Library IEEE ;
Use IEEE.STD_Logic_1164.All ;

Entity UART_Transmitter Is

   Generic(
      Data_Bits       : Integer   := 9 ;
      Stop_Bits       : Integer   := 2 ;
      Baud_Rate       : Integer   := 110 ; -- (Bits Per Second)
      Clock_Frequency : Integer   := 250 ;  -- (MHz)
      Parity_Enable   : Integer   := 1 ;    -- Just 0 Or 1 
      Even_Odd_Parity : STD_Logic := '1'    -- (Even=0) (Odd=1) 
   ) ;

   Port(
      Clock             : In  STD_Logic ;
      Input             : In  STD_Logic_Vector(Data_Bits-1 Downto 0) ;
      Available_Input   : In  STD_Logic ;
      Output            : Out STD_Logic ;
      Busy              : Out STD_Logic
   ) ;

End UART_Transmitter ;

Architecture Behavioral Of UART_Transmitter Is

   Signal Input_Register             : STD_Logic_Vector(Data_Bits-1 Downto 0) := (Others=>'0') ;
   Signal Available_Input_Register   : STD_Logic                              := '0' ;
   Signal Output_Register            : STD_Logic                              := '1' ;
   Signal Busy_Register              : STD_Logic                              := '0' ;

   Signal Data_Line                  : STD_Logic_Vector(Data_Bits+Parity_Enable+Stop_Bits Downto 0) := (Others=>'0') ;

   Signal Parity                     : STD_Logic_Vector(Data_Bits-2 Downto 0) := (Others=>'0') ;

   Signal Time_Counter               : Integer Range 0 To (((Clock_Frequency*(10**6))/Baud_Rate)-1) := 0 ;
   Signal Bit_Counter                : Integer Range 0 To (Data_Bits+Parity_Enable+Stop_Bits) := 0 ;

Begin

   Data_Line(Data_Bits+Parity_Enable+Stop_Bits Downto Data_Bits+Parity_Enable+1) <= (Others=>'1') ;
   Data_Line(0) <= '0' ;

   Process(Clock)
   Begin

      If Rising_Edge(Clock) Then

      -- Registering Input Ports
         Input_Register <= Input ;
         Available_Input_Register <= Available_Input ;
      -- %%%%%%%%%%%%%%%%%%%%%%%

      -- Wait For New Data
         If (Busy_Register='0') And (Available_Input_Register='1') Then

            Data_Line(Data_Bits Downto 1) <= Input_Register ;
            Busy_Register <= '1' ;
      -- %%%%%%%%%%%%%%%%%

         Elsif Busy_Register='1' Then

         -- Time Control
            Time_Counter <= Time_Counter + 1 ;
            If Time_Counter=(((Clock_Frequency*(10**6))/Baud_Rate)-1) Then
               Time_Counter <= 0 ;
               Bit_Counter <= Bit_Counter + 1 ;
               If Bit_Counter=(Data_Bits+Parity_Enable+Stop_Bits) Then
                  Bit_Counter <= 0 ;
                  Busy_Register <= '0' ;
               End If ;
               End If ;
         -- %%%%%%%%%%%%

         -- Preity Bit Calculation
            If Parity_Enable=1 Then
               Parity(0) <= Data_Line(1) Xor Data_Line(2) ;
               For i In 3 To Data_Bits Loop
                  Parity(i-2) <= Data_Line(i) Xor Parity(i-3) ;
               End Loop ;
               Data_Line(Data_Bits+Parity_Enable) <= Parity(Data_Bits-2) Xor Even_Odd_Parity ;
            End If ;
         -- %%%%%%%%%%%%%%%%%%%%%%

         -- Put Data On The Line
            Output_Register <= Data_Line(Bit_Counter) ;
         -- %%%%%%%%%%%%%%%%%%%%

         End If ;

      End If ;

   End Process ;

-- Registering Output Ports
   Output <= Output_Register ;
   Busy   <= Busy_Register ;
-- %%%%%%%%%%%%%%%%%%%%%%%%

End Behavioral ;