configuration AlarmMilli32C{
	provides interface Alarm<TMilli,uint32_t>;
}
implementation{
	components new TransformAlarmC(TMilli, uint32_t, T32khz, uint16_t, 5);
	components UlptimTimerC, CounterMilli32C;

	Alarm = TransformAlarmC;

	TransformAlarmC.AlarmFrom -> UlptimTimerC;
	TransformAlarmC.Counter -> CounterMilli32C;

}