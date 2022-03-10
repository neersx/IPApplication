using System;
using System.Collections.Generic;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.BatchEventUpdate.DataEntryTaskHandlers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.PostModificationTasks;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;

namespace Inprotech.Tests.Web.BatchEventUpdate.EventDetailUpdateHandlerFacts
{
    public class EventDetailUpdateHandlerFixture : IFixture<IEventDetailUpdateHandler>
    {
        public IChangeTracker ChangeTracker;
        public ICurrentOfficialNumberUpdater CurrentOfficialNumberUpdater;
        public IDocumentGenerator DocumentGenerator;
        public IEnumerable<IPostCaseDetailModificationTask> PostCaseDetailModificationTasks;
        public Func<DateTime> SystemClock;

        public EventDetailUpdateHandlerFixture(InMemoryDbContext db)
        {
            ExistingCase = new CaseBuilder().Build().In(db);
            ExistingCriteria = new CriteriaBuilder().Build().In(db);
            ExistingDataEntryTask = new DataEntryTaskBuilder
            {
                Criteria = ExistingCriteria,
                FileLocation =
                    new TableCodeBuilder().For(TableTypes.FileLocation).Build().In(db)
            }.Build().In(db);

            ChangeTracker = Substitute.For<IChangeTracker>();
            CurrentOfficialNumberUpdater = Substitute.For<ICurrentOfficialNumberUpdater>();
            DocumentGenerator = Substitute.For<IDocumentGenerator>();
            PostCaseDetailModificationTasks = Substitute.For<IEnumerable<IPostCaseDetailModificationTask>>();
            SystemClock = Substitute.For<Func<DateTime>>();
            Subject = new EventDetailUpdateHandler(db, PostCaseDetailModificationTasks, ChangeTracker, SystemClock, DocumentGenerator, CurrentOfficialNumberUpdater);
        }

        public DataEntryTask ExistingDataEntryTask { get; set; }
        public Case ExistingCase { get; set; }
        protected Criteria ExistingCriteria { get; set; }
        public IEventDetailUpdateHandler Subject { get; }
    }
}