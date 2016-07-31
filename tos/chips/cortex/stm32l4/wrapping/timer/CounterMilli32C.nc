configuration CounterMilli32C{
	provides interface Counter<TMilli,uint32_t>;
}
implementation{
	components new TransformCounterC(TMilli, uint32_t, T32khz, uint16_t, 5, uint16_t);
	components UlptimTimerC;
	
	Counter = TransformCounterC;

	TransformCounterC.CounterFrom -> UlptimTimerC;

	
}