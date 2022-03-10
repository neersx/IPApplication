using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public interface IOpenItemNumbers
    {
        Task<string> AcquireNextDraftNumber(int itemEntityId, int staffId);
    }

    public class OpenItemNumbers : IOpenItemNumbers
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public OpenItemNumbers(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<string> AcquireNextDraftNumber(int itemEntityId, int staffId)
        {
            var draftPrefix = _siteControlReader.Read<string>(SiteControls.DRAFTPREFIX) ?? "D";

            var itemNoPrefix = await ResolveOpenItemPrefixByOffice(staffId);

            var entity = await GetSpecialName(itemEntityId);
            
            var lasAllocated = await ResolveLastAllocated(itemEntityId, $"{draftPrefix}{itemNoPrefix}");

            var nextToAllocate = (lasAllocated ?? entity.LastDraftNo).GetValueOrDefault() + 1;

            entity.LastDraftNo = nextToAllocate;

            await _dbContext.SaveChangesAsync();

            return $"{draftPrefix}{itemNoPrefix}{nextToAllocate}";
        }

        async Task<SpecialName> GetSpecialName(int itemEntityId)
        {
            return await _dbContext.Set<SpecialName>().SingleAsync(_ => _.Id == itemEntityId);
        }

        async Task<string> ResolveOpenItemPrefixByOffice(int staffId)
        {
            var staffIdInString = $"{staffId}";

            return await (from ta in _dbContext.Set<TableAttributes>()
                    join o in _dbContext.Set<Office>() on ta.TableCodeId equals o.Id into o1
                    from o in o1
                    where o.ItemNoPrefix != null &&
                          ta.SourceTableId == (short)TableTypes.Office &&
                          ta.ParentTable == "NAME" &&
                          ta.GenericKey == staffIdInString
                    select o.ItemNoPrefix
                ).SingleOrDefaultAsync();
        }

        async Task<int?> ResolveLastAllocated(int itemEntityId, string itemNoPrefix)
        {
            var counts = await (from oi in _dbContext.Set<OpenItem>()
                            where oi.ItemEntityId == itemEntityId &&
                                  oi.OpenItemNo.StartsWith(itemNoPrefix)
                            let count = oi.OpenItemNo.Replace(itemNoPrefix, string.Empty)
                            select count)
                .ToArrayAsync();

            return counts.Any() ? counts.Select(int.Parse).Max() : null;
        }
    }
}
