using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Web.CaseSupportData
{
    public interface IRelationships
    {
        IEnumerable<Relationship> Get(string country, string propertyType, string relationshipKey = null);
    }

    public class Relationships : IRelationships
    {
        readonly IPreferredCultureResolver _cultureResolver;
        readonly IDbContext _dbContext;

        public Relationships(IDbContext dbContext, IPreferredCultureResolver cultureResolver)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            if (cultureResolver == null) throw new ArgumentNullException(nameof(cultureResolver));
            _dbContext = dbContext;
            _cultureResolver = cultureResolver;
        }

        public IEnumerable<Relationship> Get(string country, string propertyType, string relationshipKey = null)
        {
            var culture = _cultureResolver.Resolve();

            var validRelationships = _dbContext.Set<ValidRelationship>().Where(_ => _.PropertyTypeId == propertyType);

            validRelationships = !string.IsNullOrWhiteSpace(country) && validRelationships.Any(_ => _.CountryId == country)
                ? validRelationships.Where(_ => _.CountryId == country)
                : validRelationships.Where(_ => _.CountryId == KnownValues.DefaultCountryCode);

            var vr = validRelationships.Select(_ => new Relationship
                                                    {
                                                        Id = _.RelationshipCode,
                                                        Description = DbFuncs.GetTranslation(_.Relationship.Description, null, _.Relationship.DescriptionTId, culture),
                                                        BaseDescription = DbFuncs.GetTranslation(_.Relationship.Description, null, _.Relationship.DescriptionTId, culture)
                                                    })
                                       .ToArray();

            if ((relationshipKey == null && vr.Any()) || vr.Any(_ => _.Id == relationshipKey))
                return vr;

            return _dbContext.Set<CaseRelation>()
                             .Select(_ => new Relationship
                                          {
                                              Id = _.Relationship,
                                              Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture),
                                              BaseDescription = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                          })
                             .ToArray();
        }
    }

    public class Relationship
    {
        public string Id { get; set; }

        public string Description { get; set; }

        public string BaseDescription { get; set; }
    }
}