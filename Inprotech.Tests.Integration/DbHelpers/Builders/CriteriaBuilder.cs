using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class CriteriaBuilder : Builder
    {
        public CriteriaBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public string JurisdictionId { get; set; }

        public Criteria Create(string name = null, int? parentId = null)
        {
            var item = InsertWithNewId(new Criteria
            {
                Description = Fixture.Prefix(name ?? Fixture.String(3)),
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                CountryId = JurisdictionId
            });

            if (parentId != null)
                Insert(new Inherits { CriteriaNo = item.Id, FromCriteriaNo = parentId.Value });

            return item;
        }
    }
}