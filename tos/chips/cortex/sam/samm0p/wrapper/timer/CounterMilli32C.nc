configuration CounterMilli32C
{
	provides interface Counter<TMilli, uint32_t>;
}

implementation
{

	components SamRtcC;
	Counter = SamRtcC;

}
