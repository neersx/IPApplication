using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.ResponseEnrichment;
using InprotechKaizen.Model.Components.Accounting.Billing.BulkBilling;

namespace Inprotech.Web.Accounting.Billing.BulkBilling
{
    [Authorize]
    [NoEnrichment]
    [UseDefaultContractResolver]
    [RoutePrefix("api/accounting/bulk-billing")]
    public class BulkBillingController : ApiController
    {
        readonly IBillDateSettingsResolver _billDateSettingsResolver;

        public BulkBillingController(IBillDateSettingsResolver billDateSettingsResolver)
        {
            _billDateSettingsResolver = billDateSettingsResolver;
        }

        [HttpGet]
        [Route("settings/bill-date")]
        public async Task<BillDateSetting> GetBillDateSetting()
        {
            return await _billDateSettingsResolver.Resolve();
        }
    }
}