using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.Epo.CpaXmlConversion
{
    static class Helper
    {
        public static IOrderedEnumerable<TSource> OrderByChangeGazetteNum<TSource>(this IEnumerable<TSource> source, Func<TSource, string> keySelector)
        {
            var s = source ?? Enumerable.Empty<TSource>();
            return s.OrderByDescending(i =>
            {
                var num = keySelector(i);
                return num == "N/P" ? "0000/00" : num;
            });
        }

        public static IEnumerable<TSource> LatestByChangeGazetteNum<TSource>(this IEnumerable<TSource> source,
            Func<TSource, string> keySelector)
        {
            var s = source ?? Enumerable.Empty<TSource>();
            var itm = s.OrderByChangeGazetteNum(keySelector)
                            .FirstOrDefault();

            return (null == itm) ? new List<TSource>() : new List<TSource> { itm };
        }

        public static bool IgnoreCaseEquals(string s1, string s2)
        {
            return string.Equals(s1, s2, StringComparison.OrdinalIgnoreCase);
        }
    }

}
