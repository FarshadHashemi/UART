Library IEEE ;
Use IEEE.STD_Logic_1164.All ;

Entity UART_Receiver Is
 
   Generic(
      Data_Bits       : Integer   := 9 ;
      Baud_Rate       : Integer   := 9600 ; -- (Bits Per Second)
      Clock_Frequency : Integer   := 100 ;  -- (MHz)
      Parity_Enable   : Integer   := 1 ;    -- Just 0 Or 1 
      Even_Odd_Parity : STD_Logic := '1'    -- (Even=0) (Odd=1) 
   ) ;

   Port(
      Clock        : In  STD_Logic ;
      Input        : In  STD_Logic ;
      Output       : Out STD_Logic_Vector(Data_Bits-1 Downto 0) ;
      Valid_Output : Out STD_Logic 
   ) ;

End UART_Receiver ;

Architecture Behavioral Of UART_Receiver Is

   Signal Input_Register         : STD_Logic                                                    := '1' ;
   Signal Output_Register        : STD_Logic_Vector(Data_Bits+Parity_Enable-1 Downto 0)         := (Others=>'0') ;
   Signal Valid_Output_Register  : STD_Logic                                                    := '0' ;

   Signal Input_Register_1_Delay : STD_Logic                                                    := '1' ;

   Signal Start                  : STD_Logic                                                    := '0' ;
   Signal Sampling               : STD_Logic                                                    := '0' ;
   Signal Parity_Check           : STD_Logic                                                    := '0' ;

   Signal Parity                 : STD_Logic_Vector(Data_Bits-2 Downto 0)                       := (Others=>'0') ;

   Signal Time_Counter           : Integer Range 0 To (((Clock_Frequency*(10**6))/Baud_Rate)-1) := 0 ;
   Signal Bit_Counter            : Integer Range 0 To (Data_Bits+Parity_Enable-1)               := 0 ;

Begin

   Process(Clock)
   Begin

      If Rising_Edge(Clock) Then

      -- Registering Input Port
         Input_Register         <= Input ;
         Input_Register_1_Delay <= Input_Register ;
      -- %%%%%%%%%%%%%%%%%%%%%%

         Valid_Output_Register  <= '0' ;

      -- Wait For Start
         If (Start='0') And (Sampling='0') And (Input_Register_1_Delay='1') And (Input_Register='0') Then
            Start <= '1' ;
         End If ;
      -- %%%%%%%%%%%%%%

      -- Wait For Bit Center
         If Start='1' Then
            Time_Counter    <= Time_Counter + 1 ;
            If Time_Counter=(((Clock_Frequency*(10**6))/(2*Baud_Rate))-1) Then
               Time_Counter <= 0 ;
               Start        <= '0' ;
               Sampling     <= '1' ;
            End If ;
         End If ;
      -- %%%%%%%%%%%%%%%%%%%

      -- Sampling From Bit Center
         If Sampling='1' Then
            Time_Counter    <= Time_Counter + 1 ;
            If Time_Counter=(((Clock_Frequency*(10**6))/Baud_Rate)-1) Then
               Time_Counter <= 0 ;
               Bit_Counter  <= Bit_Counter + 1 ;
               If Bit_Counter=(Data_Bits+Parity_Enable-1) Then
                  Bit_Counter <= 0 ;
                  Sampling    <= '0' ;
                  If Parity_Enable=1 Then
                     Parity_Check          <= '1' ;
                  Else
                     Valid_Output_Register <= '1' ;
                  End If ;
               End If ;
               Output_Register(Bit_Counter) <= Input_Register ;
            End If ;
         End If ;
      -- %%%%%%%%%%%%%%%%%%%%%%%%

      -- Check Parity If It Is needed
         If Parity_Enable=1 Then
            Parity(0)      <= Output_Register(0) Xor Output_Register(1) ;
            For i In 2 To (Data_Bits-1) Loop
               Parity(i-1) <= Output_Register(i) Xor Parity(i-2) ;
            End Loop ;
            If Parity_Check='1' Then
               Parity_Check <= '0' ;
               If (Output_Register(Data_Bits+Parity_Enable-1) Xor Parity(Data_Bits-2))=Even_Odd_Parity Then
                  Valid_Output_Register <= '1' ;
               End If ;
            End If ;
         End If ;
      -- %%%%%%%%%%%%%%%%%%%%%%%%%%%%

      End If ;

   End Process ;

-- Registering Output Ports
   Output         <= Output_Register(Data_Bits-1 Downto 0) ;
   Valid_Output   <= Valid_Output_Register ;
-- %%%%%%%%%%%%%%%%%%%%%%%%

End Behavioral ;