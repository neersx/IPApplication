using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class ImportanceLevelMaintenanceControllerFacts : FactBase
    {
        public class ImportanceLevelMaintenanceControllerFixture : IFixture<ImportanceLevelMaintenanceController>
        {
            public ImportanceLevelMaintenanceControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new ImportanceLevelMaintenanceController(DbContext);
            }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public InMemoryDbContext DbContext { get; }

            public ImportanceLevelMaintenanceController Subject { get; }

            public void PrepareData()
            {
                AddImportanceLevel("01", "Importance Level 1");
                AddImportanceLevel("02", "Importance Level 2");
                AddImportanceLevel("03", "Importance Level 3");
            }

            void AddImportanceLevel(string level, string description)
            {
                new Importance(level, description).In(DbContext);
            }
        }

        public class SearchMethod : FactBase
        {
            [Fact]
            public void ShouldReturnListOfImportanceLevelSortedByLevel()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var e = (IEnumerable<object>) f.Subject.Search();

                Assert.NotNull(e);
                Assert.Equal(e.Count(), f.DbContext.Set<Importance>().Count());
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldAddUpdateandDeleteImportanceLevelWithGivenDetails()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var saveDetails = new Delta<Importance>();
                saveDetails.Deleted.Add(new Importance {Level = "03"});
                saveDetails.Updated.Add(new Importance {Description = "Importance Level 2 Updated", Level = "02"});
                saveDetails.Added.Add(new Importance {Description = "Importance Level 4", Level = "04"});

                var result = f.Subject.Save(saveDetails);

                var importanceLevel =
                    Db.Set<Importance>().FirstOrDefault();

                Assert.NotNull(importanceLevel);
                Assert.Equal(result.ValidationErrors.Count, 0);
                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void ShouldCreateNewImportanceLevelWithGivenDetails()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                var saveDetails = new Delta<Importance>();
                saveDetails.Added.Add(new Importance {Description = "Importance Leval 1", Level = "01"});

                var result = f.Subject.Save(saveDetails);

                var importanceLevel =
                    Db.Set<Importance>().FirstOrDefault();

                Assert.NotNull(importanceLevel);
                Assert.Equal(result.ValidationErrors.Count, 0);
                Assert.Equal("success", result.Result);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenAddedImportanceLevelAlreadyExist()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var saveDetails = new Delta<Importance>();
                saveDetails.Added.Add(new Importance {Description = "Importance Level 1", Level = "01"});

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.ValidationErrors.Count, 2);
                Assert.Equal(result.ValidationErrors[0].Field, "level");
                Assert.Equal(result.Result, "error");
            }

            [Fact]
            public void ShouldReturnErrorResultWhenImportanceLevelIsBlank()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var saveDetails = new Delta<Importance>();
                saveDetails.Added.Add(new Importance {Description = "Importance Level", Level = string.Empty});

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.ValidationErrors.Count, 1);
                Assert.Equal(result.ValidationErrors[0].Field, "level");
                Assert.Equal(result.Result, "error");
            }

            [Fact]
            public void ShouldReturnErrorResultWhenUpdatedImportanceLevelAlreadyExist()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var saveDetails = new Delta<Importance>();
                saveDetails.Updated.Add(new Importance {Description = "Importance Level 1", Level = "02"});

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.ValidationErrors.Count, 1);
                Assert.Equal(result.ValidationErrors[0].Field, "description");
                Assert.Equal(result.Result, "error");
            }

            [Fact]
            public void ShouldReturnErrorWhenImportanceLevelDescriptionLenghtIsGreaterThanThirty()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var saveDetails = new Delta<Importance>();
                saveDetails.Added.Add(new Importance {Description = "0123456789012345678901234567890", Level = "10"});

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.ValidationErrors.Count, 1);
                Assert.Equal(result.ValidationErrors[0].Field, "description");
                Assert.Equal(result.Result, "error");
            }

            [Fact]
            public void ShouldReturnErrorWhenImportanceLevelLenghtIsGreaterThanTwo()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var saveDetails = new Delta<Importance>();
                saveDetails.Added.Add(new Importance {Description = "Importance Level", Level = "001"});

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(result.ValidationErrors.Count, 1);
                Assert.Equal(result.ValidationErrors[0].Field, "level");
                Assert.Equal(result.Result, "error");
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var f = new ImportanceLevelMaintenanceControllerFixture(Db);

                f.PrepareData();

                var saveDetails = new Delta<Importance>();
                saveDetails.Deleted.Add(new Importance {Level = "01"});
                saveDetails.Deleted.Add(new Importance {Level = "02"});

                var result = f.Subject.Save(saveDetails);

                Assert.Equal(result.ValidationErrors.Count, 0);
                Assert.Equal("success", result.Result);
            }
        }
    }
}