using System;
using System.Collections.Generic;
using System.Linq;
using Xunit;

namespace Inprotech.Tests.Extensions
{
    public static class AssertEx
    {
        public static void AssertWith<TExpected, TActual>(this IEnumerable<TActual> actual, IEnumerable<TExpected> expected, Action<TExpected, TActual> inspector)
        {
            Assert.Collection(actual, expected.Select(e => (Action<TActual>)(a => inspector(e, a))).ToArray());
        }
    }
}