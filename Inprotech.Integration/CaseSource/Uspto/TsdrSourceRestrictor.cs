using System.Linq;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Integration.PtoAccess;

namespace Inprotech.Integration.CaseSource.Uspto
{
    public class TsdrSourceRestrictor : ISourceRestrictor
    {
        public IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, DownloadType downloadType = DownloadType.All)
        {
            return from c in cases
                   where c.ApplicationNumber != null && c.ApplicationNumber.Trim() != string.Empty
                         || c.RegistrationNumber != null && c.RegistrationNumber.Trim() != string.Empty
                   select c;
        }
    }
}