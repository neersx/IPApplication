using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class ImportanceBuilder : Builder
    {
        public ImportanceBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public Importance Create(string name = null)
        {
            return InsertWithNewId(new Importance
            {
                Description = Fixture.Prefix(name ?? Fixture.String(3))
            });
        }
    }
}
