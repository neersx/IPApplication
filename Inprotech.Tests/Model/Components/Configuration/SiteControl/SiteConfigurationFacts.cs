using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Common;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.SiteControl
{
    public class SiteConfigurationFacts
    {
        public class HomeNameMethod : FactBase
        {
            [Fact]
            public void ReturnsHomeName()
            {
                var name = new InprotechKaizen.Model.Names.Name().In(Db);

                new SiteControlBuilder
                    {
                        SiteControlId = SiteControls.HomeNameNo,
                        IntegerValue = name.Id
                    }
                    .Build()
                    .In(Db);

                var r = new SiteConfiguration(Db).HomeName();

                Assert.Equal(name, r);
            }
        }

        public class HomeCountryMethod : FactBase
        {
            [Fact]
            public void ReturnsHomeCountry()
            {
                var country = new CountryBuilder().Build().In(Db);

                new SiteControlBuilder
                    {
                        SiteControlId = SiteControls.HOMECOUNTRY,
                        StringValue = country.Id
                    }
                    .Build()
                    .In(Db);

                var r = new SiteConfiguration(Db).HomeCountry();

                Assert.Equal(country, r);
            }
        }

        public class ProductSupportEmail : FactBase
        {
            [Fact]
            public void ReturnProductSupportEmail()
            {
                var email = Fixture.String();

                new SiteControlBuilder
                    {
                        SiteControlId = SiteControls.ProductSupportEmail,
                        StringValue = email
                    }
                    .Build()
                    .In(Db);

                var r = new SiteConfiguration(Db).ProductSupportEmail;

                Assert.Equal(email, r);
            }
        }
    }
}