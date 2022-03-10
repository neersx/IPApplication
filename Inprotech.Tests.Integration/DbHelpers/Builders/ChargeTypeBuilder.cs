using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class ChargeTypeBuilder : Builder
    {
        public ChargeTypeBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public ChargeType Create(string prefix=null)
        {
            return InsertWithNewId(new ChargeType { Description = (prefix ?? "Fee") + Fixture.String(5) });
        }
    }
}
