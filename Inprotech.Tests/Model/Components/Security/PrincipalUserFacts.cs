using System.Collections.Generic;
using System.Security.Claims;
using System.Security.Principal;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security
{
    public class PrincipalUserFacts : FactBase
    {
        [Theory]
        [InlineData("superuser", "superuser")]
        [InlineData("fabrikam\\superuser", "fabrikam\\superuser")]
        public void MatchesTheCorrectUsers(string loginIdInDb, string currentPrincipalIdentity)
        {
            var currentPrincipal = new GenericPrincipal(new GenericIdentity(currentPrincipalIdentity), new string[0]);

            var theUser = new User(loginIdInDb, false).In(Db);

            Assert.Equal(theUser, new PrincipalUser(Db).From(currentPrincipal));
        }

        [Fact]
        public void MatchesUsersBasedOnClaim()
        {
            var windowsUser = "got\\Sansa";
            var claims = new List<Claim> {new Claim(ClaimTypes.WindowsAccountName, windowsUser)};
            var currentPrincipal = new ClaimsPrincipal(new ClaimsIdentity(claims));

            var theUser = new User(windowsUser, false).In(Db);

            Assert.Equal(theUser, new PrincipalUser(Db).From(currentPrincipal, ClaimTypes.WindowsAccountName));
        }
    }
}