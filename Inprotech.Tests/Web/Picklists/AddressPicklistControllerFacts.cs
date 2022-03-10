using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class AddressPicklistControllerFacts : FactBase
    {
        public class GetDataMethod : FactBase
        {
            [Fact]
            public async Task GetsAllAssociatedNameAddresses()
            {
                var nameAddress = new NameAddressBuilder(Db).Build().In(Db);
                new NameAddressBuilder(Db).Build().In(Db);
                new NameAddressBuilder(Db).Build().In(Db);
                new NameAddressBuilder(Db).Build().In(Db);
                
                var f = new AddressPicklistControllerFixture(Db);
                var addresses = new Dictionary<int, AddressFormatted> {{nameAddress.AddressId, new AddressFormatted {Id = nameAddress.AddressId, Address = nameAddress.Address.Formatted()}}};
                f.NameAddressFormatter.GetAddressesFormatted(Arg.Any<int[]>()).Returns(addresses);

                var result = await f.Subject.GetData(null, nameAddress.NameId);
                var data = result.ToArray();

                Assert.Equal(1, data.Length);
                Assert.True(data.Any(v => v.Address.Contains(nameAddress.Address.Country.Name)));
            }

            [Fact]
            public async Task GetAddressMatchingSearch()
            {
                var name = new NameBuilder(Db).Build();
                var na1 = new NameAddressBuilder(Db) {Name = name}.Build().In(Db);
                var na2 = new NameAddressBuilder(Db) {Name = name}.Build().In(Db);
                var na3 = new NameAddressBuilder(Db) {Name = name}.Build().In(Db);
                var na4 = new NameAddressBuilder(Db) {Name = name}.Build().In(Db);
                
                var f = new AddressPicklistControllerFixture(Db);
                var addresses = new Dictionary<int, AddressFormatted>
                {
                    {na1.AddressId, new AddressFormatted {Id = na1.AddressId, Address = na1.Address.Formatted()}},
                    {na2.AddressId, new AddressFormatted {Id = na2.AddressId, Address = na2.Address.Formatted()}},
                    {na3.AddressId, new AddressFormatted {Id = na3.AddressId, Address = na3.Address.Formatted()}},
                    {na4.AddressId, new AddressFormatted {Id = na4.AddressId, Address = na4.Address.Formatted()}}
                };
                f.NameAddressFormatter.GetAddressesFormatted(Arg.Any<int[]>()).Returns(addresses);

                var result = await f.Subject.GetData(na1.Address.Country.Name, name.Id);
                var data = result.ToArray();

                Assert.Equal(1, data.Length);
                Assert.True(data.Any(v => v.Address.Contains(na1.Address.Country.Name)));
            }

            [Fact]
            public async Task GetNoAddressWhenNoMatches()
            {
                new NameAddressBuilder(Db).Build().In(Db);
                new NameAddressBuilder(Db).Build().In(Db);
                new NameAddressBuilder(Db).Build().In(Db);
                new NameAddressBuilder(Db).Build().In(Db);
                
                var f = new AddressPicklistControllerFixture(Db);

                var result = await f.Subject.GetData(null, Fixture.Integer());
                var data = result.ToArray();

                Assert.Equal(0, data.Length);
            }
        }
    }

    public class AddressPicklistControllerFixture : IFixture<AddressPicklistController>
    {
        public AddressPicklistControllerFixture(InMemoryDbContext db)
        {
            CommonQueryService = Substitute.For<ICommonQueryService>();
            CommonQueryParameters = CommonQueryParameters.Default;
            NameAddressFormatter = Substitute.For<IFormattedNameAddressTelecom>();
            Subject = new AddressPicklistController(db, CommonQueryService, NameAddressFormatter);
        }
        public ICommonQueryService CommonQueryService { get; set; }
        public CommonQueryParameters CommonQueryParameters { get; set; }
        public IFormattedNameAddressTelecom NameAddressFormatter { get; set; }
        public AddressPicklistController Subject { get; }
    }
}
