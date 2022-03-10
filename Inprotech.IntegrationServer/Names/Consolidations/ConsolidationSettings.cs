using Inprotech.Integration.Settings;

namespace Inprotech.IntegrationServer.Names.Consolidations
{
    public interface IConsolidationSettings
    {
        int Timeout { get; set; }

        int DefaultTimeout { get; }
    }

    public class ConsolidationSettings : IConsolidationSettings
    {
        public ConsolidationSettings(GroupedConfigSettings.Factory settings)
        {
            var t = settings("NameConsolidation")["CommandTimeout"];

            Timeout = !int.TryParse(t, out var timeout) ? DefaultTimeout : timeout;
        }

        public int DefaultTimeout => 60;

        public int Timeout { get; set; }
    }
}