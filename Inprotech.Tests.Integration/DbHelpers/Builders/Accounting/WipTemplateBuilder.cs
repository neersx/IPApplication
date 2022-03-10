using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Persistence;
using WipCategory = InprotechKaizen.Model.Accounting.WipCategory;

namespace Inprotech.Tests.Integration.DbHelpers.Builders.Accounting
{
    internal class WipTemplateBuilder : Builder
    {
        public WipTemplateBuilder(IDbContext dbContext) : base(dbContext)
        {
        }

        public WipTemplate Create(string code = null, short usedBy = 15, string typeId = null, string taxCode = null)
        {
            var wipTypeCode = typeId ?? "E2EWIP";

            if (!DbContext.Set<WipType>().Any(_ => _.Id == wipTypeCode))
            {
                Insert(new WipType
                {
                    Id = wipTypeCode,
                    CategoryId = WipCategory.ServiceCharge
                });
            }

            var wipType = DbContext.Set<WipType>()
                                   .Include(_ => _.Category)
                                   .Single(_ => _.Id == wipTypeCode);

            return Insert(new WipTemplate
            {
                WipCode = code?.Substring(0, 3) + "WIP",
                Description = code + "_WIP Activity",
                UsedBy = usedBy,
                WipTypeId = wipType.Id,
                WipType = wipType,
                TaxCode = taxCode
            });
        }
    }
}