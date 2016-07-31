configuration UlptimTimerC{
	provides interface Counter<T32khz, uint16_t>;
	provides interface Alarm<T32khz, uint16_t>;

}
implementation{
	components UlptimTimerP, MainC;
	
	Counter = UlptimTimerP;
	Alarm = UlptimTimerP;

	MainC.SoftwareInit -> UlptimTimerP;
	
}
