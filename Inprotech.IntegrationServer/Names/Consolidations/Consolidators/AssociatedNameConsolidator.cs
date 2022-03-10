using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

#pragma warning disable 618

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class AssociatedNameConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public AssociatedNameConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(AssociatedNameConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await UpdateName(to, from);

            await UpdateRelatedName(to, from);

            await DeleteOldRelatedNameReferences(from, option.KeepConsolidatedName);

            await DeleteOldAssociatedNameReferences(from, option.KeepConsolidatedName);
        }

        async Task UpdateName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from na in _dbContext.Set<AssociatedName>()
                                         join na1 in _dbContext.Set<AssociatedName>()
                                             on new
                                             {
                                                 NameId = to.Id,
                                                 na.Relationship,
                                                 na.RelatedNameId
                                             }
                                            equals new
                                             {
                                                 NameId = na1.Id,
                                                 na1.Relationship,
                                                 na1.RelatedNameId
                                             }
                                            into na1J
                                         from na1 in na1J.DefaultIfEmpty()
                                         where na.Id == @from.Id && na1 == null
                                         select na,
                                         _ => new AssociatedName {Id = to.Id});
        }

        async Task UpdateRelatedName(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from na in _dbContext.Set<AssociatedName>()
                                         join na1 in _dbContext.Set<AssociatedName>()
                                             on new
                                             {
                                                 na.Id,
                                                 na.Relationship,
                                                 NameId = to.Id
                                             }
                                            equals new
                                             {
                                                 na1.Id,
                                                 na1.Relationship,
                                                 NameId = na1.RelatedNameId
                                             }
                                            into na1J
                                         from na1 in na1J.DefaultIfEmpty()
                                         where na.RelatedNameId == @from.Id && na1 == null
                                         select na,
                                         _ => new AssociatedName {RelatedNameId = to.Id});
        }

        async Task DeleteOldRelatedNameReferences(Name from, bool shouldKeepConsolidatedName)
        {
            if (shouldKeepConsolidatedName) return;

            await _dbContext.DeleteAsync(_dbContext.Set<AssociatedName>().Where(_ => _.RelatedNameId == from.Id));
        }

        async Task DeleteOldAssociatedNameReferences(Name from, bool shouldKeepConsolidatedName)
        {
            if (shouldKeepConsolidatedName) return;

            await _dbContext.DeleteAsync(_dbContext.Set<AssociatedName>().Where(_ => _.Id == from.Id));
        }
    }
}