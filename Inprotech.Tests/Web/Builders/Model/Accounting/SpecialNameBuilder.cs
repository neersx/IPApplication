using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Accounting
{
    public class SpecialNameBuilder : IBuilder<SpecialName>
    {
        readonly InMemoryDbContext _db;

        public SpecialNameBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public bool? EntityFlag { get; set; }
        public Name EntityName { get; set; }

        public SpecialName Build()
        {
            return new SpecialName(EntityFlag, EntityName ?? new NameBuilder(_db) {LastName = Fixture.String()}.Build().In(_db));
        }
    }
}