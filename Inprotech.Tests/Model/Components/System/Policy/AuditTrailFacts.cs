using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.Policy
{
    public class AuditTrailFacts
    {
        [Fact]
        public void ShouldSetContextWhenCalled()
        {
            var context = Substitute.For<IContextInfo>();

            new InprotechKaizen.Model.Components.System.Policy.AuditTrail(context).Start();

            context.Received().EnsureUserContext();
        }
    }
}