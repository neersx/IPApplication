using System;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class CaseNameAddressResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            [Fact]
            public void DefaultsCountryFromHomeCountry()
            {
                var address = new AddressBuilder
                {
                    City = "Sydney",
                    Street1 = "York Street",
                    PostCode = "2000"
                }.Build().In(Db);

                address.Country = null;

                var caseName = new CaseNameBuilder(Db)
                {
                    Address = address
                }.Build().In(Db);

                var f = new CaseNameAddressResolverFixture()
                    .WithHomeCountry(new CountryBuilder
                    {
                        Name = "Australia"
                    }.Build());

                var r = f.Subject.Resolve(caseName);

                Assert.Equal(@"York Street Sydney 2000 Australia", r.FormattedAddress.Replace(Environment.NewLine, " "));
                Assert.False(r.IsInherited);
            }

            [Fact]
            public void ResolvesAddressHeldAgainstCaseName()
            {
                var address = new AddressBuilder
                {
                    City = "Sydney",
                    Street1 = "York Street",
                    PostCode = "2000",
                    Country = new CountryBuilder
                    {
                        Name = "Australia"
                    }.Build()
                }.Build().In(Db);

                var caseName = new CaseNameBuilder(Db)
                {
                    Address = address
                }.Build().In(Db);

                var f = new CaseNameAddressResolverFixture();
                var r = f.Subject.Resolve(caseName);

                Assert.Equal(@"York Street Sydney 2000 Australia", r.FormattedAddress.Replace(Environment.NewLine, " "));
                Assert.False(r.IsInherited);
            }

            [Fact]
            public void ResolvesAddressHeldAgainstName()
            {
                var address = new AddressBuilder
                {
                    City = "Sydney",
                    Street1 = "York Street",
                    PostCode = "2000",
                    Country = new CountryBuilder
                    {
                        Name = "Australia"
                    }.Build()
                }.Build().In(Db);

                var caseName = new CaseNameBuilder(Db)
                {
                    Name = new NameBuilder(Db)
                    {
                        PostalAddress = address
                    }.Build().In(Db)
                }.Build().In(Db);

                var f = new CaseNameAddressResolverFixture();
                var r = f.Subject.Resolve(caseName);

                Assert.Equal(@"York Street Sydney 2000 Australia", r.FormattedAddress.Replace(Environment.NewLine, " "));
                Assert.True(r.IsInherited);
            }
        }

        public class CaseNameAddressResolverFixture : IFixture<CaseNameAddressResolver>
        {
            public CaseNameAddressResolverFixture()
            {
                SiteConfiguration = Substitute.For<ISiteConfiguration>();

                Subject = new CaseNameAddressResolver(SiteConfiguration);
            }

            public ISiteConfiguration SiteConfiguration { get; set; }

            public CaseNameAddressResolver Subject { get; set; }

            public CaseNameAddressResolverFixture WithHomeCountry(Country country)
            {
                SiteConfiguration.HomeCountry().Returns(country);

                return this;
            }
        }
    }
}