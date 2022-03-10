using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class ClassesMaintenanceFacts
    {
        public const string TopicName = "classes";
        const string CountryCode = "AF";
        const string PropertyType = "T";
        const string Class1 = "01";
        const string Class2 = "02";
        const string SubClass = "YYXXXXY";
        const string Heading = "Heading";
        const string Notes = "Notes";
        static readonly DateTime EffectiveDate = DateTime.Today;

        public class ClassesMaintenanceFixture : IFixture<ClassesMaintenance>
        {
            readonly InMemoryDbContext _db;

            public ClassesMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new ClassesMaintenance(db);
            }

            public ClassesMaintenance Subject { get; set; }

            public TmClass PrepareData()
            {
                var country = new CountryBuilder {Id = CountryCode}.Build().In(_db);
                var property = new PropertyTypeBuilder {Id = PropertyType}.Build().In(_db);
                return new TmClass(country.Id, Class1, property.Code).In(_db);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ShouldGiveDuplicateClassErrorOnValidate()
            {
                var f = new ClassesMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<ClassesMaintenanceModel>();

                delta.Added.Add(new ClassesMaintenanceModel {CountryId = CountryCode, Class = Class1, PropertyType = PropertyType});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Duplicate Class.");
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryClassNameNotProvided()
            {
                var f = new ClassesMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<ClassesMaintenanceModel>();

                delta.Added.Add(new ClassesMaintenanceModel {CountryId = CountryCode, PropertyType = "T"});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field was empty.");
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryPropertyTypeNotProvided()
            {
                var f = new ClassesMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<ClassesMaintenanceModel>();

                delta.Added.Add(new ClassesMaintenanceModel {CountryId = CountryCode, Class = "01"});

                var errors = f.Subject.Validate(delta).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field was empty.");
            }
        }

        public class SaveUpdateMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ShouldUpdateClasses(bool isPrimaryChanged)
            {
                var f = new ClassesMaintenanceFixture(Db);
                var tmClass = f.PrepareData();

                var delta = new Delta<ClassesMaintenanceModel>();
                delta.Updated.Add(new ClassesMaintenanceModel
                {
                    Id = tmClass.Id,
                    CountryId = tmClass.CountryCode,
                    PropertyType = tmClass.PropertyType,
                    Class = isPrimaryChanged ? "04" : tmClass.Class,
                    SubClass = SubClass,
                    Notes = Notes,
                    Description = Heading,
                    EffectiveDate = EffectiveDate
                });
                f.Subject.Save(delta);
                var countryClasses = isPrimaryChanged ? Db.Set<TmClass>().First(_ => _.Class == "04" && _.CountryCode == tmClass.CountryCode && _.PropertyType == tmClass.PropertyType) : Db.Set<TmClass>().First(_ => _.Id == tmClass.Id && _.CountryCode == tmClass.CountryCode);

                Assert.NotNull(countryClasses);

                Assert.Equal(CountryCode, countryClasses.CountryCode);
                Assert.Equal(PropertyType, countryClasses.PropertyType);
                Assert.Equal(Heading, countryClasses.Heading);
                Assert.Equal(Notes, countryClasses.Notes);
                Assert.Equal(0, countryClasses.SequenceNo);
                Assert.Equal(SubClass, countryClasses.SubClass);
                Assert.Equal(EffectiveDate, countryClasses.EffectiveDate);
                if (isPrimaryChanged)
                {
                    Assert.NotEqual(countryClasses.Id, tmClass.Id);
                    Assert.Equal("04", countryClasses.Class);
                }
                else
                {
                    Assert.Equal(countryClasses.Id, tmClass.Id);
                    Assert.Equal(Class1, countryClasses.Class);
                }
            }

            [Fact]
            public void ShouldAddClasses()
            {
                var f = new ClassesMaintenanceFixture(Db);
                f.PrepareData();
                var delta = new Delta<ClassesMaintenanceModel>();
                delta.Added.Add(new ClassesMaintenanceModel
                {
                    CountryId = CountryCode,
                    PropertyType = PropertyType,
                    Class = Class2,
                    SubClass = SubClass,
                    Notes = Notes,
                    Description = Heading,
                    EffectiveDate = EffectiveDate
                });
                f.Subject.Save(delta);

                var totalTableClasses = Db.Set<TmClass>().Where(_ => _.CountryCode == CountryCode).ToList();
                Assert.Equal(2, totalTableClasses.Count);

                var countryClasses = Db.Set<TmClass>().First(_ => _.Class == Class2 && _.CountryCode == CountryCode);

                Assert.Equal(CountryCode, countryClasses.CountryCode);
                Assert.Equal(Class2, countryClasses.Class);
                Assert.Equal(0, countryClasses.SequenceNo);
                Assert.Equal(PropertyType, countryClasses.PropertyType);
                Assert.Equal(Heading, countryClasses.Heading);
                Assert.Equal(Notes, countryClasses.Notes);
                Assert.Equal(SubClass, countryClasses.SubClass);
                Assert.Equal(EffectiveDate, countryClasses.EffectiveDate);
            }

            [Fact]
            public void ShouldAddClassesAndIncrementSequence()
            {
                var f = new ClassesMaintenanceFixture(Db);
                var subClass = "XXX";
                f.PrepareData();
                var delta = new Delta<ClassesMaintenanceModel>();
                delta.Added.Add(new ClassesMaintenanceModel
                {
                    CountryId = CountryCode,
                    PropertyType = PropertyType,
                    Class = Class1,
                    SubClass = subClass
                });
                f.Subject.Save(delta);

                var totalTableClasses = Db.Set<TmClass>().Where(_ => _.CountryCode == CountryCode).ToList();
                Assert.Equal(2, totalTableClasses.Count);

                var countryClasses = Db.Set<TmClass>().FirstOrDefault(_ => _.Class == Class1 && _.SubClass == subClass);

                Assert.NotNull(countryClasses);
                Assert.Equal(1, countryClasses.SequenceNo);
            }

            [Fact]
            public void ShouldDeleteExistingClasses()
            {
                var f = new ClassesMaintenanceFixture(Db);
                var tmClass = f.PrepareData();

                var delta = new Delta<ClassesMaintenanceModel>();
                delta.Deleted.Add(new ClassesMaintenanceModel {Id = tmClass.Id, CountryId = tmClass.CountryCode});
                f.Subject.Save(delta);

                var totalTableClasses = Db.Set<TmClass>().ToList();
                Assert.Empty(totalTableClasses);
            }
        }
    }
}