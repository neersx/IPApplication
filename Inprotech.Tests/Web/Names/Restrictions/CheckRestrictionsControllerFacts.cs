using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Names.Restrictions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Restrictions
{
    public class CheckRestrictionsControllerFacts : FactBase
    {
        public CheckRestrictionsControllerFacts()
        {
            _red.In(Db);
            _amber1.In(Db);
            _amber2.In(Db);
            _green.In(Db);
        }

        readonly DebtorStatus _red = new DebtorStatus {RestrictionType = KnownDebtorRestrictions.DisplayError, Status = "red"};
        readonly DebtorStatus _amber1 = new DebtorStatus {RestrictionType = KnownDebtorRestrictions.DisplayWarning, Status = "amber"};
        readonly DebtorStatus _amber2 = new DebtorStatus {RestrictionType = KnownDebtorRestrictions.DisplayWarning, Status = "amber"};
        readonly DebtorStatus _green = new DebtorStatus {Status = "green"};

        CheckRestrictionsController CreateSubject(int[] accessibleNames, bool isExternalUser = false)
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User(Fixture.String(), isExternalUser));

            var cultureResolver = Substitute.For<IPreferredCultureResolver>();
            cultureResolver.Resolve().Returns("en");

            var nameAuthorization = Substitute.For<INameAuthorization>();
            nameAuthorization.AccessibleNames(Arg.Any<int[]>()).Returns(accessibleNames);

            return new CheckRestrictionsController(Db, securityContext, nameAuthorization, cultureResolver);
        }

        [Fact]
        public async Task ShouldReturnNamesWithAndWithoutRestrictions()
        {
            var cdRed = new ClientDetail {DebtorStatus = _red}.In(Db);
            var cdGreen = new ClientDetail {DebtorStatus = _green}.In(Db);
            var cdAmber1 = new ClientDetail {DebtorStatus = _amber1}.In(Db);
            var cdAmber2 = new ClientDetail {DebtorStatus = _amber2}.In(Db);
            var noRestriction1 = 100;
            var noRestriction2 = 200;

            var ids = new[] {noRestriction2, noRestriction1, cdRed.Id, cdAmber1.Id, cdAmber2.Id, cdGreen.Id};
            var subject = CreateSubject(ids);

            var r = (await subject.GetRestrictions(string.Join(",", ids.Select(_ => $"{_}")))).ToArray();

            Assert.Equal(6, r.Length);

            var rRed = r.First(_ => _.Id == cdRed.Id);
            var rGreen = r.First(_ => _.Id == cdGreen.Id);
            var rAmber1 = r.First(_ => _.Id == cdAmber1.Id);
            var rAmber2 = r.First(_ => _.Id == cdAmber2.Id);
            var rNoRes1 = r.First(_ => _.Id == noRestriction1);
            var rNoRes2 = r.First(_ => _.Id == noRestriction2);

            Assert.Equal("red", rRed.Description);
            Assert.Equal("error", rRed.Severity);

            Assert.Equal("amber", rAmber1.Description);
            Assert.Equal("warning", rAmber1.Severity);

            Assert.Equal("amber", rAmber2.Description);
            Assert.Equal("warning", rAmber2.Severity);

            Assert.Equal("green", rGreen.Description);
            Assert.Equal("information", rGreen.Severity);

            Assert.Null(rNoRes1.Description);
            Assert.Null(rNoRes1.Severity);
            Assert.Null(rNoRes2.Description);
            Assert.Null(rNoRes2.Severity);
        }
    }
}