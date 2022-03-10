using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Reporting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders
{
    public class DefaultBuilder : IBillDefinitionBuilder
    {
        readonly IBillDefinitions _billDefinitions;

        public DefaultBuilder(IBillDefinitions billDefinitions)
        {
            _billDefinitions = billDefinitions;
        }

        public Task<IEnumerable<ReportDefinition>> Build(BillGenerationRequest request, params BillPrintDetail[] billPrintDetails)
        {
            return Task.FromResult(billPrintDetails.InPrintOrder()
                                                   .Select(billPrintDetail => _billDefinitions.From(request, billPrintDetail, null)));
        }

        public Task EnsureValidSettings()
        {
            return Task.CompletedTask;
        }
    }
}
