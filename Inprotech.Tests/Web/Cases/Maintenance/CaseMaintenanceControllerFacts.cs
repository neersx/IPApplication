using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance
{
    public class CaseMaintenanceControllerFacts : FactBase
    {
        [Fact]
        public void ShouldReturnAppropriateResponseOnValidationError()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            fixture.TopicsUpdater.Validate(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Case>()).Returns(new List<ValidationError>() { ValidationErrors.NotUnique(string.Empty) });
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id };

            var response = fixture.Subject.SaveData(model);

            Assert.Equal(1, response.Errors.Count());
            Assert.Equal("error", response.Status);
            fixture.TopicsUpdater.Received(1).Validate(model, TopicGroups.Cases, Arg.Any<Case>());
            fixture.TopicsUpdater.DidNotReceive().Update(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Case>());
            fixture.CaseMaintenanceSave.DidNotReceive().Save(Arg.Any<Case>(), Arg.Any<bool>(), Arg.Any<int>(), Arg.Any<CaseMaintenanceSaveModel>());
        }

        [Fact]
        public void ShouldReturnErrorOnNoValidationError()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            fixture.TopicsUpdater.Validate(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Case>()).Returns(new List<ValidationError>());
            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(new CaseMaintenanceSaveResult());
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id };
            var response = fixture.Subject.SaveData(model);

            Assert.Null(response.Errors);
            Assert.NotEqual("error", response.Status);
            fixture.TopicsUpdater.Received(1).Validate(model, TopicGroups.Cases, @case);
            fixture.CaseMaintenanceSave.Received().Save(Arg.Any<Case>(), Arg.Any<bool?>(), null, Arg.Any<CaseMaintenanceSaveModel>());
        }

        [Fact]
        public void IfPoliceImmediatelyPassedInDoNotUseSiteControl()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id, IsPoliceImmediately = true };
            var result = new CaseMaintenanceSaveResult() { AnyPolicingRequests = true };
            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(result);
            fixture.Subject.SaveData(model);

            fixture.SiteControlReader.DidNotReceive().Read<bool>(SiteControls.PoliceImmediately);
        }

        [Fact]
        public void IfPoliceImmediatelyNotPassedInUseSiteControl()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id };
            var result = new CaseMaintenanceSaveResult() { AnyPolicingRequests = true };
            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(result);

            fixture.Subject.SaveData(model);

            fixture.SiteControlReader.Received(1).Read<bool>(SiteControls.PoliceImmediately);
        }

        [Fact]
        public void IfPoliceImmediatelyPassedAsTruePolicingShouldBeCalled()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id, IsPoliceImmediately = true };
            var result = new CaseMaintenanceSaveResult() { AnyPolicingRequests = true };

            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(result);

            var response = fixture.Subject.SaveData(model);

            Assert.True(response.ShouldRunPolicing);
        }

        [Fact]
        public void IfPoliceImmediatelyPassedAsFalsePolicingShouldBeCalled()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id };
            var result = new CaseMaintenanceSaveResult() { AnyPolicingRequests = true };

            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(result);

            var response = fixture.Subject.SaveData(model);

            Assert.False(response.ShouldRunPolicing);
        }

        [Fact]
        public void IfPoliceImmediatelyNullAndSiteControlIsFalsePolicingShouldBeCalled()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id };

            var result = new CaseMaintenanceSaveResult() { AnyPolicingRequests = true };
            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(result);
            fixture.SiteControlReader.Read<bool>(Arg.Any<string>()).Returns(false);

            var response = fixture.Subject.SaveData(model);

            Assert.False(response.ShouldRunPolicing);
        }

        [Fact]
        public void IfPoliceImmediatelyNullAndSiteControlIsTruePolicingShouldBeCalled()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase.In(Db);
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id };
            var result = new CaseMaintenanceSaveResult() { AnyPolicingRequests = true };
            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(result);
            fixture.SiteControlReader.Read<bool>(Arg.Any<string>()).Returns(true);

            var response = fixture.Subject.SaveData(model);

            Assert.True(response.ShouldRunPolicing);
        }

        [Fact]
        public void SaveDataProceedOnWarningsWithForceUpdate()
        {
            var fixture = new CaseMaintenanceControllerFixture(Db);
            var @case = fixture.DefaultCase;
            @case.In(Db);
            var warnings = new List<ValidationError>();
            warnings.Add(new ValidationError("aa", "message", string.Empty, true, Severity.Warning));
            fixture.CaseMaintenanceSave.Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>()).Returns(new CaseMaintenanceSaveResult());
            fixture.TopicsUpdater.Validate(Arg.Any<MaintenanceSaveModel>(), Arg.Any<TopicGroups>(), Arg.Any<Case>()).Returns(warnings);
            var model = new CaseMaintenanceSaveModel() { CaseKey = @case.Id, ForceUpdate = true, IsPoliceImmediately = true };
            var response = fixture.Subject.SaveData(model);

            Assert.Null(response.Errors);
            Assert.NotEqual("error", response.Status);
            fixture.TopicsUpdater.Received(1).Validate(model, TopicGroups.Cases, @case);
            fixture.CaseMaintenanceSave.Received().Save(Arg.Any<Case>(), Arg.Any<bool?>(), Arg.Any<int?>(), Arg.Any<CaseMaintenanceSaveModel>());
        }

        public class CaseMaintenanceControllerFixture : IFixture<CaseMaintenanceController>
        {
            public CaseMaintenanceControllerFixture(IDbContext db)
            {
                TopicsUpdater = Substitute.For<ITopicsUpdater<Case>>();
                CaseMaintenanceSave = Substitute.For<ICaseMaintenanceSave>();
                PolicingEngine = Substitute.For<IPolicingEngine>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new CaseMaintenanceController(db, TopicsUpdater, CaseMaintenanceSave, PolicingEngine, SiteControlReader);
            }
            public ITopicsUpdater<Case> TopicsUpdater { get; set; }
            public IPolicingEngine PolicingEngine { get; }
            public ISiteControlReader SiteControlReader { get; }
            public ICaseMaintenanceSave CaseMaintenanceSave { get; set; }
            public CaseMaintenanceController Subject { get; }
            public Case DefaultCase
            {
                get
                {
                    var @case = new Case(Fixture.Integer(),
                                         Fixture.String(),
                                         new Country(Fixture.String(), Fixture.String()),
                                         new CaseType(Fixture.String(), Fixture.String()),
                                         new PropertyType(Fixture.String(), Fixture.String()),
                                         null);
                    @case.CaseEvents.AddAll(new List<CaseEvent>()
                    {
                        new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short())
                    });
                    return @case;
                }
            }
        }
    }
}
