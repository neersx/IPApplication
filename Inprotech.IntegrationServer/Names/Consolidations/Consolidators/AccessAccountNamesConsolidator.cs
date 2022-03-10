using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class AccessAccountNamesConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public AccessAccountNamesConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(AccessAccountNamesConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await CopyAccessAccountNames(to, from);

            await DeleteAccessAccountNames(from);
        }

        async Task DeleteAccessAccountNames(Name from)
        {
            await _dbContext.DeleteAsync(from a in _dbContext.Set<AccessAccountName>()
                                         where a.NameId == @from.Id
                                         select a);
        }

        async Task CopyAccessAccountNames(Name to, Name from)
        {
            _dbContext.AddRange(await NamesToCopy(to, from));

            await _dbContext.SaveChangesAsync();
        }

        async Task<IEnumerable<AccessAccountName>> NamesToCopy(Name to, Name from)
        {
            var accessAccountNamesToCopy = await (
                from a in _dbContext.Set<AccessAccountName>()
                join a1 in _dbContext.Set<AccessAccountName>()
                                     .Where(_ => _.NameId == to.Id)
                    on a.AccessAccountId equals a1.AccessAccountId into a1J
                from a1 in a1J.DefaultIfEmpty()
                where a.NameId == @from.Id && a1 == null
                select new
                {
                    a.AccessAccountId,
                    NameId = to.Id
                }).ToArrayAsync();

            return accessAccountNamesToCopy.Select(a => new AccessAccountName
            {
                AccessAccountId = a.AccessAccountId,
                NameId = a.NameId
            }).ToArray();
        }
    }
}