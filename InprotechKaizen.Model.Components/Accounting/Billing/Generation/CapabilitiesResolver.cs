using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Reporting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation
{
    public interface ICapabilitiesResolver
    {
        Task<Capabilities> Resolve();
    }

    public class CapabilitiesResolver : ICapabilitiesResolver
    {
        readonly IReportProvider _reportProvider;

        public CapabilitiesResolver(IReportProvider reportProvider)
        {
            _reportProvider = reportProvider;
        }
        
        public async Task<Capabilities> Resolve()
        {
            var reportProvider = await _reportProvider.GetReportProviderInfo();

            var canGenerateViaReportingServices = reportProvider?.Provider == ReportProviderType.MsReportingServices;

            return new Capabilities
            {
                CanGeneratePrintPreview = canGenerateViaReportingServices,
                CanGenerateBills = canGenerateViaReportingServices
            };
        }
    }

    public class Capabilities
    {
        public bool CanGeneratePrintPreview { get; set; }

        public bool CanGenerateBills { get; set; }
    }
}
