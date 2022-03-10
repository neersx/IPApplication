using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseInternalDetailsControllerFacts : FactBase
    {
        [Fact]
        public void ReturnDates()
        {
            const int caseId = 100;
            var dateCreated = DateTime.Now.AddDays(-7);
            var dateChanged = DateTime.Now.AddDays(-3);
            
            var f = new CaseInternalDetailsControllerFixture();

            f.Data.WithCaseEvents(caseId, (int) KnownEvents.DateOfLastChange, dateChanged)
                  .WithCaseEvents(caseId, (int) KnownEvents.DateOfEntry, dateCreated);
             
            var result = f.Subject.GetCaseInternalDetails(caseId);
            Assert.Equal(dateCreated, result.DateCreated);
            Assert.Equal(dateChanged, result.DateChanged);
        }

        [Fact]
        public void ReturnNullOnNullDate()
        {
            const int caseId = 100;
            var dateChanged = DateTime.Now.AddDays(-3);
            
            var f = new CaseInternalDetailsControllerFixture();

            f.Data.WithCaseEvents(caseId, (int) KnownEvents.DateOfLastChange, dateChanged);
             
            var result = f.Subject.GetCaseInternalDetails(caseId);
            Assert.Equal(dateChanged, result.DateChanged);
            Assert.Null(result.DateCreated);
        }

        [Fact]
        public void ShouldReturnMaintainWorkflowRulesProtected()
        {
            const int caseId = 100;
            
            var f = new CaseInternalDetailsControllerFixture();

            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.LaunchScreenDesigner).Returns(true);
            var result = f.Subject.GetCaseInternalDetails(caseId);
         
            Assert.True(result.CanAccessLink);

            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.LaunchScreenDesigner).Returns(false);

            result = f.Subject.GetCaseInternalDetails(caseId);
            Assert.False(result.CanAccessLink);
        }
    }

    class CaseInternalDetailsControllerFixture : IFixture<CaseInternalDetailsController>
    {
        public CaseInternalDetailsControllerFixture()
        {
            Db = new InMemoryDbContext();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            Subject = new CaseInternalDetailsController(Db, TaskSecurityProvider);
            Data = new EventData(Db);
        }

        InMemoryDbContext Db { get; }
        public ITaskSecurityProvider TaskSecurityProvider { get; }

        public CaseInternalDetailsController Subject { get; }

        public EventData Data { get; }

    }

    public class EventData
    {
        readonly InMemoryDbContext _db;

        public EventData WithCaseEvents(int caseId, int eventNo, DateTime eventDate)
        {
            new CaseEvent(caseId, eventNo, Int16.MinValue)
            {
                EventDate = eventDate
            }.In(_db);

            return this;
        }

        public EventData(InMemoryDbContext db)
        {
            _db = db;
        }
    }
}