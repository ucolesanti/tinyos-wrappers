configuration Alarm32khz32C{
	provides interface Counter<T32khz, uint32_t>;
	provides interface Alarm<T32khz, uint32_t>;

}
implementation{
	components Tim2Alarm32khz32P, MainC;
	
	Counter = Tim2Alarm32khz32P;
	Alarm = Tim2Alarm32khz32P;

	MainC.SoftwareInit -> Tim2Alarm32khz32P;
	
}