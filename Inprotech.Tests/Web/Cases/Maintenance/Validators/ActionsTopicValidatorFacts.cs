using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Cases.Maintenance.Validators;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Rules;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance.Validators
{
    public class ActionsTopicValidatorFacts : FactBase
    {
        [Fact]
        public void ShouldNotHaveAccessToTaskSecurityReturnsValidatorError()
        {
            var fixture = new ActionsTopicValidatorFixture(Db);
            fixture.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(false);

            var validationErrors = fixture.Subject.Validate(null, null, null);

            Assert.Equal(1, validationErrors.Count());
        }

        [Fact]
        public void ShouldContinueOnIfHasAccessToTask()
        {
            var fixture = new ActionsTopicValidatorFixture(Db);
            fixture.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(true);
            var @case = new Case().In(Db);
            var eventSaveModel = JObject.FromObject(new EventTopicSaveModel() { Rows = new EventSaveModel[0] });
            var validationErrors = fixture.Subject.Validate(eventSaveModel, null, @case);

            Assert.Equal(0, validationErrors.Count());
        }

        [Fact]
        public void ShouldReturnValidationErrorsIfNotAllowedToClearCaseEventDates()
        {
            var fixture = new ActionsTopicValidatorFixture(Db);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseEvent).Returns(true);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.ClearCaseEventDates).Returns(false);
            var @case = new Case().In(Db);
            var caseEvents = new[]
            {
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short())
            }.In(Db);
            caseEvents[0].EventDate = Fixture.Date();
            caseEvents[1].EventDate = Fixture.Date();
            caseEvents[2].EventDate = Fixture.Date();
            @case.CaseEvents.AddRange(caseEvents);
            var eventSaveModel = JObject.FromObject(new EventTopicSaveModel()
            {
                Rows = new []
                {
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[0].EventNo,
                        Cycle = caseEvents[0].Cycle,
                        EventDate = null
                    }, 
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[1].EventNo,
                        Cycle = caseEvents[1].Cycle,
                        EventDate = null
                    }, 
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[2].EventNo,
                        Cycle = caseEvents[2].Cycle,
                        EventDate = Fixture.Date()
                    }
                }
            });
            var validationErrors = fixture.Subject.Validate(eventSaveModel, null, @case);

            Assert.Equal(2, validationErrors.Count());
        }

        [Fact] 
        public void ShouldAllowClearingOfEventDatesWithTaskPermission()
        {
            var fixture = new ActionsTopicValidatorFixture(Db);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseEvent).Returns(true);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.ClearCaseEventDates).Returns(true);
            var @case = new Case().In(Db);
            var caseEvents = new[]
            {
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short())
            }.In(Db);
            caseEvents[0].EventDate = Fixture.Date();
            caseEvents[1].EventDate = Fixture.Date();
            caseEvents[2].EventDate = Fixture.Date();
            @case.CaseEvents.AddRange(caseEvents);
            var eventSaveModel = JObject.FromObject(new EventTopicSaveModel()
            {
                Rows = new []
                {
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[0].EventNo,
                        Cycle = caseEvents[0].Cycle,
                        EventDate = null
                    }, 
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[1].EventNo,
                        Cycle = caseEvents[1].Cycle,
                        EventDate = null
                    }, 
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[2].EventNo,
                        Cycle = caseEvents[2].Cycle,
                        EventDate = Fixture.Date()
                    }
                }
            });
            var validationErrors = fixture.Subject.Validate(eventSaveModel, null, @case);

            Assert.Equal(0, validationErrors.Count());
        }

        [Fact]
        public void ShouldReturnEachRowCorrectlyFromValidationResults()
        {
            var fixture = new ActionsTopicValidatorFixture(Db);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseEvent).Returns(true);
            fixture.TaskSecurityProvider.HasAccessTo(ApplicationTask.ClearCaseEventDates).Returns(true);
            fixture.DatesRuleValidator.Validate(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<short>(), Arg.Any<DateLogicValidationType>())
                   .ReturnsForAnyArgs(new List<DateRuleViolation>() { new DateRuleViolation() { IsInvalid = false }, new DateRuleViolation() { IsInvalid = true } });
            var @case = new Case().In(Db);
            var caseEvents = new[]
            {
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short()),
                new CaseEvent(@case.Id, Fixture.Integer(), Fixture.Short())
            }.In(Db);
            caseEvents[0].EventDate = Fixture.Date();
            caseEvents[1].EventDate = Fixture.Date();
            caseEvents[2].EventDate = Fixture.Date();
            @case.CaseEvents.AddRange(caseEvents);
            var eventSaveModel = JObject.FromObject(new EventTopicSaveModel()
            {
                Rows = new[]
                {
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[0].EventNo,
                        Cycle = caseEvents[0].Cycle,
                        EventDate = null
                    },
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[1].EventNo,
                        Cycle = caseEvents[1].Cycle,
                        EventDate = null
                    },
                    new EventSaveModel()
                    {
                        EventNo = caseEvents[2].EventNo,
                        Cycle = caseEvents[2].Cycle,
                        EventDate = Fixture.Date()
                    }
                }
            });
            var validationErrors = fixture.Subject.Validate(eventSaveModel, null, @case).ToArray();

            Assert.Equal(2, validationErrors.Count());
            Assert.Equal(Severity.Warning,validationErrors[0].Severity);
            Assert.Equal(Severity.Error,validationErrors[1].Severity);
        }

        public class ActionsTopicValidatorFixture : IFixture<ActionsTopicValidator>
        {
            public ActionsTopicValidatorFixture(IDbContext db)
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                DatesRuleValidator = Substitute.For<IDateRuleValidator>();
                Subject = new ActionsTopicValidator(db, TaskSecurityProvider, DatesRuleValidator);
            }
            public ActionsTopicValidator Subject { get; }
            public ITaskSecurityProvider TaskSecurityProvider { get; }
            public IDateRuleValidator DatesRuleValidator { get; }
        }
    }
}
