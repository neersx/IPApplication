using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.BatchEventUpdate.Miscellaneous;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.DataEntryTaskHandlersFacts
{
    public class WhenValidating : FactBase
    {
        public WhenValidating()
        {
            _fixture = new BatchEventDataEntryTaskHandlerFixture(Db);

            var event1 = new EventBuilder().Build().In(Db);
            var event2 = new EventBuilder().Build().In(Db);

            var availableEvent1 =
                new AvailableEventBuilder {Event = event1, DataEntryTask = _fixture.ExistingDataEntryTask}.Build()
                                                                                                          .In(Db);
            var availableEvent2 =
                new AvailableEventBuilder {Event = event2, DataEntryTask = _fixture.ExistingDataEntryTask}.Build()
                                                                                                          .In(Db);

            _fixture.ExistingDataEntryTask.AvailableEvents.Add(availableEvent1);
            _fixture.ExistingDataEntryTask.AvailableEvents.Add(availableEvent2);

            AvailableEvents = new[]
            {
                new AvailableEventModelBuilder
                {
                    AvailableEvent = availableEvent1,
                    Event = event1,
                    DataEntryTask = _fixture.ExistingDataEntryTask
                }.Build(),
                new AvailableEventModelBuilder
                {
                    AvailableEvent = availableEvent2,
                    Event = event2,
                    DataEntryTask = _fixture.ExistingDataEntryTask
                }.Build()
            };

            _fixture.CaseUpdateModel.FileLocationId =
                new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(Db).Id;
            _fixture.CaseUpdateModel.OfficialNumber = Fixture.String();
            _fixture.CaseUpdateModel.AvailableEvents = AvailableEvents;

            _fixture.Subject.Validate(_fixture.ExistingCase, _fixture.ExistingDataEntryTask, _fixture.CaseUpdateModel);
        }

        readonly BatchEventDataEntryTaskHandlerFixture _fixture;

        protected AvailableEventModel[] AvailableEvents { get; set; }
        protected DataEntryTaskHandlerOutput Result { get; set; }

        [Fact]
        public void It_should_invoke_event_detail_update_validators_ensure_input_is_correct_once()
        {
            _fixture.EventDetailUpdateValidator.Received(1).EnsureInputIsValid(
                                                                               Arg.Any<Case>(),
                                                                               Arg.Any<DataEntryTask>(),
                                                                               Arg.Is<string>(
                                                                                              officialNumber =>
                                                                                                  _fixture.CaseUpdateModel.OfficialNumber ==
                                                                                                  officialNumber),
                                                                               Arg.Is<int?>(
                                                                                            fileLocationId =>
                                                                                                _fixture.CaseUpdateModel.FileLocationId ==
                                                                                                fileLocationId),
                                                                               Arg.Is<AvailableEventModel[]>(
                                                                                                             ae =>
                                                                                                                 ae.SequenceEqual(
                                                                                                                                  _fixture.CaseUpdateModel
                                                                                                                                          .AvailableEvents)));
        }

        [Fact]
        public void It_should_invoke_event_detail_update_validators_validate_once()
        {
            _fixture.EventDetailUpdateValidator.Received(1).Validate(
                                                                     Arg.Any<Case>(),
                                                                     Arg.Any<DataEntryTask>(),
                                                                     Arg.Is<string>(
                                                                                    officialNumber =>
                                                                                        _fixture.CaseUpdateModel.OfficialNumber ==
                                                                                        officialNumber),
                                                                     Arg.Is<int?>(
                                                                                  fileLocationId =>
                                                                                      _fixture.CaseUpdateModel.FileLocationId ==
                                                                                      fileLocationId),
                                                                     Arg.Is<AvailableEventModel[]>(
                                                                                                   ae =>
                                                                                                       ae.SequenceEqual(
                                                                                                                        _fixture.CaseUpdateModel
                                                                                                                                .AvailableEvents)));
        }
    }
}