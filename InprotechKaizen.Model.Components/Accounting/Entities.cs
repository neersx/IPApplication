using System.Collections.Generic;
using System.Data.Entity;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting
{
    public interface IEntities
    {
        Task<IEnumerable<EntityName>> Get(int staffId);

        Task<bool> IsRestrictedByCurrency(int entityId);
    }

    public class Entities : IEntities
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControls;
        readonly IDisplayFormattedName _displayFormattedName;

        public Entities(IDbContext dbContext, ISiteControlReader siteControls, IDisplayFormattedName displayFormattedName)
        {
            _dbContext = dbContext;
            _siteControls = siteControls;
            _displayFormattedName = displayFormattedName;
        }

        public async Task<IEnumerable<EntityName>> Get(int staffNameId)
        {
            var defaultEntityId = _dbContext.Set<Employee>().Single(_ => _.Id == staffNameId).DefaultEntityId;
            if (!defaultEntityId.HasValue)
            {
                var officeEntity = await (from s in _dbContext.Set<SpecialName>() 
                                          join o in _dbContext.Set<Office>() on s.Id equals o.OrganisationId
                                          join t in _dbContext.Set<TableAttributes>() on o.Id equals t.TableCodeId
                                          where s.IsEntity == decimal.One && 
                                                t.GenericKey == staffNameId.ToString() && 
                                                t.ParentTable == KnownTableAttributes.Name && 
                                                t.SourceTableId == (short) TableTypes.Office
                                          select new
                                          {
                                              s.Id
                                          }).ToListAsync();

                if (officeEntity.Count == 1)
                    defaultEntityId = officeEntity.SingleOrDefault()?.Id;
            }

            var entityId = defaultEntityId ?? _siteControls.Read<int>(SiteControls.HomeNameNo);

            var entities = await (from e in _dbContext.Set<SpecialName>()
                             join n in _dbContext.Set<Name>() on e.Id equals n.Id
                             where e.IsEntity == decimal.One
                             select new EntityName
                             {
                                 Id = e.Id,
                                 IsDefault = n.Id == entityId
                             }).ToArrayAsync();

            var formattedNames = await _displayFormattedName.For(entities.Select(_ => _.Id).ToArray());

            foreach (var entity in entities)
            {
                entity.DisplayName = formattedNames[entity.Id].Name;
            }

            return entities.OrderBy(_ => _.DisplayName);
        }

        public async Task<bool> IsRestrictedByCurrency(int entityId)
        {
            var hasRestrictedByCurrencySettings = _siteControls.Read<bool>(SiteControls.EntityRestrictionByCurrency);
            if (!hasRestrictedByCurrencySettings) return false;

            var homeCurrency = _siteControls.Read<string>(SiteControls.CURRENCY);
            
            var entity = await _dbContext.Set<SpecialName>().SingleAsync(sn => sn.Id == entityId);

            if (string.IsNullOrEmpty(entity.Currency) || entity.IsEntity.GetValueOrDefault() != 1) return false;

            return string.Compare(entity.Currency, homeCurrency, CultureInfo.InvariantCulture, CompareOptions.IgnoreCase) != 0;
        }
    }

    public class EntityName
    {
        public int Id { get; set; }
        public bool? IsDefault { get; set; }
        public string DisplayName { get; set; }
    }
}