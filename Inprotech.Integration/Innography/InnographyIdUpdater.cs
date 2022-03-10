using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Innography
{
    public interface IInnographyIdUpdater
    {
        Task Update(int caseId, string innographyId);
        Task Reject(int caseId, string innographyId);
        void Clear(int caseId);
    }

    public class InnographyIdUpdater : IInnographyIdUpdater
    {
        readonly IChangeTracker _changeTracker;
        readonly IDbContext _dbContext;

        public InnographyIdUpdater(IDbContext dbContext, IChangeTracker changeTracker)
        {
            _dbContext = dbContext;
            _changeTracker = changeTracker;
        }

        public async Task Update(int caseId, string innographyId)
        {
            var db = _dbContext.Set<CpaGlobalIdentifier>();
            var cases = db.Where(_ => _.CaseId == caseId);

            var linked = await cases.SingleOrDefaultAsync(_ => _.InnographyId == innographyId);
            if (linked == null)
            {
                linked = db.Add(new CpaGlobalIdentifier
                                {
                                    CaseId = caseId,
                                    InnographyId = innographyId,
                                    IsActive = true
                                });
            }
            else
            {
                linked.IsActive = true;
            }

            if (!_changeTracker.HasChanged(linked))
            {
                return;
            }

            _dbContext.SaveChanges();
        }

        public async Task Reject(int caseId, string innographyId)
        {
            var db = _dbContext.Set<CpaGlobalIdentifier>();
            var cases = db.Where(_ => _.CaseId == caseId);

            var linked = await cases.SingleOrDefaultAsync(_ => _.InnographyId == innographyId);
            if (linked == null)
            {
                linked = db.Add(new CpaGlobalIdentifier
                                {
                                    CaseId = caseId,
                                    InnographyId = innographyId,
                                    IsActive = false
                                });
            }
            else
            {
                linked.IsActive = false;
            }

            if (!_changeTracker.HasChanged(linked))
            {
                return;
            }

            _dbContext.SaveChanges();
        }

        public void Clear(int caseId)
        {
            var db = _dbContext.Set<CpaGlobalIdentifier>();

            var cases = db.Where(_ => _.CaseId == caseId);

            _dbContext.Delete(cases);

            _dbContext.SaveChanges();
        }
    }
}