using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class OverviewMaintenanceFacts
    {
        public class OverviewMaintenanceFixture : IFixture<OverviewMaintenance>
        {
            public OverviewMaintenanceFixture(InMemoryDbContext db)
            {
                Subject = new OverviewMaintenance(db);
            }

            public OverviewMaintenance Subject { get; set; }
        }

        public class SaveMethod : FactBase
        {
            [Theory]
            [InlineData("0", true)]
            [InlineData("1", false)]
            [InlineData("2", false)]
            [InlineData("3", false)]
            public void AddsJurisdictionAndDefaultsNecessaryFields(string type, bool defaultsPostalName)
            {
                var countryCode = Fixture.String().Substring(0, 3);

                var f = new OverviewMaintenanceFixture(Db);
                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = type};

                f.Subject.Save(formData, Operation.Add);
                var newCountry = Db.Set<Country>().Single(v => v.Id == countryCode);

                Assert.Equal(countryCode, newCountry.Id);
                Assert.Equal(formData.Name, newCountry.Name);
                Assert.Equal(countryCode, newCountry.AlternateCode);
                Assert.Equal(formData.Name.Substring(0, 10), newCountry.Abbreviation);
                Assert.Equal(formData.Name, newCountry.InformalName);
                Assert.Equal(defaultsPostalName, newCountry.PostalName == formData.Name);
            }

            [Theory]
            [InlineData("0123456789A", "0123456789")]
            [InlineData("0123456789", "0123456789")]
            [InlineData("012345", "012345")]
            public void AddJurisdictionAndDefaultsAbbreviation(string name, string abbreviation)
            {
                const string countryCode = "VQ";

                var f = new OverviewMaintenanceFixture(Db);
                var formData = new JurisdictionModel {Id = countryCode, Name = name, Type = "0"};

                f.Subject.Save(formData, Operation.Add);
                var newCountry = Db.Set<Country>().Single(v => v.Id == countryCode);

                Assert.Equal(countryCode, newCountry.Id);
                Assert.Equal(formData.Name, newCountry.Name);
                Assert.Equal(formData.Name, newCountry.PostalName);
                Assert.Equal(abbreviation, newCountry.Abbreviation);
            }

            [Fact]
            public void AddJurisdictionAndDefaultsPostalNameForCountry()
            {
                const string countryCode = "VQ";

                var f = new OverviewMaintenanceFixture(Db);
                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0"};

                f.Subject.Save(formData, Operation.Add);
                var newCountry = Db.Set<Country>().Single(v => v.Id == countryCode);

                Assert.Equal(countryCode, newCountry.Id);
                Assert.Equal(formData.Name, newCountry.Name);
                Assert.Equal(formData.Name, newCountry.PostalName);
            }

            [Fact]
            public void AddJurisdictionWithAllMemberFlag()
            {
                const string countryCode = "VQ";

                var f = new OverviewMaintenanceFixture(Db);
                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0", AllMembersFlag = true};

                f.Subject.Save(formData, Operation.Add);
                var newCountry = Db.Set<Country>().Single(v => v.Id == countryCode);

                Assert.Equal(countryCode, newCountry.Id);
                Assert.Equal(formData.AllMembersFlag, newCountry.AllMembersFlag == 1);
            }

            [Fact]
            public void UpdateAddressSettingDetails()
            {
                const string countryCode = "BB";

                var f = new OverviewMaintenanceFixture(Db);
                var country = new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);
                var formData = new JurisdictionModel
                {
                    Id = country.Id,
                    StateLabel = "New Style",
                    PostCodeLiteral = "Postcode Label",
                    StateAbbreviated = true,
                    PostCodeFirst = false,
                    PostCodeAutoFlag = true,
                    NameStyle = new TableCodePicklistController.TableCodePicklistItem {Key = Fixture.Integer()},
                    AddressStyle = new TableCodePicklistController.TableCodePicklistItem {Key = Fixture.Integer()},
                    PopulateCityFromPostCode = new TableCodePicklistController.TableCodePicklistItem {Key = Fixture.Integer()}
                };

                f.Subject.Save(formData, Operation.Update);
                var updatedCountry = Db.Set<Country>().First(v => v.Id == countryCode);
                Assert.Equal(formData.StateAbbreviated, updatedCountry.StateAbbreviated == 1);
                Assert.Equal(formData.PostCodeFirst, updatedCountry.PostCodeFirst == 1);
                Assert.Equal(formData.PostCodeAutoFlag, updatedCountry.PostCodeAutoFlag == 1);
                Assert.Equal(formData.StateLabel, updatedCountry.StateLabel);
                Assert.Equal(formData.PostCodeLiteral, updatedCountry.PostCodeLiteral);
                Assert.Equal(formData.NameStyle.Key, updatedCountry.NameStyleId);
                Assert.Equal(formData.AddressStyle.Key, updatedCountry.AddressStyleId);
                Assert.Equal(formData.PopulateCityFromPostCode.Key, updatedCountry.PostCodeSearchCodeId);
            }

            [Fact]
            public void UpdateCommenceAndCeaseDates()
            {
                const string countryCode = "BB";

                var f = new OverviewMaintenanceFixture(Db);
                var country = new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);
                var formData = new JurisdictionModel {Id = country.Id, DateCommenced = Fixture.PastDate(), DateCeased = Fixture.PastDate()};

                f.Subject.Save(formData, Operation.Update);
                var updatedCountry = Db.Set<Country>().First(v => v.Id == countryCode);

                Assert.Equal(formData.DateCommenced, updatedCountry.DateCommenced);
                Assert.Equal(formData.DateCeased, updatedCountry.DateCeased);
            }

            [Fact]
            public void UpdateCountryDetails()
            {
                const string countryCode = "BB";

                var f = new OverviewMaintenanceFixture(Db);
                var country = new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);
                var formData = new JurisdictionModel {Id = country.Id, Notes = "New Notes", Name = "BBBQ", AllMembersFlag = true};

                f.Subject.Save(formData, Operation.Update);
                var updatedCountry = Db.Set<Country>().First(v => v.Id == countryCode);
                Assert.Equal(formData.Notes, updatedCountry.Notes);
                Assert.Equal(formData.Name, updatedCountry.Name);
                Assert.Equal(formData.AllMembersFlag, updatedCountry.AllMembersFlag == 1);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void MandatoryStyleShouldBePresentOnUpdate(bool nameStyleError)
            {
                const string countryCode = "BB";

                var f = new OverviewMaintenanceFixture(Db);
                new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);
                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0"};

                if (!nameStyleError)
                {
                    formData.NameStyle = new TableCodePicklistController.TableCodePicklistItem {Key = Fixture.Integer(), Value = Fixture.String()};
                }
                else
                {
                    formData.AddressStyle = new TableCodePicklistController.TableCodePicklistItem {Key = Fixture.Integer(), Value = Fixture.String()};
                }

                var errors = f.Subject.Validate(formData, Operation.Update).ToArray();

                Assert.Single(errors);
                Assert.True(nameStyleError ? errors.Any(v => v.Field == "nameStyle") : errors.Any(v => v.Field == "addressStyle"));
                Assert.Contains(errors, v => v.Message == "field.errors.required");
            }

            [Fact]
            public void DoesNotAllowAddingDuplicate()
            {
                const string countryCode = "BB";

                var f = new OverviewMaintenanceFixture(Db);
                new Country(countryCode, Fixture.String(countryCode), Fixture.String()).In(Db);
                var formData = new JurisdictionModel {Id = countryCode, Name = Fixture.String(), Type = "0"};

                var errors = f.Subject.Validate(formData, Operation.Add).ToArray();

                Assert.NotEmpty(errors);
                Assert.Contains(errors, v => v.Topic == "jurisdictions.maintenance.errors.duplicate");
            }
        }
    }
}