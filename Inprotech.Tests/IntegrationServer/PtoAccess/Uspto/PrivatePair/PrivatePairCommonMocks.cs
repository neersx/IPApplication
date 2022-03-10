using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using NSubstitute;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public static class PrivatePairCommonMocks
    {
        public static IFileNameExtractor FileNameExtractor
        {
            get
            {
                var obj = Substitute.For<IFileNameExtractor>();
                obj.AbsoluteUriName(Arg.Any<string>()).Returns((p) => p[0]);
                return obj;
            }
        }
    }
}
