using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseAccessAccountBuilder : IBuilder<CaseAccess>
    {
        readonly InMemoryDbContext _db;

        public CaseAccessAccountBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Case Case { get; set; }
        public int? AccountId { get; set; }

        public CaseAccess Build()
        {
            return new CaseAccess(
                                  Case ?? new CaseBuilder().Build().In(_db),
                                  AccountId ?? Fixture.Integer());
        }

        public static CaseAccessAccountBuilder ForSpecificCaseAndAccount(InMemoryDbContext db, Case @case, int accountId)
        {
            return new CaseAccessAccountBuilder(db)
            {
                Case = @case,
                AccountId = accountId
            };
        }
    }
}