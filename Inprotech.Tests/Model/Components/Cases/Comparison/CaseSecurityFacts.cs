using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison
{
    public class CaseSecurityFacts
    {
        public class CaseSecurityFixture : IFixture<CaseSecurity>
        {
            public CaseSecurityFixture()
            {
                CaseAuthorization = Substitute.For<ICaseAuthorization>();

                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                Subject = new CaseSecurity(CaseAuthorization, TaskSecurityProvider);
            }

            public ICaseAuthorization CaseAuthorization { get; set; }

            public ITaskSecurityProvider TaskSecurityProvider { get; set; }

            public CaseSecurity Subject { get; }

            public CaseSecurityFixture WithCaseAccessSecurity()
            {
                CaseAuthorization.Authorize(Arg.Any<int>(), AccessPermissionLevel.Update)
                                 .Returns(x =>
                                 {
                                     var caseId = (int) x[0];
                                     return new AuthorizationResult(caseId, true, false, null);
                                 });
                return this;
            }

            public CaseSecurityFixture WithoutCaseAccessSecurity()
            {
                CaseAuthorization.Authorize(Arg.Any<int>(), AccessPermissionLevel.Update)
                                 .Returns(x =>
                                 {
                                     var caseId = (int) x[0];
                                     return new AuthorizationResult(caseId, true, true, Fixture.String());
                                 });
                return this;
            }

            public CaseSecurityFixture WithTaskSecurity()
            {
                TaskSecurityProvider.HasAccessTo(ApplicationTask.SaveImportedCaseData)
                                    .Returns(true);
                return this;
            }

            public CaseSecurityFixture WithoutTaskSecurity()
            {
                TaskSecurityProvider.HasAccessTo(ApplicationTask.SaveImportedCaseData)
                                    .Returns(false);
                return this;
            }
        }

        [Fact]
        public async Task CannotUpdateIfCaseAccessSecurityNotAvailable()
        {
            var f = new CaseSecurityFixture()
                    .WithoutCaseAccessSecurity()
                    .WithTaskSecurity();

            var r = await f.Subject.CanAcceptChanges(new CaseBuilder().Build());

            Assert.False(r);
        }

        [Fact]
        public async Task CannotUpdateIfTaskSecurityNotAvailable()
        {
            var f = new CaseSecurityFixture()
                    .WithCaseAccessSecurity()
                    .WithoutTaskSecurity();

            var r = await f.Subject.CanAcceptChanges(new CaseBuilder().Build());

            Assert.False(r);
        }

        [Fact]
        public async Task CanUpdateOnlyIfBothTypesOfSecurityAvailable()
        {
            var f = new CaseSecurityFixture()
                    .WithCaseAccessSecurity()
                    .WithTaskSecurity();

            var r = await f.Subject.CanAcceptChanges(new CaseBuilder().Build());

            Assert.True(r);
        }
    }
}