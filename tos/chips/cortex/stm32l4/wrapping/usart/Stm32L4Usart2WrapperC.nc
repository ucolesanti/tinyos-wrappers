configuration Stm32L4Usart2WrapperC{
	provides interface StdControl ;
	provides interface UartByte;
	provides interface UartStream;
}
implementation{
	components MainC,McuSleepC ;
	components Stm32L4Usart2WrapperP ;

	StdControl = Stm32L4Usart2WrapperP;
	UartByte = Stm32L4Usart2WrapperP;
	UartStream = Stm32L4Usart2WrapperP ;

	MainC.SoftwareInit -> Stm32L4Usart2WrapperP ;
	McuSleepC.McuPowerOverride -> Stm32L4Usart2WrapperP;
	Stm32L4Usart2WrapperP.McuPowerState -> McuSleepC;
}