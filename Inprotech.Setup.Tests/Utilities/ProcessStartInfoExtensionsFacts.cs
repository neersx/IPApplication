using System.Diagnostics;
using Inprotech.Setup.Core.Utilities;
using Xunit;

namespace Inprotech.Setup.Tests.Utilities
{
    public class ProcessStartInfoExtensionsFacts
    {
        [Fact]
        public void RunAsShouldSpecifyUserNameAndDomainCorrectlyForDomainUser()
        {
            var psi = new ProcessStartInfo().RunAs("a\\b", "p");

            Assert.Equal("a", psi.Domain);
            Assert.Equal("b", psi.UserName);
        }

        [Fact]
        public void RunAsShouldSpecifyUserNameCorrectlyForLocalUser()
        {
            var psi = new ProcessStartInfo().RunAs("a", "p");

            Assert.Equal("a", psi.UserName);
        }

        [Fact]
        public void RunAsShouldUseDefaultValueForDomainForLocalUser()
        {
            var psi = new ProcessStartInfo().RunAs("a", "p");

            Assert.Equal(new ProcessStartInfo().Domain, psi.Domain);
        }
    }
}