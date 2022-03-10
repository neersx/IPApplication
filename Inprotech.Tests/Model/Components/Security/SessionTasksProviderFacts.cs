using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class SessionTasksProviderFacts
    {
        public class IsSessionValidMethod : FactBase
        {
            [Fact]
            public void ReturnsInvalidIfLastExtensionNotInRange()
            {
                var f = new SessionTasksProviderFixture(Db)
                    .WithSecurityContext();

                var log = new UserIdentityAccessLog(f.SecurityContext.User.Id, "Forms", "Inprotech", Fixture.TodayUtc().AddMinutes(-130)) {LastExtension = Fixture.TodayUtc().AddMinutes(-121)}.In(f.DbContext);

                var result = f.Subject.IsSessionValid(log.LogId);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsInvalidIfLogidNotFound()
            {
                var f = new SessionTasksProviderFixture(Db)
                    .WithSecurityContext();

                var result = f.Subject.IsSessionValid(1000);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsInvalidIfLoginTimeNotInRange()
            {
                var f = new SessionTasksProviderFixture(Db)
                    .WithSecurityContext();

                var log = new UserIdentityAccessLog(f.SecurityContext.User.Id, "Forms", "Inprotech", Fixture.TodayUtc().AddMinutes(-121)).In(f.DbContext);

                var result = f.Subject.IsSessionValid(log.LogId);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsInvalidIfSessionIsLoggedOut()
            {
                var f = new SessionTasksProviderFixture(Db)
                    .WithSecurityContext();

                var log = new UserIdentityAccessLog(f.SecurityContext.User.Id, "Forms", "Inprotech", Fixture.TodayUtc()) {LogoutTime = Fixture.TodayUtc()}.In(f.DbContext);

                var result = f.Subject.IsSessionValid(log.LogId);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsInValidSessionIfUserDoesNotExist()
            {
                var f = new SessionTasksProviderFixture(Db);

                var result = f.Subject.IsSessionValid(0);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsValidSessionIfValid()
            {
                var f = new SessionTasksProviderFixture(Db)
                    .WithSecurityContext();

                var log = new UserIdentityAccessLog(f.SecurityContext.User.Id, "Forms", "Inprotech", Fixture.TodayUtc()).In(f.DbContext);

                var result = f.Subject.IsSessionValid(log.LogId);

                Assert.True(result);
            }
        }
    }

    public class SessionTasksProviderFixture : IFixture<ISessionValidator>
    {
        public SessionTasksProviderFixture(InMemoryDbContext db)
        {
            DbContext = db;

            SecurityContext = Substitute.For<ISecurityContext>();
            AuthSettings = Substitute.For<IAuthSettings>();

            var taskSecurityProviderCache = Substitute.For<ITaskSecurityProviderCache>();
            taskSecurityProviderCache.Resolve(Arg.Any<Func<int, IDictionary<short, ValidSecurityTask>>>(), Arg.Any<int>())
                                     .Returns(new ConcurrentDictionary<short, ValidSecurityTask>());

            Subject = new SessionTasksProvider(DbContext, SecurityContext, taskSecurityProviderCache, Fixture.TodayUtc, AuthSettings);

            AuthSettings.SessionTimeout.Returns(120);
        }

        public InMemoryDbContext DbContext { get; set; }

        public ISecurityContext SecurityContext { get; set; }

        public IAuthSettings AuthSettings { get; set; }

        public ISessionValidator Subject { get; }

        public SessionTasksProviderFixture WithSecurityContext()
        {
            SecurityContext.User.Returns(UserBuilder.AsInternalUser(DbContext, "internal").Build().In(DbContext));

            return this;
        }
    }
}