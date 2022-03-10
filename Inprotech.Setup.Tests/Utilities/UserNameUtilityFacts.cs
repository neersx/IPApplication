using System;
using Inprotech.Setup.Actions.Utilities;
using Xunit;

namespace Inprotech.Setup.Tests.Utilities
{
    public class UserNameUtilityFacts
    {
        [Fact]
        public void ShouldReturnCanonicalUserName()
        {
            const string username = "Administrator";
            Assert.Equal(string.Format("{0}\\Administrator", Environment.MachineName), username.ToCanonicalUserName());
        }

        [Fact]
        public void ShouldReturnOriginalNameIfIsDomainUser()
        {
            const string username = "INT\\Administrator";
            Assert.Equal(username, username.ToCanonicalUserName());
        }
    }
}