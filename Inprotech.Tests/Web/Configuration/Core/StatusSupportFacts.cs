using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Configuration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Core
{
    public class StatusSupportFacts
    {
        public class StopPayReasonsMethod : FactBase
        {
            [Fact]
            public void ReturnsStopPayReasons()
            {
                new TableCode(6501, 68, "Abandoned", "A").In(Db);
                new TableCode(6502, 68, "Paid through other channels", "C").In(Db);
                new TableCode(6503, 68, "Unspecified", "U").In(Db);

                var f = new StatusSupportFixture(Db);
                var result = f.Subject.StopPayReasons();

                Assert.Equal(3, result.Count());
            }
        }

        public class StopPayReasonForMethod : FactBase
        {
            [Fact]
            public void ReturnsStopPayReasonForUserCode()
            {
                var stopPayReason1 = new TableCode(6501, 68, "Abandoned", "A").In(Db);
                new TableCode(6502, 68, "Paid through other channels", "C").In(Db);
                new TableCode(6503, 68, "Unspecified", "U").In(Db);

                var f = new StatusSupportFixture(Db);
                var result = f.Subject.StopPayReasonFor("A");

                Assert.Equal(stopPayReason1.Id, result.Id);
            }
        }

        public class PermissionsMethod : FactBase
        {
            [Fact]
            public void ReturnsPermissions()
            {
                var f = new StatusSupportFixture(Db);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Modify)
                 .Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Create)
                 .Returns(true);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainStatus, ApplicationTaskAccessLevel.Delete)
                 .Returns(false);

                var result = f.Subject.Permissions();

                Assert.True(result.CanUpdate);
                Assert.False(result.CanDelete);
                Assert.True(result.CanCreate);
            }
        }

        public class StatusSupportFixture : IFixture<StatusSupport>
        {
            public StatusSupportFixture(InMemoryDbContext db)
            {
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                Subject = new StatusSupport(db, TaskSecurityProvider);
            }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }
            public StatusSupport Subject { get; }
        }
    }
}