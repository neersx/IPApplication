using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.DataEntryTasks;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate.DataEntryTaskHandlers;
using Inprotech.Web.BatchEventUpdate.Models;
using Inprotech.Web.BatchEventUpdate.Validators;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using AvailableEventModel = Inprotech.Web.BatchEventUpdate.Miscellaneous.AvailableEventModel;

namespace Inprotech.Tests.Web.BatchEventUpdate.DataEntryTaskHandlersFacts
{
    public class BatchEventDataEntryTaskHandlerFixture : IFixture<BatchEventDataEntryTaskHandler>
    {
        public BatchEventDataEntryTaskHandlerFixture(InMemoryDbContext db)
        {
            ExistingCase = new CaseBuilder().Build().In(db);
            ExistingCriteria = new CriteriaBuilder().Build().In(db);
            ExistingDataEntryTask = new DataEntryTaskBuilder
            {
                Criteria = ExistingCriteria,
                FileLocation =
                    new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(db)
            }.Build().In(db);

            EventDetailUpdateValidator = Substitute.For<IEventDetailUpdateValidator>();
            EventDetailUpdateValidator.Validate(
                                                Arg.Any<Case>(),
                                                Arg.Any<DataEntryTask>(),
                                                Arg.Any<string>(),
                                                Arg.Any<int?>(),
                                                Arg.Any<AvailableEventModel[]>())
                                      .Returns(Enumerable.Empty<ValidationResult>());

            EventDetailUpdateHandler = Substitute.For<IEventDetailUpdateHandler>();
            EventDetailUpdateHandler.ApplyChanges(null, null, null, null, Arg.Any<DateTime>(), null, null)
                                    .ReturnsForAnyArgs(new PolicingRequestsBuilder().Build());
            EventDetailUpdateHandler.ProcessPostModificationTasks(null, null, null)
                                    .ReturnsForAnyArgs(new PolicingRequestsBuilder().Build());

            CaseUpdateModel = new CaseUpdateModel();
        }

        public DataEntryTask ExistingDataEntryTask { get; set; }
        public Case ExistingCase { get; }
        protected Criteria ExistingCriteria { get; }
        public CaseUpdateModel CaseUpdateModel { get; set; }
        public IEventDetailUpdateValidator EventDetailUpdateValidator { get; }
        public IEventDetailUpdateHandler EventDetailUpdateHandler { get; }

        public BatchEventDataEntryTaskHandler Subject => new BatchEventDataEntryTaskHandler(EventDetailUpdateValidator, EventDetailUpdateHandler);
    }
}