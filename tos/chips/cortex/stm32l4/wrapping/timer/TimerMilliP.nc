configuration TimerMilliP
{
	provides
	{
		interface Timer<TMilli> as TimerMilli[uint8_t id];
	}
}

implementation
{
	components AlarmMilli32C;

	components new AlarmToTimerC(TMilli);
	AlarmToTimerC.Alarm -> AlarmMilli32C;

	components new VirtualizeTimerC(TMilli, uniqueCount(UQ_TIMER_MILLI));
	TimerMilli = VirtualizeTimerC;
	VirtualizeTimerC.TimerFrom -> AlarmToTimerC;
}