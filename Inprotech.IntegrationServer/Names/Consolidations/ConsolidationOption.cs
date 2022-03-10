namespace Inprotech.IntegrationServer.Names.Consolidations
{
    public class ConsolidationOption
    {
        public bool KeepAddressHistory { get; }

        public bool KeepTelecomHistory { get; }

        public bool KeepConsolidatedName { get; }

        public ConsolidationOption(bool keepAddressHistory, bool keepTelecomHistory, bool keepConsolidatedName)
        {
            KeepConsolidatedName = keepConsolidatedName;
            KeepAddressHistory = keepAddressHistory;
            KeepTelecomHistory = keepTelecomHistory;
        }
    }
}