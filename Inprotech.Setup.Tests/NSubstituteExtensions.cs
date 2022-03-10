using System.Threading.Tasks;

namespace Inprotech.Setup.Tests
{
    public static class NSubstituteExtensions
    {
        public static void IgnoreAwaitForNSubstituteAssertion(this Task task)
        {
        }
    }
}