using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Xunit;
using PropertyType = InprotechKaizen.Model.Cases.PropertyType;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class TextsMaintenanceFacts
    {
        public class TextsMaintenanceFixture : IFixture<TextsMaintenance>
        {
            readonly InMemoryDbContext _db;

            public TextsMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new TextsMaintenance(db);
            }

            public TextsMaintenance Subject { get; set; }

            public dynamic PrepareData()
            {
                const string countryCode = "AF";
                var textType = new TableCodeBuilder().For(TableTypes.TextType).Build().In(_db);
                var propertyType = new PropertyType(Fixture.String(), Fixture.String()).In(_db);

                var existingJurisdictionTexts = new CountryText(countryCode, textType, propertyType)
                {
                    Text = "UT Text",
                    SequenceId = 0
                }.In(_db);

                return new
                {
                    CountryCode = countryCode,
                    TextType = new TableCodePicklistController.TableCodePicklistItem
                    {
                        Key = existingJurisdictionTexts.TextType.Id,
                        Value = existingJurisdictionTexts.TextType.Name
                    },
                    PropertyType = new Inprotech.Web.Picklists.PropertyType
                    {
                        Key = existingJurisdictionTexts.Property.Id,
                        Value = existingJurisdictionTexts.Property.Name,
                        Code = existingJurisdictionTexts.Property.Code
                    }
                };
            }
        }

        public class ValidateMethod : FactBase
        {
            const string TopicName = "texts";

            [Fact]
            public void DoesNotAllowAddingDuplicate()
            {
                var f = new TextsMaintenanceFixture(Db);
                var data = f.PrepareData();
                var textsDelta = new Delta<TextsModel>();

                textsDelta.Added.Add(new TextsModel {CountryCode = data.CountryCode, TextType = data.TextType, PropertyType = data.PropertyType});

                var formData = new JurisdictionModel {Id = data.CountryCode, Name = Fixture.String(), Type = "0", TextsDelta = textsDelta};

                var errors = f.Subject.Validate(formData.TextsDelta).ToArray();

                Assert.True(errors.Length == 1);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == ConfigurationResources.DuplicateJurisdictionTexts);
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryFieldDoesNotProvided()
            {
                var f = new TextsMaintenanceFixture(Db);
                var data = f.PrepareData();
                var textsDelta = new Delta<TextsModel>();

                textsDelta.Added.Add(new TextsModel {CountryCode = data.CountryCode, TextType = null, PropertyType = data.PropertyType});

                var formData = new JurisdictionModel {Id = data.CountryCode, Name = Fixture.String(), Type = "0", TextsDelta = textsDelta};

                var errors = f.Subject.Validate(formData.TextsDelta).ToArray();

                Assert.True(errors.Length == 1);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Text type can not be blank.");
            }
        }

        public class SaveUpdateDeleteMethod : FactBase
        {
            [Fact]
            public void ShouldAddJurisdictionTexts()
            {
                var f = new TextsMaintenanceFixture(Db);
                var data = f.PrepareData();
                string countryCode = data.CountryCode;
                int textId = data.TextType.Key;

                var propertyType = new PropertyType(Fixture.String(), Fixture.String()).In(Db);

                var propertyTypePickList = new Inprotech.Web.Picklists.PropertyType
                {
                    Key = propertyType.Id,
                    Value = propertyType.Name,
                    Code = propertyType.Code
                };

                var textTypePickList = new TableCodePicklistController.TableCodePicklistItem
                {
                    Code = data.TextType.Code,
                    Key = data.TextType.Key,
                    Value = data.TextType.Value,
                    TypeId = (short) data.TextType.Key
                };

                var textsDelta = new Delta<TextsModel>();

                textsDelta.Added.Add(new TextsModel {CountryCode = data.CountryCode, TextType = textTypePickList, PropertyType = propertyTypePickList, Text = "Jurisdiction Text"});
                f.Subject.Save(textsDelta);

                var totalCountryTexts = Db.Set<CountryText>().ToList();
                Assert.Equal(2, totalCountryTexts.Count);

                var countryTexts = Db.Set<CountryText>().Where(_ => _.CountryId == countryCode && _.TextType.Id == textId && _.PropertyType == propertyType.Code).ToArray();

                Assert.Single(countryTexts);
                Assert.Equal(countryTexts.Single().CountryId, data.CountryCode);
                Assert.Equal(countryTexts.Single().PropertyType, propertyType.Code);
                Assert.Equal(countryTexts.Single().TextType.Id, textId);
            }

            [Fact]
            public void ShouldDeleteJurisdicitonTexts()
            {
                var f = new TextsMaintenanceFixture(Db);
                var data = f.PrepareData();

                var propertyType = new PropertyType(Fixture.String(), Fixture.String()).In(Db);

                var propertyTypePickList = new Inprotech.Web.Picklists.PropertyType
                {
                    Key = propertyType.Id,
                    Value = propertyType.Name,
                    Code = propertyType.Code
                };

                var textTypePickList = new TableCodePicklistController.TableCodePicklistItem
                {
                    Code = data.TextType.Code,
                    Key = data.TextType.Key,
                    Value = data.TextType.Value,
                    TypeId = (short) data.TextType.Key
                };

                var textsDelta = new Delta<TextsModel>();

                textsDelta.Deleted.Add(new TextsModel {CountryCode = data.CountryCode, TextType = textTypePickList, PropertyType = propertyTypePickList, SequenceId = 0});

                f.Subject.Save(textsDelta);

                var countryTexts = Db.Set<CountryText>();

                Assert.Empty(countryTexts);
            }

            [Fact]
            public void ShouldUpdateJurisdictionTexts()
            {
                var f = new TextsMaintenanceFixture(Db);
                var data = f.PrepareData();

                var propertyType = new PropertyType(Fixture.String(), Fixture.String()).In(Db);

                var propertyTypePickList = new Inprotech.Web.Picklists.PropertyType
                {
                    Key = propertyType.Id,
                    Value = propertyType.Name,
                    Code = propertyType.Code
                };

                var textTypePickList = new TableCodePicklistController.TableCodePicklistItem
                {
                    Code = data.TextType.Code,
                    Key = data.TextType.Key,
                    Value = data.TextType.Value,
                    TypeId = (short) data.TextType.Key
                };

                var textsDelta = new Delta<TextsModel>();

                textsDelta.Updated.Add(new TextsModel {CountryCode = data.CountryCode, TextType = textTypePickList, PropertyType = propertyTypePickList, Text = "Jurisdiction Text Updated", SequenceId = 0});
                f.Subject.Save(textsDelta);

                var countryTexts = Db.Set<CountryText>().First();

                Assert.Equal(countryTexts.CountryId, data.CountryCode);
                Assert.Equal(countryTexts.PropertyType, propertyType.Code);
                Assert.Equal("Jurisdiction Text Updated", countryTexts.Text);
            }
        }
    }
}