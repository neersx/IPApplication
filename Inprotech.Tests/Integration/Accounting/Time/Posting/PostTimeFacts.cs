using System;
using System.Linq;
using Dependable.Dispatcher;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.Accounting.Time.Posting;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Accounting.Time.Posting
{
    public class PostTimeFacts : FactBase
    {
        [Fact]
        public void HandleExceptionShouldAddBackgroundProcessWithError()
        {
            var f = new PostTimeFixture(Db);
            var args = new PostTimeArgs
            {
                UserIdentityId = Fixture.Integer(),
                ErrorMessage = Fixture.String()
            };
            var exceptionContext = new ExceptionContext {Exception = new Exception("Error")};
            f.Subject.HandleException(exceptionContext, args);
            
            f.Logger.Received(1).Exception(exceptionContext.Exception, "Error");
            var backGroundProcess = Db.Set<BackgroundProcess>().FirstOrDefault(_ => _.IdentityId == args.UserIdentityId);
            Assert.NotNull(backGroundProcess);
            Assert.Equal(args.ErrorMessage, backGroundProcess.StatusInfo);
            Assert.Equal(BackgroundProcessType.General.ToString(), backGroundProcess.ProcessType);
            Assert.Equal(BackgroundProcessSubType.TimePosting.ToString(), backGroundProcess.ProcessSubType);
            Assert.Equal((int)StatusType.Error, backGroundProcess.Status);
            Assert.Equal(f.DateFunc(), backGroundProcess.StatusDate);
        }
    }

    public class PostTimeFixture : IFixture<PostTime>
    {
        public PostTimeFixture(InMemoryDbContext db)
        {
            DateFunc = Substitute.For<Func<DateTime>>();
            Logger = Substitute.For<IBackgroundProcessLogger<PostTime>>();
            Subject = new PostTime(db, DateFunc, Logger);
        }
        public Func<DateTime> DateFunc { get; set; }
        public PostTime Subject { get; set; }
        public IBackgroundProcessLogger<PostTime> Logger { get; set; }
    }
}
