using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class AssociatedNameBuilder : IBuilder<AssociatedName>
    {
        readonly InMemoryDbContext _db;

        public AssociatedNameBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Name Name { get; set; }
        public Name RelatedName { get; set; }
        public string Relationship { get; set; }
        public short? Sequence { get; set; }

        public Name ContactName { get; set; }
        public Address Address { get; set; }
        public PropertyType PropertyType { get; set; }

        public virtual TableCode PositionCategory { get; set; }

        public AssociatedName Build()
        {
            var associatedName = new AssociatedName(
                                                    Name ?? new NameBuilder(_db).Build(),
                                                    RelatedName ?? new NameBuilder(_db).Build(),
                                                    Relationship ?? Fixture.String("Relationship"),
                                                    Sequence ?? Fixture.Short());

            associatedName.SetPostalAddress(Address ?? new AddressBuilder().Build());
            associatedName.ContactId = (ContactName ?? new NameBuilder(_db).Build()).Id;
            associatedName.SetPropertyType(PropertyType ?? new PropertyTypeBuilder().Build().In(_db));
            associatedName.SetPositionCategory(PositionCategory ?? new TableCodeBuilder().Build());
            return associatedName;
        }
    }
}