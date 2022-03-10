using System.Linq;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Integration.PtoAccess;
using InprotechKaizen.Model.Persistence;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Integration.CaseSource.FileApp
{
    public class FileAppSourceRestrictor : ISourceRestrictor
    {
        readonly IDbContext _dbContext;

        public FileAppSourceRestrictor(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        
        public IQueryable<EligibleCaseItem> Restrict(IQueryable<EligibleCaseItem> cases, DownloadType downloadType = DownloadType.All)
        {
            var fileCases = _dbContext.Set<FileCaseEntity>();

            return from c in cases
                   where fileCases.Any(_ => _.CaseId == c.CaseKey)
                   select c;
        }
    }
}