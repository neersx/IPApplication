using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    public class Builder : DbSetup
    {
        protected static readonly string DefaultPrefix = Fixture.Prefix();

        public Builder(IDbContext dbContext) : base(dbContext)
        {
            
        }
    }
}
