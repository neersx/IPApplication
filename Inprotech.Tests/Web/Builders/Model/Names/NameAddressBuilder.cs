using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class NameAddressBuilder : IBuilder<NameAddress>
    {
        readonly InMemoryDbContext _db;

        public NameAddressBuilder(InMemoryDbContext db)
        {
            _db = db;
        }

        public Name Name { get; set; }

        public Address Address { get; set; }

        public TableCode AddressTypeTableCode { get; set; }

        public TableCode AddressStatusTableCode { get; set; }

        public NameAddress Build()
        {
            var nameAddress = new NameAddress(
                                              Name ?? new NameBuilder(_db).Build(),
                                              Address ?? new AddressBuilder().Build(),
                                              AddressTypeTableCode ?? new TableCodeBuilder().Build());

            nameAddress.AddressStatusTableCode = AddressStatusTableCode ?? new TableCodeBuilder().Build();
            nameAddress.AddressType = nameAddress.AddressTypeTableCode.Id;

            return nameAddress;
        }
    }

    public static class NameAddressBuilderEx
    {
        public static NameAddressBuilder ForName(this NameAddressBuilder builder, Name name)
        {
            builder.Name = name;
            return builder;
        }

        public static NameAddressBuilder As(this NameAddressBuilder builder, AddressType addressType)
        {
            builder.AddressTypeTableCode = new TableCode((int) addressType, (short) TableTypes.AddressType, addressType.ToString());

            return builder;
        }
    }
}