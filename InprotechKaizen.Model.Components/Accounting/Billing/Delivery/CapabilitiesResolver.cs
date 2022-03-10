using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Integration.Exchange;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery
{
    public interface ICapabilitiesResolver
    {
        Task<Capabilities> Resolve();
    }

    public class CapabilitiesResolver : ICapabilitiesResolver
    {
        readonly IExchangeSiteSettingsResolver _exchangeSiteSettingsResolver;

        public CapabilitiesResolver(IExchangeSiteSettingsResolver exchangeSiteSettingsResolver)
        {
            _exchangeSiteSettingsResolver = exchangeSiteSettingsResolver;
        }

        public async Task<Capabilities> Resolve()
        {
            var r = await _exchangeSiteSettingsResolver.Resolve();

            return new Capabilities
            {
                CanDeliverBillInDraftMailbox = r.HasValidSettings && r.Settings.IsBillFinalisationEnabled
            };
        }
    }

    public class Capabilities
    {
        public bool CanDeliverBillInDraftMailbox { get; set; }
    }
}