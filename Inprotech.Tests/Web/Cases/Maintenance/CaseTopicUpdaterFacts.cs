using System.Collections.Generic;
using System.Linq;
using Autofac;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Maintenance
{
    public class CaseTopicsValidatorFacts : FactBase
    {
        public class SaveData : FactBase
        {
            [Fact]
            public void ShouldCallAllTheUpdateDataMethods()
            {
                var fixture = new CaseTopicsValidatorFactsFixture();
                var topic1Updater = Substitute.For<ITopicDataUpdater<Case>>();
                var topic2Updater = Substitute.For<ITopicDataUpdater<Case>>();

                fixture.TopicUpdateDatas.TryGetValue(Arg.Any<string>(), out _).ReturnsForAnyArgs(x =>
                {
                    var arg = x.Arg<string>();
                    if (arg == $"{TopicGroups.Cases}test1")
                    {
                        x[1] = topic1Updater;
                        return true;
                    }

                    if (arg == $"{TopicGroups.Cases}test2")
                    {
                        x[1] = topic2Updater;
                        return true;
                    }

                    return false;
                });

                fixture.Subject.Update(new MaintenanceSaveModel
                {
                    Topics = new Dictionary<string, JObject>
                    {
                        {"test1", null},
                        {"test2", null},
                        {"test3", null}
                    }
                }, TopicGroups.Cases, Arg.Any<Case>());

                topic1Updater.Received(1).UpdateData(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Case>());
                topic2Updater.Received(1).UpdateData(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Case>());
            }
        }

        public class Validate : FactBase
        {
            [Fact]
            public void ShouldReturnAllErrorsForValidatorsThatMatch()
            {
                var fixture = new CaseTopicsValidatorFactsFixture();
                var topic1Validator = Substitute.For<ITopicValidator<Case>>();
                topic1Validator.Validate(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Case>()).Returns(new[]
                {
                    ValidationErrors.Required("test"),
                    ValidationErrors.Required("test2")
                });

                fixture.TopicValidators.TryGetValue(Arg.Any<string>(), out _).ReturnsForAnyArgs(x =>
                {
                    x[1] = topic1Validator;
                    return true;
                });

                var validationErrors = fixture.Subject.Validate(new MaintenanceSaveModel
                {
                    Topics = new Dictionary<string, JObject>
                    {
                        {"test1", null},
                        {"test2", null},
                        {"test3", null}
                    }
                }, TopicGroups.Cases, Arg.Any<Case>());

                topic1Validator.Received(3).Validate(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Case>());
                Assert.Equal(6, validationErrors.Count());
            }

            [Fact]
            public void ShouldResultEachValidationResults()
            {
                var fixture = new CaseTopicsValidatorFactsFixture();
                fixture.TopicValidators.TryGetValue($"{TopicGroups.Cases}test1", out _).Returns(false);
                fixture.TopicValidators.TryGetValue($"{TopicGroups.Cases}test2", out _).Returns(false);
                fixture.TopicValidators.TryGetValue($"{TopicGroups.Cases}test3", out _).Returns(true);
                var validationErrors = fixture.Subject.Validate(new MaintenanceSaveModel
                {
                    Topics = new Dictionary<string, JObject>
                    {
                        {"test1", null},
                        {"test2", null}
                    }
                }, TopicGroups.Cases, Arg.Any<Case>());

                Assert.Equal(2, validationErrors.Count());
            }
        }
    }

    public class CaseTopicsValidatorFactsFixture : IFixture<CaseTopicsUpdater>
    {
        public CaseTopicsValidatorFactsFixture()
        {
            TopicValidators = Substitute.For<IIndex<string, ITopicValidator<Case>>>();
            LifetimeScope = Substitute.For<ILifetimeScope>();
            TopicUpdateDatas = Substitute.For<IIndex<string, ITopicDataUpdater<Case>>>();
            Subject = new CaseTopicsUpdater(TopicValidators, TopicUpdateDatas);
        }

        public IIndex<string, ITopicValidator<Case>> TopicValidators { get; set; }
        public ILifetimeScope LifetimeScope { get; set; }
        public IIndex<string, ITopicDataUpdater<Case>> TopicUpdateDatas { get; set; }

        public CaseTopicsUpdater Subject { get; }
    }
}