using System.Linq;
using System.Reflection;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Tests.Server;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseShaping
{
    public class ResponseShapingFacts
    {
        [Fact]
        public void ShouldNotEnrichResponseForAnyGivenPicklistPayload()
        {
            foreach (var c in AllRegisteredControllers.Get())
            {
                Assert.False(c.GetMethods()
                              .Any(
                                   _ =>
                                       _.GetCustomAttribute<PicklistPayloadAttribute>() != null &&
                                       c.GetCustomAttribute<NoEnrichmentAttribute>() == null),
                             string.Format("Controller {0} has picklist payload action without a no-enrichment attribute", c));
            }
        }
    }
}