using System.Collections.Generic;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Reporting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders
{
    public interface IBillDefinitionBuilder
    {
        public Task<IEnumerable<ReportDefinition>> Build(BillGenerationRequest request,
                                                   params BillPrintDetail[] billPrintDetails);

        Task EnsureValidSettings();
    }
}
