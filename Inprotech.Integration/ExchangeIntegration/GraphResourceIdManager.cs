using System;
using System.Data.Entity;
using System.Threading.Tasks;
using InprotechKaizen.Model;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExchangeIntegration
{
    public interface IGraphResourceManager
    {
        Task SaveAsync(int staffId, DateTime createdOn, KnownExchangeResourceType resourceType, string resourceId);

        Task<string> GetAsync(int staffId, DateTime createdOn, KnownExchangeResourceType resourceType);

        Task<bool> DeleteAsync(int staffId, DateTime createdOn, KnownExchangeResourceType resourceType, string resourceId);
    }

    public class GraphResourceIdManager : IGraphResourceManager
    {
        readonly IDbContext _dbContext;

        public GraphResourceIdManager(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task SaveAsync(int staffId, DateTime createdOn, KnownExchangeResourceType resourceType, string resourceId)
        {
            _dbContext.Set<ExchangeResourceTracker>().Add(
                                                          new ExchangeResourceTracker(
                                                                                      staffId,
                                                                                      createdOn,
                                                                                      (short) resourceType,
                                                                                      resourceId)
                                                         );
            await _dbContext.SaveChangesAsync();
        }

        public async Task<string> GetAsync(int staffId, DateTime createdOn, KnownExchangeResourceType resourceType)
        {
            var resource = await _dbContext.Set<ExchangeResourceTracker>().SingleOrDefaultAsync(_ => _.StaffId == staffId
                                                                                                     && _.ResourceType == (short) resourceType
                                                                                                     && _.SequenceDate == createdOn
                                                                                               );

            return resource?.ResourceId;
        }

        public async Task<bool> DeleteAsync(int staffId, DateTime createdOn, KnownExchangeResourceType resourceType, string resourceId)
        {
            var resource = await _dbContext.Set<ExchangeResourceTracker>().SingleOrDefaultAsync(_ => _.StaffId == staffId
                                                                                                     && _.ResourceType == (short) resourceType
                                                                                                     && _.SequenceDate == createdOn
                                                                                                     && _.ResourceId == resourceId
                                                                                               );

            if (resource == null) return false;

            _dbContext.Set<ExchangeResourceTracker>().Remove(resource);
            await _dbContext.SaveChangesAsync();
            return true;
        }
    }
}