using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class AttributesMaintenanceFacts
    {
        public class AttributesMaintenanceFixture : IFixture<AttributesMaintenance>
        {
            readonly InMemoryDbContext _db;

            public AttributesMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new AttributesMaintenance(db);
            }

            public AttributesMaintenance Subject { get; set; }

            public dynamic PrepareData()
            {
                const string topicName = "attributes";
                const string countryCode = "AF";

                var tableType = new TableTypeBuilder(_db).BuildWithTableCodes().In(_db);
                var existingTableCode = tableType.TableCodes.First();
                var newTableCodes = tableType.TableCodes.Last();
                var existingTableAttributes = new TableAttributes(KnownTableAttributes.Country, countryCode)
                {
                    SourceTableId = tableType.Id,
                    TableCodeId = existingTableCode.Id
                }.WithKnownId(1).In(_db);

                return new
                {
                    TopicName = topicName,
                    CountryCode = countryCode,
                    ExistingTableType = tableType,
                    ExistingTableCodes = existingTableCode,
                    NewTableCodes = newTableCodes,
                    ExistingTableAttributes = existingTableAttributes
                };
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void DoesNotAllowAddingDuplicate()
            {
                var f = new AttributesMaintenanceFixture(Db);
                var data = f.PrepareData();
                var delta = new Delta<AttributesMaintenanceModel>();

                delta.Added.Add(new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = data.ExistingTableCodes.Id});

                var errors = f.Subject.Validate(delta, new List<AttributesMaintenanceModel>()).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == data.TopicName);
                Assert.Contains(errors, v => v.Message == ConfigurationResources.DuplicateJurisdictionAttribute);
            }

            [Fact]
            public void ShouldGiveMaxAttributesErrorOnValidate()
            {
                var f = new AttributesMaintenanceFixture(Db);
                var data = f.PrepareData();
                var delta = new Delta<AttributesMaintenanceModel>();
                var attributes = new List<AttributesMaintenanceModel>();

                new SelectionTypes(data.ExistingTableType) {ParentTable = KnownTableAttributes.Country, MinimumAllowed = 0, MaximumAllowed = 1}.In(Db);

                var model = new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = 3};
                attributes.Add(model);
                attributes.Add(new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = data.ExistingTableCodes.Id});
                delta.Added.Add(new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = 3});

                var errors = f.Subject.Validate(delta, attributes).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == data.TopicName);
                Assert.Contains(errors, v => v.Message.Contains("Maximum"));
            }

            [Fact]
            public void ShouldGiveMinAttributesErrorOnValidate()
            {
                var f = new AttributesMaintenanceFixture(Db);
                var data = f.PrepareData();
                var delta = new Delta<AttributesMaintenanceModel>();
                var attributes = new List<AttributesMaintenanceModel>();

                new SelectionTypes(new TableType()) {ParentTable = KnownTableAttributes.Country, MinimumAllowed = 1, MaximumAllowed = 3}.In(Db);

                var model = new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = 3};
                attributes.Add(model);
                delta.Added.Add(new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = 3});

                var errors = f.Subject.Validate(delta, attributes).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == data.TopicName);
                Assert.Contains(errors, v => v.Message.Contains("Minimum"));
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryFieldDoesNotProvided()
            {
                var f = new AttributesMaintenanceFixture(Db);
                var data = f.PrepareData();
                var delta = new Delta<AttributesMaintenanceModel>();

                delta.Added.Add(new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = null});

                var errors = f.Subject.Validate(delta, new List<AttributesMaintenanceModel>()).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == data.TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field was empty.");
            }
        }

        public class SaveUpdateMethod : FactBase
        {
            [Fact]
            public void ShouldAddAttributes()
            {
                var f = new AttributesMaintenanceFixture(Db);
                var data = f.PrepareData();
                string countryCode = data.CountryCode.ToString();
                short? typeId = data.ExistingTableType.Id;
                int? tableCode = data.NewTableCodes.Id;

                var delta = new Delta<AttributesMaintenanceModel>();
                delta.Added.Add(new AttributesMaintenanceModel {CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = data.NewTableCodes.Id});
                f.Subject.Save(delta);

                var totalTableAttributes = Db.Set<TableAttributes>().ToList();
                Assert.Equal(2, totalTableAttributes.Count);

                var tableAttributes = Db.Set<TableAttributes>().Where(_ => _.ParentTable == KnownTableAttributes.Country && _.GenericKey == countryCode && _.SourceTableId == typeId && _.TableCodeId == tableCode).ToArray();

                Assert.Single(tableAttributes);
                Assert.Equal(tableAttributes.Single().GenericKey, data.CountryCode);
                Assert.Equal(tableAttributes.Single().SourceTableId, data.ExistingTableType.Id);
                Assert.Equal(tableAttributes.Single().TableCodeId, data.NewTableCodes.Id);
            }

            [Fact]
            public void ShouldDeleteExistingAttributes()
            {
                var f = new AttributesMaintenanceFixture(Db);
                var data = f.PrepareData();

                var delta = new Delta<AttributesMaintenanceModel>();
                delta.Deleted.Add(new AttributesMaintenanceModel {Id = 1, CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = data.NewTableCodes.Id});
                f.Subject.Save(delta);

                var totalTableAttributes = Db.Set<TableAttributes>();
                Assert.Empty(totalTableAttributes);
            }

            [Fact]
            public void ShouldUpdateAttributes()
            {
                var f = new AttributesMaintenanceFixture(Db);
                var data = f.PrepareData();

                var delta = new Delta<AttributesMaintenanceModel>();
                delta.Updated.Add(new AttributesMaintenanceModel {Id = 1, CountryCode = data.CountryCode, TypeId = data.ExistingTableType.Id, ValueId = data.NewTableCodes.Id});
                f.Subject.Save(delta);

                var totalTableAttributes = Db.Set<TableAttributes>().ToList();
                Assert.Single(totalTableAttributes);
                Assert.Equal(totalTableAttributes.Single().GenericKey, data.CountryCode);
                Assert.Equal(totalTableAttributes.Single().SourceTableId, data.ExistingTableType.Id);
                Assert.Equal(totalTableAttributes.Single().TableCodeId, data.NewTableCodes.Id);
            }
        }
    }
}