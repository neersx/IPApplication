using System.Linq;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Integration.PtoAccess;

namespace Inprotech.Integration.CaseSource
{
    public interface ISourceRestrictor
    {
        IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, DownloadType downloadType = DownloadType.All);
    }
}