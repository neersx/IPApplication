using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Tests.Integration.DbHelpers.Builders
{
    class CountryBuilder : Builder
    {
        public CountryBuilder(IDbContext dbContext) : base(dbContext)
        {

        }

        public string Type { get; set; }

        public Country Create(string name)
        {
            return InsertWithNewId(new Country
            {
                Name = Fixture.Prefix(name),
                Type = Type ?? "0"
            });
        }
    }
}
