using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Offices;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;
using Office = InprotechKaizen.Model.Cases.Office;

namespace Inprotech.Tests.Web.Configuration.Offices
{
    public class OfficesFacts
    {
        public class OfficesFixture : IFixture<Inprotech.Web.Configuration.Offices.Offices>
        {
            public OfficesFixture(InMemoryDbContext db)
            {
                CultureResolver = Substitute.For<IPreferredCultureResolver>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

                Subject = new Inprotech.Web.Configuration.Offices.Offices(db, CultureResolver, DisplayFormattedName, SiteControlReader, LastInternalCodeGenerator);
            }

            public ISiteControlReader SiteControlReader { get; set; }
            public IPreferredCultureResolver CultureResolver { get; set; }
            public IDisplayFormattedName DisplayFormattedName { get; set; }
            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }
            public Inprotech.Web.Configuration.Offices.Offices Subject { get; set; }
        }

        public class GetOffices : FactBase
        {
            [Fact]
            public async Task ReturnEmptyResultSetWhenNoData()
            {
                var f = new OfficesFixture(Db);
                var results = (await f.Subject.GetOffices(string.Empty)).ToArray();
                Assert.Empty(results);
            }

            [Fact]
            public async Task ReturnsAllKotCaseTextTypes()
            {
                var f = new OfficesFixture(Db);
                var n1 = new NameBuilder(Db).Build().In(Db);
                var t1 = new TableCodeBuilder().Build().In(Db);
                var c1 = new CountryBuilder().Build().In(Db);
                var o1 = new OfficeBuilder {Name = "ABC"}.Build().In(Db);
                var o2 = new OfficeBuilder {Name = "DEF"}.Build().In(Db);
                o1.Organisation = n1;
                o1.DefaultLanguage = t1;
                o1.Country = c1;

                var results = (await f.Subject.GetOffices(string.Empty)).ToArray();

                Assert.Equal(2, results.Length);
                Assert.Equal(o1.Id, results[0].Key);
                Assert.True(results[0].Organisation.Contains(n1.FirstName));
                Assert.Equal(c1.Name, results[0].Country);
                Assert.Equal(t1.Name, results[0].DefaultLanguage);

                //Filtered Office
                results = (await f.Subject.GetOffices("DE")).ToArray();

                Assert.Equal(1, results.Length);
                Assert.Equal(o2.Id, results[0].Key);
                Assert.Equal(o2.Name, results[0].Value);
            }
        }

