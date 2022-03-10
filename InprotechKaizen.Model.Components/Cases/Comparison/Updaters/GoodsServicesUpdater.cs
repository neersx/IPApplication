using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface IGoodsServicesUpdater
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        void Update(Case @case, IEnumerable<Components.Cases.Comparison.Results.GoodsServices> updatedData);
    }

    public class GoodsServicesUpdater : IGoodsServicesUpdater
    {
        readonly IDbContext _dbContext;
        readonly IGoodsServices _goodsServices;

        public GoodsServicesUpdater(IDbContext dbContext, IGoodsServices goodsServices)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbContext = dbContext;
            _goodsServices = goodsServices;
        }

        public void Update(Case @case, IEnumerable<Components.Cases.Comparison.Results.GoodsServices> updatedData)
        {
            if (@case == null) throw new ArgumentNullException("case");
            if (updatedData == null) throw new ArgumentNullException("updatedData");

            var classUpdated = false;
            var goodsServicesUpdated = updatedData as IList<Components.Cases.Comparison.Results.GoodsServices> ?? updatedData.ToList();

            foreach (var goodsService in goodsServicesUpdated)
            {
                var classId = goodsService.Class.OurValue ?? goodsService.Class.TheirValue;
                if (_goodsServices.DoesClassExists(@case, classId))
                {
                    continue;
                }

                goodsService.Class.OurValue = _goodsServices.AddClass(@case, classId);
                classUpdated = true;
            }

            if (classUpdated)
            {
                _dbContext.SaveChanges();

                @case = _dbContext.Set<Case>()
                                  .Include(c => c.CaseTexts)
                                  .Include(c => c.ClassFirstUses)
                                  .Single(c => c.Id == @case.Id);
            }

            foreach (var goodsService in goodsServicesUpdated)
            {
                _goodsServices.AddOrUpdate(@case, goodsService.Class.OurValue,
                                           goodsService.Text != null && goodsService.Text.Updated ? goodsService.Text.TheirValue : null,
                                           goodsService.Language?.OurValue?.Key,
                                           goodsService.FirstUsedDate != null && goodsService.FirstUsedDate.Updated ? goodsService.FirstUsedDate.TheirValue : null,
                                           goodsService.FirstUsedDateInCommerce != null && goodsService.FirstUsedDateInCommerce.Updated ? goodsService.FirstUsedDateInCommerce.TheirValue : null);
            }
        }
    }
}