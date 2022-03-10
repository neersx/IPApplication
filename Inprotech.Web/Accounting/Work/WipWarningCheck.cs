using System.Net;
using System.Threading.Tasks;
using System.Web.Http;

namespace Inprotech.Web.Accounting.Work
{
    public interface IWipWarningCheck
    {
        Task<bool> For(int? caseKey, int? nameKey);
    }

    public class WipWarningCheck : IWipWarningCheck
    {
        readonly IWipWarnings _wipWarnings;

        public WipWarningCheck(IWipWarnings wipWarnings)
        {
            _wipWarnings = wipWarnings;
        }
        public async Task<bool> For(int? caseKey, int? nameKey)
        {
            if (caseKey.HasValue &&
                (!await _wipWarnings.AllowWipFor(caseKey.Value) ||
                 await _wipWarnings.HasDebtorRestriction(caseKey.Value)))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            if (!caseKey.HasValue && nameKey.HasValue && await _wipWarnings.HasNameRestriction(nameKey.Value))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            return true;
        }
    }
}
