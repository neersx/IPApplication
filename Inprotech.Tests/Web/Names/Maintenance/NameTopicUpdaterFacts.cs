using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Maintenance.Topics;
using Inprotech.Web.Names.Maintenance;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Maintenance
{
    public class NameTopicUpdaterFacts : FactBase
    {
        public class SaveData : FactBase
        {
            [Fact]
            public void ShouldCallAllTheUpdateDataMethods()
            {
                var fixture = new NameTopicsValidatorFactsFixture(Db);
                var topic1Updater = Substitute.For<ITopicDataUpdater<Name>>();
                var topic2Updater = Substitute.For<ITopicDataUpdater<Name>>();

                fixture.TopicUpdateData.TryGetValue(Arg.Any<string>(), out _).ReturnsForAnyArgs(x =>
                {
                    var arg = x.Arg<string>();
                    if (arg == $"{TopicGroups.Names}test1")
                    {
                        x[1] = topic1Updater;
                        return true;
                    }

                    if (arg == $"{TopicGroups.Names}test2")
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
                }, TopicGroups.Names, Arg.Any<Name>());

                topic1Updater.Received(1).UpdateData(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>());
                topic2Updater.Received(1).UpdateData(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>());
            }

            public class Validate : FactBase
            {
                [Fact]
                public void ShouldReturnAllErrorsForValidatorsThatMatch()
                {
                    var fixture = new NameTopicsValidatorFactsFixture(Db);
                    var topic1Validator = Substitute.For<ITopicValidator<Name>>();
                    topic1Validator.Validate(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>()).Returns(new[]
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
                    }, TopicGroups.Cases, Arg.Any<Name>());

                    topic1Validator.Received(3).Validate(Arg.Any<JObject>(), Arg.Any<MaintenanceSaveModel>(), Arg.Any<Name>());
                    Assert.Equal(6, validationErrors.Count());
                }

                [Fact]
                public void ShouldReturnValidationErrorIfNoTopicValidator()
                {
                    var fixture = new NameTopicsValidatorFactsFixture(Db);
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
                    }, TopicGroups.Cases, Arg.Any<Name>());

                    Assert.Equal(2, validationErrors.Count());
                }
            }
        }

        public class NameTopicsValidatorFactsFixture : IFixture<NameTopicsUpdater>
        {
            public NameTopicsValidatorFactsFixture(InMemoryDbContext db)
            {
                DbContext = db; 
                TopicValidators = Substitute.For<IIndex<string, ITopicValidator<Name>>>();
                TopicUpdateData = Substitute.For<IIndex<string, ITopicDataUpdater<Name>>>();
                Subject = new NameTopicsUpdater(TopicValidators, TopicUpdateData, db);
            }

            public IIndex<string, ITopicValidator<Name>> TopicValidators { get; set; }
            public IIndex<string, ITopicDataUpdater<Name>> TopicUpdateData { get; set; }
            public InMemoryDbContext DbContext { get; set; }

            public NameTopicsUpdater Subject { get; }
        }
    }
}
