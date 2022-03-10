using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class SubjectSecurityProviderFacts
    {
        public class IsSessionValidMethod : FactBase
        {
            [Fact]
            public void ReturnsFaleIfPermissionNotFound()
            {
                var f = new SubjectSecurityProviderFixture(Db)
                    .WithSecurityContext();

                f.SubjectSecurityProviderCache.Resolve(Arg.Any<Func<int, IDictionary<short, SubjectAccess>>>(), Arg.Any<int>())
                 .Returns(new ConcurrentDictionary<short, SubjectAccess>());

                var result = f.Subject.HasAccessToSubject(ApplicationSubject.Attachments);
                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfFoundInCache()
            {
                var f = new SubjectSecurityProviderFixture(Db)
                    .WithSecurityContext();

                f.SubjectSecurityProviderCache.Resolve(Arg.Any<Func<int, IDictionary<short, SubjectAccess>>>(), Arg.Any<int>())
                 .Returns(new Dictionary<short, SubjectAccess>() { { 0, new SubjectAccess() { TopicId = (short)ApplicationSubject.Attachments, CanSelect = true } } });

                var result = f.Subject.HasAccessToSubject(ApplicationSubject.Attachments);

                Assert.True(result);
            }
        }
    }

    public class SubjectSecurityProviderFixture : IFixture<ISubjectSecurityProvider>
    {
        public SubjectSecurityProviderFixture(InMemoryDbContext db)
        {
            DbContext = db;

            SecurityContext = Substitute.For<ISecurityContext>();
            AuthSettings = Substitute.For<IAuthSettings>();

            SubjectSecurityProviderCache = Substitute.For<ISubjectSecurityProviderCache>();

            Subject = new SubjectSecurityProvider(DbContext, SecurityContext, SubjectSecurityProviderCache, Fixture.TodayUtc);

            AuthSettings.SessionTimeout.Returns(120);
        }

        public InMemoryDbContext DbContext { get; set; }

        public ISecurityContext SecurityContext { get; set; }

        public ISubjectSecurityProviderCache SubjectSecurityProviderCache { get; set; }

        public IAuthSettings AuthSettings { get; set; }

        public ISubjectSecurityProvider Subject { get; }

        public SubjectSecurityProviderFixture WithSecurityContext()
        {
            SecurityContext.User.Returns(UserBuilder.AsInternalUser(DbContext, "internal").Build().In(DbContext));

            return this;
        }
    }
}