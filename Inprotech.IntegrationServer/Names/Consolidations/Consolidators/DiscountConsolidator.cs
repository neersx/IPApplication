using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.Names.Consolidations.Consolidators
{
    public class DiscountConsolidator : INameConsolidator
    {
        readonly IDbContext _dbContext;

        public DiscountConsolidator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public string Name => nameof(DiscountConsolidator);

        public async Task Consolidate(Name to, Name from, ConsolidationOption option)
        {
            await CopyDiscounts(to, from);

            await UpdateCaseOwner(to, from);

            await UpdateEmployeeNo(to, from);

            await DeleteDiscounts(from, option.KeepConsolidatedName);
        }

        async Task CopyDiscounts(Name to, Name from)
        {
            var maxDiscounts = from d in _dbContext.Set<Discount>().AsQueryable()
                               group d by d.NameId
                               into g1
                               select new
                               {
                                   NameId = g1.Key,
                                   Sequence = g1.DefaultIfEmpty().Max(_ => (short?) _.Sequence) ?? (short?) 0
                               };

            var discountsToCopy = await (from d in _dbContext.Set<Discount>()
                                         join d1 in maxDiscounts on new {NameId = (int?) to.Id} equals new {d1.NameId} into d1J
                                         from d1 in d1J.DefaultIfEmpty()
                                         join d2 in _dbContext.Set<Discount>().Where(_ => _.NameId == to.Id)
                                             on new
                                             {
                                                 d.PropertyTypeId,
                                                 d.ActionId,
                                                 d.WipCategory,
                                                 d.WipTypeId,
                                                 d.EmployeeId,
                                                 d.ProductCode,
                                                 d.CaseOwnerId,
                                                 d.WipCode,
                                                 d.CaseTypeId,
                                                 d.CountryId
                                             }
                                            equals new
                                             {
                                                 d2.PropertyTypeId,
                                                 d2.ActionId,
                                                 d2.WipCategory,
                                                 d2.WipTypeId,
                                                 d2.EmployeeId,
                                                 d2.ProductCode,
                                                 d2.CaseOwnerId,
                                                 d2.WipCode,
                                                 d2.CaseTypeId,
                                                 d2.CountryId
                                             }
                                            into d2J
                                         from d2 in d2J.DefaultIfEmpty()
                                         where d.NameId == @from.Id && d2 == null
                                         select new
                                         {
                                             NameId = to.Id,
                                             Sequence = (short) (d.Sequence + (d1 == null ? 0 : d1.Sequence) + 1),
                                             d.PropertyTypeId,
                                             d.ActionId,
                                             d.DiscountRate,
                                             d.WipCategory,
                                             d.BasedOnAmount,
                                             d.WipTypeId,
                                             d.EmployeeId,
                                             d.ProductCode,
                                             d.CaseOwnerId,
                                             d.MarginProfileId,
                                             d.WipCode,
                                             d.CaseTypeId,
                                             d.CountryId
                                         }).ToArrayAsync();

            foreach (var discount in discountsToCopy)
            {
                _dbContext.Set<Discount>().Add(new Discount
                {
                    NameId = discount.NameId,
                    Sequence = discount.Sequence,
                    PropertyTypeId = discount.PropertyTypeId,
                    ActionId = discount.ActionId,
                    DiscountRate = discount.DiscountRate,
                    WipCategory = discount.WipCategory,
                    BasedOnAmount = discount.BasedOnAmount,
                    WipTypeId = discount.WipTypeId,
                    EmployeeId = discount.EmployeeId,
                    ProductCode = discount.ProductCode,
                    CaseOwnerId = discount.CaseOwnerId,
                    MarginProfileId = discount.MarginProfileId,
                    WipCode = discount.WipCode,
                    CaseTypeId = discount.CaseTypeId,
                    CountryId = discount.CountryId
                });
            }

            await _dbContext.SaveChangesAsync();
        }

        async Task UpdateCaseOwner(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from d in _dbContext.Set<Discount>()
                                         where d.CaseOwnerId == @from.Id
                                         select d,
                                         _ => new Discount {CaseOwnerId = to.Id});
        }

        async Task UpdateEmployeeNo(Name to, Name from)
        {
            await _dbContext.UpdateAsync(from d in _dbContext.Set<Discount>()
                                         where d.EmployeeId == @from.Id
                                         select d,
                                         _ => new Discount {EmployeeId = to.Id});
        }

        async Task DeleteDiscounts(Name from, bool shouldKeepConsolidatedName)
        {
            if (shouldKeepConsolidatedName) return;

            await _dbContext.DeleteAsync(from d in _dbContext.Set<Discount>()
                                         where d.NameId == @from.Id
                                         select d);
        }
    }
}