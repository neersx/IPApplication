using System.Threading.Tasks;

namespace Inprotech.Tests.Extensions
{
    public static class NSubstituteExtensions
    {
        public static void IgnoreAwaitForNSubstituteAssertion(this Task task)
        {
        }
    }
}