using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class ViewAccessAllowedStaffResolverFacts
    {
        public class ResolveMethod
        {
            [Fact]
            public async Task ShouldReturnAccessGrantedToStaffPersonallyIfNoRulesDefined()
            {
                var f = new ViewAccessAllowedStaffResolverFixture();

                f.FunctionSecurityProvider.ForOthers(BusinessFunction.TimeRecording, f.CurrentStaff)
                 .Returns(Enumerable.Empty<FunctionPrivilege>());

                var result = (await f.Subject.Resolve()).ToArray();

                Assert.Equal(1, result.Length);
                Assert.Equal(f.CurrentStaff.NameId, result[0]);
            }

            [Fact]
            public async Task ShouldNotReturnAccessGrantedToStaffIfOwnerlessRulesExist()
            {
                var f = new ViewAccessAllowedStaffResolverFixture();

                f.FunctionSecurityProvider.ForOthers(BusinessFunction.TimeRecording, f.CurrentStaff)
                 .Returns(new[]
                 {
                     new FunctionPrivilege {CanRead = true, OwnerId = null}
                 });

                var result = (await f.Subject.Resolve()).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public async Task ShouldReturnReadAccessGrantedOfAllOwnersIncludingStaff()
            {
                var staffA = Fixture.Integer();
                var staffB = Fixture.Integer();
                var staffC = Fixture.Integer();

                var f = new ViewAccessAllowedStaffResolverFixture();
                f.FunctionSecurityProvider.ForOthers(BusinessFunction.TimeRecording, f.CurrentStaff)
                 .Returns(new[]
                 {
                     new FunctionPrivilege {CanRead = true, OwnerId = staffA},
                     new FunctionPrivilege {CanRead = false, OwnerId = staffB},
                     new FunctionPrivilege {CanRead = true, OwnerId = staffC}
                 });

                var result = (await f.Subject.Resolve()).ToArray();

                Assert.Equal(3, result.Length);
                Assert.Equal(staffA, result[0]);
                Assert.Equal(staffC, result[1]);
                Assert.Equal(f.CurrentStaff.NameId, result[2]);
            }
        }

        public class ViewAccessAllowedStaffResolverFixture : IFixture<ViewAccessAllowedStaffResolver>
        {
            public ViewAccessAllowedStaffResolverFixture()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(CurrentStaff);

                Subject = new ViewAccessAllowedStaffResolver(securityContext, FunctionSecurityProvider);
            }

            public User CurrentStaff { get; } = new User(Fixture.String(), false);

            public IFunctionSecurityProvider FunctionSecurityProvider { get; } = Substitute.For<IFunctionSecurityProvider>();

            public ViewAccessAllowedStaffResolver Subject { get; }
        }
    }
}