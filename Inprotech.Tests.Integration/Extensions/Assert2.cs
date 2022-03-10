using System;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.Extensions
{
    public static class Assert2
    {
        public static void WaitTrue(int times, int wait, Func<bool> action, string message = null)
        {
            Assert.IsTrue(Try.Wait(times, wait, action), message);
        }

        public static void WaitFalse(int times, int wait, Func<bool> action, string message = null)
        {
            Assert.IsTrue(Try.Wait(times, wait, () => !action()), message);
        }

        public static void WaitEqual(int times, int wait, Func<object> val1, Func<object> val2, string message = null)
        {
            Try.Retry(times, wait, () => Assert.AreEqual(val1(), val2(), message));
        }
    }
}