        public class GetOfficeDetail : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenIdDoesNotExist()
            {
                var f = new OfficesFixture(Db);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetOffice(Fixture.Integer()));
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsAllKotCaseTextTypes()
            {
                var f = new OfficesFixture(Db);
                var n1 = new NameBuilder(Db).Build().In(Db);
                var t1 = new TableCodeBuilder().Build().In(Db);
                var c1 = new CountryBuilder().Build().In(Db);
                var o1 = new OfficeBuilder {Name = "ABC"}.Build().In(Db);
                o1.OrganisationId = n1.Id;
                o1.Organisation = n1;
                o1.LanguageCode = t1.Id;
                o1.DefaultLanguage = t1;
                o1.CountryCode = c1.Id;
                o1.Country = c1;
                o1.CpaCode = Fixture.String();
                o1.IrnCode = Fixture.String();
                o1.PrinterCode = Fixture.Integer();
                o1.RegionCode = Fixture.Integer();
                o1.ItemNoPrefix = "ER";
                o1.ItemNoFrom = 1;
                o1.ItemNoTo = 100;

                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        n1.Id, new NameFormatted {Name = $"Formatted, ABC"}
                    }
                };

                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);

                var office = await f.Subject.GetOffice(o1.Id);
                Assert.Equal(o1.Id, office.Id);
                Assert.Equal(o1.Name, office.Description);
                Assert.Equal(formatted[n1.Id].Name, office.Organization.DisplayName);
                Assert.Equal(o1.Country.Name, office.Country.Value);
                Assert.Equal(o1.DefaultLanguage.Name, office.Language.Value);
                Assert.Equal(o1.UserCode, office.UserCode);
                Assert.Equal(o1.CpaCode, office.CpaCode);
                Assert.Equal(o1.ItemNoPrefix, office.ItemNoPrefix);
                Assert.Equal(o1.ItemNoFrom, office.ItemNoFrom);
                Assert.Equal(o1.ItemNoTo, office.ItemNoTo);
                Assert.Equal(o1.PrinterCode, office.PrinterCode);
                Assert.Equal(o1.RegionCode, office.RegionCode);
            }
        }

        public class GetAllPrinters : FactBase
        {
            [Fact]
            public async Task ReturnAllPrinters()
            {
                var f = new OfficesFixture(Db);
                new Device {Id = Fixture.Integer(), Name = Fixture.String("A"), Type = 0}.In(Db);
                new Device {Id = Fixture.Integer(), Name = Fixture.String("B"), Type = 1}.In(Db);
                new Device {Id = Fixture.Integer(), Name = Fixture.String("C"), Type = 0}.In(Db);

                var printers = (await f.Subject.GetAllPrinters()).ToArray();
                Assert.Equal(2, printers.Length);
                Assert.True( printers[0].Value.StartsWith("A"));
                Assert.True( printers[1].Value.StartsWith("C"));
            }
        }

        public class Delete : FactBase
        {
            [Fact]
            public async Task ShouldThrowErrorWhenIdNotExist()
            {
                var f = new OfficesFixture(Db);
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () =>
                {
                    await f.Subject.Delete(new DeleteRequestModel());
                });
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldDeleteOffice()
            {
                var f = new OfficesFixture(Db);
                var o1 = new OfficeBuilder {Name = "ABC"}.Build().In(Db);

                var result = await f.Subject.Delete(new DeleteRequestModel {Ids = new List<int> {o1.Id}});
                Assert.False(result.HasError);
            }

            [Fact]
            public async Task ShouldShowErrorWhenInUse()
            {
                var f = new OfficesFixture(Db);
                var o1 = new OfficeBuilder {Name = "ABC"}.Build().In(Db);
                new TableAttributes {SourceTableId = (short) TableTypes.Office, TableCodeId = o1.Id, ParentTable = "NAME"}.In(Db);

                var result = await f.Subject.Delete(new DeleteRequestModel {Ids = new List<int> {o1.Id}});
                Assert.True(result.HasError);
                Assert.True(result.InUseIds.Contains(o1.Id) );
                Assert.Equal(ConfigurationResources.InUseErrorMessage, result.Message);
            }
        }

        public class SaveOffice : FactBase
        {
            [Fact]
            public async Task ShouldEditOffice()
            {
                var f = new OfficesFixture(Db);

                var n1 = new NameBuilder(Db).Build().In(Db);
                var t1 = new TableCodeBuilder().Build().In(Db);
                var c1 = new CountryBuilder().Build().In(Db);
                var o1 = new OfficeBuilder {Name = "ABC"}.Build().In(Db);
                
                var request = new OfficeData
                {
                    Id = o1.Id,
                    Description = Fixture.String(),
                    Country = new Jurisdiction {Code = c1.Id, Value = c1.Name},
                    CpaCode = Fixture.String(),
                    Language = new TableCodePicklistController.TableCodePicklistItem {Key = t1.Id, Value = t1.Name},
                    Organization = new Inprotech.Web.Picklists.Name {Key = n1.Id},
                    IrnCode = Fixture.String(),
                    PrinterCode = Fixture.Integer(),
                    ItemNoPrefix = "ER",
                    ItemNoFrom = 1,
                    ItemNoTo = 100
                };

                var result = await f.Subject.SaveOffice(request);
                Assert.Equal(o1.Id, result.Id);
                Assert.Equal(request.Description, o1.Name);
                Assert.Equal(request.CpaCode, o1.CpaCode);
                Assert.Equal(request.Country.Code, o1.CountryCode);
                Assert.Equal(request.Organization.Key, o1.OrganisationId);
                Assert.Equal(request.PrinterCode, o1.PrinterCode);
                Assert.Equal(request.Language.Key, o1.LanguageCode);
                Assert.Equal(request.ItemNoPrefix, o1.ItemNoPrefix);
                Assert.Equal(request.ItemNoFrom, o1.ItemNoFrom);
                Assert.Equal(request.ItemNoTo, o1.ItemNoTo);
            }

            [Fact]
            public async Task ShouldThrowValidationErrorWhenDescriptionExists()
            {
                var f = new OfficesFixture(Db);

                var o1 = new OfficeBuilder {Name = "ABC"}.Build().In(Db);
                
                var request = new OfficeData
                {
                    Description = o1.Name
                };

                var result = await f.Subject.SaveOffice(request);
                Assert.Equal("description", result.Errors.First().Field);
                Assert.Equal("duplicateOffice", result.Errors.First().Message);
            }

            [Fact]
            public async Task ShouldThrowValidationErrorWhenItemNoPrefixIsDuplicate()
            {
                var f = new OfficesFixture(Db);
                var o1 = new OfficeBuilder {Name = "ABC"}.Build().In(Db);
                o1.ItemNoPrefix = "DR";
                
                var request = new OfficeData
                {
                    Description = Fixture.String(),
                    ItemNoPrefix = "DR"
                };

                var result = await f.Subject.SaveOffice(request);
                Assert.Equal("itemPrefix", result.Errors.First().Field);
                Assert.Equal("duplicateItemPrefix", result.Errors.First().Message);

                f.SiteControlReader.Read<string>(SiteControls.DRAFTPREFIX).Returns("DR");
                o1.ItemNoPrefix = "ER";
                result = await f.Subject.SaveOffice(request);
                Assert.Equal("itemPrefix", result.Errors.First().Field);
            }

            [Fact]
            public async Task ShouldThrowValidationErrorWhenItemNos()
            {
                var f = new OfficesFixture(Db);
                new OpenItem {OpenItemNo = "DR10"}.In(Db);
                
                var request = new OfficeData
                {
                    Description = Fixture.String(),
                    ItemNoPrefix = "DR",
                    ItemNoTo = 8,
                    ItemNoFrom = 1
                };

                var result = await f.Subject.SaveOffice(request);
                Assert.Equal("itemTo", result.Errors.First().Field);
                Assert.Equal("duplicateItemNo", result.Errors.First().Message);
            }

            [Fact]
            public async Task ShouldAddOffice()
            {
                var f = new OfficesFixture(Db);

                var n1 = new NameBuilder(Db).Build().In(Db);
                var t1 = new TableCodeBuilder().Build().In(Db);
                var c1 = new CountryBuilder().Build().In(Db);
                
                var request = new OfficeData
                {
                    Description = Fixture.String(),
                    Country = new Jurisdiction {Code = c1.Id, Value = c1.Name},
                    CpaCode = Fixture.String(),
                    Language = new TableCodePicklistController.TableCodePicklistItem {Key = t1.Id, Value = t1.Name},
                    Organization = new Inprotech.Web.Picklists.Name {Key = n1.Id},
                    IrnCode = Fixture.String(),
                    PrinterCode = Fixture.Integer(),
                    ItemNoPrefix = "ER",
                    ItemNoFrom = 1,
                    ItemNoTo = 100
                };
                var officeId = Fixture.Integer();
                f.LastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Office).Returns(officeId);

                var result = await f.Subject.SaveOffice(request);
                var o1 = Db.Set<Office>().First(_ => _.Id == result.Id);
                Assert.Equal(request.Description, o1.Name);
                Assert.Equal(request.CpaCode, o1.CpaCode);
                Assert.Equal(request.Country.Code, o1.CountryCode);
                Assert.Equal(request.Organization.Key, o1.OrganisationId);
                Assert.Equal(request.PrinterCode, o1.PrinterCode);
                Assert.Equal(request.Language.Key, o1.LanguageCode);
                Assert.Equal(request.ItemNoPrefix, o1.ItemNoPrefix);
                Assert.Equal(request.ItemNoFrom, o1.ItemNoFrom);
                Assert.Equal(request.ItemNoTo, o1.ItemNoTo);
            }
        }
    }
}
