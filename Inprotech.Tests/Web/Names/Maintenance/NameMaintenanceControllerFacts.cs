using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Maintenance.Topics;
using Inprotech.Web.Names.Maintenance;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;
using Severity = InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation.Severity;

namespace Inprotech.Tests.Web.Names.Maintenance
{
    public class NameMaintenanceControllerFacts : FactBase
    {
        public class NameMaintenanceControllerFixture : IFixture<NameMaintenanceController>
        {
            public NameMaintenanceControllerFixture(IDbContext db)
            {
                TopicsUpdater = Substitute.For<ITopicsUpdater<Name>>();
                NameMaintenanceSave = Substitute.For<INameMaintenanceSave>();
                Subject = new NameMaintenanceController(db, NameMaintenanceSave, TopicsUpdater);
            }
            public ITopicsUpdater<Name> TopicsUpdater { get; set; }
            public INameMaintenanceSave NameMaintenanceSave { get; set; }
            public NameMaintenanceController Subject { get; }
          
        }

        [Fact]
        public void SaveDataReturnsAppropriateResponseOnValidationError()
        {
            var fixture = new NameMaintenanceControllerFixture(Db);
            var name = new NameBuilder(Db).Build().In(Db);
            fixture.TopicsUpdater.Validate(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Name>()).Returns(new List<ValidationError>() { ValidationErrors.NotUnique(string.Empty) });
            var model = new NameMaintenanceSaveModel() { NameId = name.Id, IgnoreSanityCheck = true };

            var response = fixture.Subject.SaveData(model);

            Assert.Equal(1, response.Errors.Count());
            Assert.Equal("error", response.Status);
            fixture.TopicsUpdater.Received(1).Validate(model, TopicGroups.Names, Arg.Any<Name>());
            fixture.TopicsUpdater.DidNotReceive().Update(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Name>());
            fixture.NameMaintenanceSave.DidNotReceive().Save(Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>());
        }

        [Fact]
        public void SaveDataDoesNotReturnsErrorOnNoValidationError()
        {
            var fixture = new NameMaintenanceControllerFixture(Db);
            var name = new NameBuilder(Db).Build().In(Db);
            var saveResults = new NameMaintenanceSaveResult();
            fixture.TopicsUpdater.Validate(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Name>()).Returns(new List<ValidationError>());
            fixture.NameMaintenanceSave.Save(Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>()).Returns(saveResults);
            var model = new NameMaintenanceSaveModel { NameId = name.Id, IgnoreSanityCheck = true };

            var response = fixture.Subject.SaveData(model);

            Assert.Null(response.Errors);
            Assert.NotEqual("error", response.Status);
            fixture.TopicsUpdater.Received(1).Validate(model, TopicGroups.Names, name);
            fixture.NameMaintenanceSave.Received().Save(Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>());
        }

        [Fact]
        public void SaveUnsuccessfulIfThereAreBlockingSanityErrors()
        {
            var fixture = new NameMaintenanceControllerFixture(Db);
            var name = new NameBuilder(Db).Build().In(Db);
            var saveResults = new NameMaintenanceSaveResult
            {
                SanityCheckResults = new[]
                {
                    new ValidationResult("there is a problem", Severity.Warning).WithDetails(new
                    {
                        IsWarning = false, CanOverride = false
                    })
                }
            };
            fixture.TopicsUpdater.Validate(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Name>()).Returns(new List<ValidationError>());
            fixture.NameMaintenanceSave.Save(Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>()).Returns(saveResults);
            var model = new NameMaintenanceSaveModel { NameId = name.Id, IgnoreSanityCheck = false };
            var response = fixture.Subject.SaveData(model);

            Assert.False(response.SavedSuccessfully);
        }
    }
}
