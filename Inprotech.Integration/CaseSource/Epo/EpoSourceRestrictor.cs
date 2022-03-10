using System.Linq;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Integration.PtoAccess;

namespace Inprotech.Integration.CaseSource.Epo
{
    public class EpoSourceRestrictor : ISourceRestrictor
    {
        public IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, DownloadType downloadType = DownloadType.All)
        {
            return from c in cases
                   where c.ApplicationNumber != null && c.ApplicationNumber.Trim() != string.Empty
                         || c.PublicationNumber != null && c.PublicationNumber.Trim() != string.Empty
                   select c;
        }
    }
}