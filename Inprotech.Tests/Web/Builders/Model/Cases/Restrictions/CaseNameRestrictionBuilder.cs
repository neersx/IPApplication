using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Cases.Restrictions
{
    public class CaseNameRestrictionBuilder : IBuilder<CaseNameRestriction>
    {
        readonly InMemoryDbContext _db;

        public CaseNameRestrictionBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public DebtorStatus DebtorStatus { get; set; }
        public CaseName CaseName { get; set; }

        public CaseNameRestriction Build()
        {
            return new CaseNameRestriction(
                                           CaseName ?? new CaseNameBuilder(_db).Build(),
                                           DebtorStatus ?? new DebtorStatusBuilder().Build()
                                          );
        }
    }
}