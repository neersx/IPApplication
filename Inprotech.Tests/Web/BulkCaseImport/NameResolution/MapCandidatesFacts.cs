using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.BulkCaseImport.NameResolution;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.BulkCaseImport;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.Extensions;
using InprotechKaizen.Model.Ede;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport.NameResolution
{
    public class MapCandidatesFacts : FactBase
    {
        public MapCandidatesFacts()
        {
            _fixture = new MapCandidatesFixture(Db);
        }

        readonly MapCandidatesFixture _fixture;

        public class MapCandidatesFixture : IFixture<IMapCandidates>
        {
            public MapCandidatesFixture(InMemoryDbContext db)
            {
                var siteConfiguration = Substitute.For<ISiteConfiguration>();
                PotentialNameMatches = Substitute.For<IPotentialNameMatches>();

                siteConfiguration.HomeCountry().Returns(new CountryBuilder
                {
                    Id = "AU",
                    Name = "Australia"
                }.Build().In(db));

                Subject = new MapCandidates(db, PotentialNameMatches, siteConfiguration);
            }

            public IPotentialNameMatches PotentialNameMatches { get; set; }

            public IMapCandidates Subject { get; }

            public MapCandidatesFixture WithSqlResults(PotentialNameMatchItem[] results)
            {
                PotentialNameMatches.For(null, null, null, null, null, null)
                                    .ReturnsForAnyArgs(results ?? Enumerable.Empty<PotentialNameMatchItem>());
                return this;
            }
        }

        [Theory]
        [InlineData(true, "NT")]
        [InlineData(false, null)]
        public void PassesNameTypeWhenRestricted(bool restricted, string expectedResult)
        {
            new NameType(1, "NT", "NameType")
            {
                PickListFlags = restricted ? KnownNameTypeAllowedFlags.SameNameType : (short) 0
            }.In(Db);
            var n1 = new NameBuilder(Db).Build().In(Db);

            _fixture.WithSqlResults(new[]
            {
                new PotentialNameMatchItem
                {
                    NameNo = n1.Id
                }
            });
            var unresolvedName = new EdeUnresolvedName
            {
                Name = "a",
                NameType = "NT"
            };

            var _ = _fixture.Subject.For(unresolvedName).ToArray();

            _fixture.PotentialNameMatches.Received(1)
                    .For(unresolvedName.Name, null, null, false, true, expectedResult);
        }

        [Fact]
        public void ReturnsFormattedPostalAddressByDefault()
        {
            var a1 = new AddressBuilder().Build().In(Db);
            var n1 = new NameBuilder(Db) {PostalAddress = a1}.Build().In(Db);
            n1.Addresses.First().AddressType = (int) AddressType.Postal;

            _fixture.WithSqlResults(new[]
            {
                new PotentialNameMatchItem
                {
                    NameNo = n1.Id
                }
            });
            var unresolvedName = new EdeUnresolvedName
            {
                Name = "b"
            };
            var result = _fixture.Subject.For(unresolvedName).ToArray();

            Assert.Equal(a1.Formatted(), result[0].FormattedAddress);
        }

        [Fact]
        public void ReturnsMappedCandidateDetails()
        {
            var phone =
                new TelecommunicationBuilder {AreaCode = "1", Extension = "2", Isd = "3", TelecomNumber = "4"}.Build();
            var fax =
                new TelecommunicationBuilder {AreaCode = "11", Extension = "2222", Isd = "33", TelecomNumber = "4444"}
                    .Build();
            var email = new TelecommunicationBuilder {TelecomNumber = "someone@someblah.com"}.Build();
            var mainContact = new NameBuilder(Db).Build();
            var n1 = new NameBuilder(Db) {Phone = phone, Fax = fax, Email = email, MainContact = mainContact, Remarks = "R1"}.Build().In(Db);
            var n2 = new NameBuilder(Db).Build().In(Db);

            _fixture.WithSqlResults(new[]
            {
                new PotentialNameMatchItem
                {
                    NameNo = n1.Id,
                    NameCode = "ABC",
                    FirstName = "DEF",
                    Name = "GHI",
                    SearchKey1 = "SK1"
                },
                new PotentialNameMatchItem
                {
                    NameNo = n2.Id,
                    NameCode = "ABC2"
                }
            });

            var unresolvedName = new EdeUnresolvedName
            {
                FirstName = "a",
                Name = "b"
            };

            var result = _fixture.Subject.For(unresolvedName).ToArray();

            Assert.Equal(n1.Id, result[0].Id);
            Assert.Equal("ABC", result[0].NameCode);
            Assert.Equal("DEF", result[0].FirstName);
            Assert.Equal("GHI", result[0].Name);
            Assert.Equal("SK1", result[0].SearchKey1);
            Assert.Equal("R1", result[0].Remarks);
            Assert.Equal("GHI, DEF", result[0].FormattedName);
            Assert.Equal("+3 1 4 x2", result[0].Phone);
            Assert.Equal("+33 11 4444 x2222", result[0].Fax);
            Assert.Equal("someone@someblah.com", result[0].Email);
            Assert.Equal(mainContact.Formatted(), result[0].Contact);

            Assert.Equal(n2.Id, result[1].Id);
            Assert.Equal("ABC2", result[1].NameCode);
        }

        [Fact]
        public void ReturnsSpecifiedCandidateDetails()
        {
            var mainContact = new NameBuilder(Db).Build();
            var candidateSpecified = new NameBuilder(Db)
            {
                NameCode = "ABC",
                FirstName = "DEF",
                LastName = "GHI",
                SearchKey1 = "SK1",
                Remarks = "R1",
                Phone = new TelecommunicationBuilder {TelecomNumber = "123"}.Build(),
                Fax = new TelecommunicationBuilder {TelecomNumber = "456"}.Build(),
                Email = new TelecommunicationBuilder {TelecomNumber = "a@b.com"}.Build(),
                MainContact = mainContact
            }.Build().In(Db);

            var unresolvedName = new EdeUnresolvedName
            {
                FirstName = "a",
                Name = "b"
            };

            var result = _fixture.Subject.For(unresolvedName, candidateSpecified.Id).ToArray();

            Assert.Equal("ABC", result[0].NameCode);
            Assert.Equal("DEF", result[0].FirstName);
            Assert.Equal("GHI", result[0].Name);
            Assert.Equal("SK1", result[0].SearchKey1);
            Assert.Equal("R1", result[0].Remarks);
            Assert.Equal("GHI, DEF", result[0].FormattedName);
            Assert.Equal("123", result[0].Phone);
            Assert.Equal("456", result[0].Fax);
            Assert.Equal("a@b.com", result[0].Email);
            Assert.Equal(mainContact.Formatted(), result[0].Contact);

            Assert.Single(result);
        }

        [Fact]
        public void ReturnsStreetAddressWhenKeepStreetFlag()
        {
            new NameType(1, "NT", "NameType")
            {
                KeepStreetFlag = 1
            }.In(Db);
            var pa = new AddressBuilder().Build().In(Db);
            var sa = new AddressBuilder().Build().In(Db);
            var n1 = new NameBuilder(Db) {PostalAddress = pa, StreetAddress = sa}.Build().In(Db);
            n1.Addresses.Last().AddressType = (int) AddressType.Street;

            _fixture.WithSqlResults(new[]
            {
                new PotentialNameMatchItem
                {
                    NameNo = n1.Id
                }
            });
            var unresolvedName = new EdeUnresolvedName
            {
                Name = "a",
                NameType = "NT"
            };

            var result = _fixture.Subject.For(unresolvedName).ToArray();

            Assert.Equal(sa.Formatted(), result[0].FormattedAddress);
        }
    }
}