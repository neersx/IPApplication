using Dependable.Dispatcher;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.ApplyRecordal;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.BackgroundProcess;
using NSubstitute;
using System;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.ApplyRecordal
{
    public class ApplyRecordalFacts : FactBase
    {
        [Fact]
        public async Task ShouldAddBackgroundProcessOnSuccessfulRun()
        {
            var f = new ApplyRecordalFixture(Db);
            var args = new ApplyRecordalArgs
            {
                RecordalCase = Fixture.Integer(),
                RecordalDate = Fixture.Date(),
                RunBy = Fixture.Integer(),
                RecordalSeqIds = Fixture.String(),
                RecordalStatus = Fixture.String(),
                SuccessMessage = Fixture.String()
            };

            await f.Subject.AddBackgroundProcess(args);
            var backGroundProcess = Db.Set<BackgroundProcess>().FirstOrDefault(_ => _.IdentityId == args.RunBy);
            Assert.NotNull(backGroundProcess);
            Assert.Equal(args.SuccessMessage, backGroundProcess.StatusInfo);
            Assert.Equal(BackgroundProcessType.General.ToString(), backGroundProcess.ProcessType);
            Assert.Equal(BackgroundProcessSubType.ApplyRecordals.ToString(), backGroundProcess.ProcessSubType);
            Assert.Equal((int)StatusType.Completed, backGroundProcess.Status);
            Assert.Equal(f.DateFunc(), backGroundProcess.StatusDate);
        }

        [Fact]
        public void HandleExceptionShouldAddBackgroundProcessWithError()
        {
            var f = new ApplyRecordalFixture(Db);
            var args = new ApplyRecordalArgs
            {
                RecordalCase = Fixture.Integer(),
                RecordalDate = Fixture.Date(),
                RunBy = Fixture.Integer(),
                RecordalSeqIds = Fixture.String(),
                RecordalStatus = Fixture.String(),
                ErrorMessage = Fixture.String()
            };
            var exceptionContext = new ExceptionContext {Exception = new Exception("Error")};
            f.Subject.HandleException(exceptionContext, args);
            
            f.Logger.Received(1).Exception(exceptionContext.Exception, "Error");
            var backGroundProcess = Db.Set<BackgroundProcess>().FirstOrDefault(_ => _.IdentityId == args.RunBy);
            Assert.NotNull(backGroundProcess);
            Assert.Equal(args.ErrorMessage, backGroundProcess.StatusInfo);
            Assert.Equal(BackgroundProcessType.General.ToString(), backGroundProcess.ProcessType);
            Assert.Equal(BackgroundProcessSubType.ApplyRecordals.ToString(), backGroundProcess.ProcessSubType);
            Assert.Equal((int)StatusType.Error, backGroundProcess.Status);
            Assert.Equal(f.DateFunc(), backGroundProcess.StatusDate);
        }
    }

    public class ApplyRecordalFixture : IFixture<Inprotech.Integration.ApplyRecordal.ApplyRecordal>
    {
        public ApplyRecordalFixture(InMemoryDbContext db)
        {
            DateFunc = Substitute.For<Func<DateTime>>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Logger = Substitute.For<IBackgroundProcessLogger<Inprotech.Integration.ApplyRecordal.ApplyRecordal>>();
            Subject = new Inprotech.Integration.ApplyRecordal.ApplyRecordal(db, DateFunc, SiteControlReader, Logger);
        }
        public Func<DateTime> DateFunc { get; set; }
        public Inprotech.Integration.ApplyRecordal.ApplyRecordal Subject { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public IBackgroundProcessLogger<Inprotech.Integration.ApplyRecordal.ApplyRecordal> Logger { get; set; }
    }
}
